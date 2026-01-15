#!/bin/bash
# Ralph Setup - Creates worktree and prepares .ralph directory for an agent run
# Usage: ./ralph_setup.sh
#        ./ralph_setup.sh cleanup - Remove all Ralph worktrees

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
ARCHIVE_DIR="$SCRIPT_DIR/archive"
LAST_WORKTREE_FILE="$SCRIPT_DIR/.last-worktree"
WORKTREES_DIR="$SCRIPT_DIR/.worktrees"

echo "Ralph Setup"
echo "-----------"

# Parse arguments
if [ "$1" = "cleanup" ]; then
  echo "Cleaning up Ralph worktrees..."

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

# Check for prd.json
if [ ! -f "$PRD_FILE" ]; then
  echo "Error: No prd.json found at $PRD_FILE"
  exit 1
fi

BRANCH_NAME=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")

if [ -z "$BRANCH_NAME" ]; then
  echo "Error: No branchName found in prd.json"
  exit 1
fi

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
  cp -R "$SCRIPT_DIR" "$WORKTREE_PATH/.ralph"
  echo "Copied .ralph directory to worktree"
fi

echo ""
echo "Setup complete!"
echo ""
echo "To run the agent:"
echo "  cd $WORKTREE_PATH"
echo "  .ralph/ralph_run.sh <max_iterations>"
echo ""
echo "To clean up worktrees when done:"
echo "  $0 cleanup"
