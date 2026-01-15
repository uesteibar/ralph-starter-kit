#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop
# Usage: ./ralph.sh [max_iterations]
#        ./ralph.sh cleanup - Remove all Ralph worktrees

set -e

echo "Ralph Wiggum - Long-running AI agent loop"
echo "-----------------------------------------"

# Parse arguments
if [ "$1" = "cleanup" ]; then
  echo "Cleaning up Ralph worktrees..."
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
  WORKTREES_DIR="$SCRIPT_DIR/.worktrees"

  if [ -d "$WORKTREES_DIR" ]; then
    cd "$PROJECT_ROOT"
    for worktree in "$WORKTREES_DIR"/*; do
      if [ -d "$worktree" ]; then
        BRANCH_NAME=$(basename "$worktree")
        echo "Removing worktree: $BRANCH_NAME"
        git worktree remove "$worktree" --force || true
      fi
    done
    rmdir "$WORKTREES_DIR" 2>/dev/null || true
    echo "Cleanup complete!"
  else
    echo "No worktrees to clean up."
  fi
  exit 0
fi

MAX_ITERATIONS=$1

if [ -z "$MAX_ITERATIONS" ]; then
  echo "Usage: $0 <max_iterations>"
  echo "       $0 cleanup"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_WORKTREE_FILE="$SCRIPT_DIR/.last-worktree"
WORKTREES_DIR="$SCRIPT_DIR/.worktrees"

# Detect main branch (could be 'main' or 'master')
cd "$PROJECT_ROOT"
if git rev-parse --verify main >/dev/null 2>&1; then
  MAIN_BRANCH="main"
elif git rev-parse --verify master >/dev/null 2>&1; then
  MAIN_BRANCH="master"
else
  echo "Error: Could not find main or master branch."
  exit 1
fi

# Archive previous run if worktree changed
if [ -f "$PRD_FILE" ] && [ -f "$LAST_WORKTREE_FILE" ]; then
  CURRENT_BRANCH=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
  LAST_WORKTREE=$(cat "$LAST_WORKTREE_FILE" 2>/dev/null || echo "")

  if [ -n "$CURRENT_BRANCH" ] && [ -n "$LAST_WORKTREE" ]; then
    LAST_BRANCH=$(basename "$LAST_WORKTREE")

    if [ "$CURRENT_BRANCH" != "$LAST_BRANCH" ]; then
      # Archive the previous run
      DATE=$(date +%Y-%m-%d)
      # Strip "ralph/" prefix from branch name for folder
      # Keep ralph/ prefix for archive folder
      ARCHIVE_FOLDER="$ARCHIVE_DIR/$DATE-$LAST_BRANCH"

      echo "Archiving previous run: $LAST_BRANCH"
      mkdir -p "$ARCHIVE_FOLDER"
      [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$ARCHIVE_FOLDER/"
      [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$ARCHIVE_FOLDER/"
      echo "   Archived to: $ARCHIVE_FOLDER"

      # Reset progress file for new run
      echo "# Ralph Progress Log" > "$PROGRESS_FILE"
      echo "Started: $(date)" >> "$PROGRESS_FILE"
      echo "---" >> "$PROGRESS_FILE"
    fi
  fi
fi

# Setup worktree if needed
if [ -f "$PRD_FILE" ]; then
  BRANCH_NAME=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")

  if [ -n "$BRANCH_NAME" ]; then
    # Keep the full branch name including "ralph/" prefix in the worktree path
    WORKTREE_PATH="$WORKTREES_DIR/$BRANCH_NAME"

    # Create worktrees directory if it doesn't exist
    mkdir -p "$WORKTREES_DIR"

    # Check if worktree already exists
    if [ ! -d "$WORKTREE_PATH" ]; then
      echo "Creating worktree for branch: $BRANCH_NAME"
      cd "$PROJECT_ROOT"

      # Check if branch exists
      if git rev-parse --verify "$BRANCH_NAME" >/dev/null 2>&1; then
        # Branch exists, create worktree from it
        git worktree add "$WORKTREE_PATH" "$BRANCH_NAME" 2>/dev/null || {
          echo "Error: Failed to create worktree. Branch may already be checked out elsewhere."
          exit 1
        }
      else
        # Branch doesn't exist, create new branch from main/master
        git worktree add -b "$BRANCH_NAME" "$WORKTREE_PATH" "$MAIN_BRANCH" 2>/dev/null || {
          echo "Error: Failed to create worktree from $MAIN_BRANCH branch."
          exit 1
        }
      fi

      echo "Worktree created at: $WORKTREE_PATH"
    else
      echo "Using existing worktree at: $WORKTREE_PATH"
    fi

    # Track current worktree
    echo "$WORKTREE_PATH" > "$LAST_WORKTREE_FILE"

    # Copy .ralph directory to worktree (enables parallel execution with separate prd.json files)
    if [ ! -d "$WORKTREE_PATH/.ralph" ]; then
      mkdir -p "$WORKTREE_PATH/.ralph"
      # Copy prd.json and progress.txt for this worktree's independent state
      [ -f "$PRD_FILE" ] && cp "$PRD_FILE" "$WORKTREE_PATH/.ralph/"
      [ -f "$PROGRESS_FILE" ] && cp "$PROGRESS_FILE" "$WORKTREE_PATH/.ralph/"
      # Symlink CLAUDE.md since it's shared across all runs
      ln -s "$SCRIPT_DIR/CLAUDE.md" "$WORKTREE_PATH/.ralph/CLAUDE.md"
      echo "Created .ralph directory in worktree with copied prd.json"
    fi

    # Change to worktree directory for Claude execution
    cd "$WORKTREE_PATH" || {
      echo "Error: Failed to change to worktree directory: $WORKTREE_PATH"
      exit 1
    }
    echo "Working in worktree: $WORKTREE_PATH"
  else
    echo "Warning: No branchName found in prd.json, using current directory"
  fi
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

echo "Starting Ralph Max iterations: $MAX_ITERATIONS"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "==============================================================="
  echo "  Ralph Iteration $i of $MAX_ITERATIONS"
  echo "==============================================================="

  # Use worktree-local CLAUDE.md if in a worktree, otherwise use central one
  CLAUDE_MD="${WORKTREE_PATH:+$WORKTREE_PATH/.ralph/CLAUDE.md}"
  CLAUDE_MD="${CLAUDE_MD:-$SCRIPT_DIR/CLAUDE.md}"
  OUTPUT=$(claude --dangerously-skip-permissions --print < "$CLAUDE_MD" 2>&1 | tee /dev/stderr) || true

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "Ralph completed all tasks!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    echo ""
    echo "To merge changes back to main, run:"
    echo "  cd $WORKTREE_PATH"
    echo "  git push origin $BRANCH_NAME"
    echo ""
    echo "To clean up worktrees when done, run:"
    echo "  $0 cleanup"
    exit 0
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
exit 1
