#!/bin/bash
# Ralph Run - Executes the AI agent loop
# Usage: ./ralph_run.sh <max_iterations>
# Run this from within a worktree's .ralph directory

set -e

MAX_ITERATIONS=$1

if [ -z "$MAX_ITERATIONS" ]; then
  echo "Usage: $0 <max_iterations>"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKTREE_PATH="$(cd "$SCRIPT_DIR/.." && pwd)"
PRD_FILE="$SCRIPT_DIR/prd.json"
PROGRESS_FILE="$SCRIPT_DIR/progress.txt"
CLAUDE_MD="$SCRIPT_DIR/CLAUDE.md"

echo "Ralph Wiggum - Long-running AI agent loop"
echo "-----------------------------------------"

# Verify we have the required files
if [ ! -f "$PRD_FILE" ]; then
  echo "Error: No prd.json found at $PRD_FILE"
  echo "Run ralph_setup.sh first to create the worktree."
  exit 1
fi

if [ ! -f "$CLAUDE_MD" ]; then
  echo "Error: No CLAUDE.md found at $CLAUDE_MD"
  exit 1
fi

# Initialize progress file if it doesn't exist
if [ ! -f "$PROGRESS_FILE" ]; then
  echo "# Ralph Progress Log" > "$PROGRESS_FILE"
  echo "Started: $(date)" >> "$PROGRESS_FILE"
  echo "---" >> "$PROGRESS_FILE"
fi

# Change to worktree directory for Claude execution
cd "$WORKTREE_PATH" || {
  echo "Error: Failed to change to worktree directory: $WORKTREE_PATH"
  exit 1
}

BRANCH_NAME=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")

echo "Working in: $WORKTREE_PATH"
echo "Starting Ralph - Max iterations: $MAX_ITERATIONS"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "==============================================================="
  echo "  Ralph Iteration $i of $MAX_ITERATIONS"
  echo "==============================================================="

  OUTPUT=$(claude --dangerously-skip-permissions --print < "$CLAUDE_MD" 2>&1 | tee /dev/stderr) || true

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "Ralph completed all tasks!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    echo ""
    if [ -n "$BRANCH_NAME" ]; then
      echo "To merge changes back to main, run:"
      echo "  git push origin $BRANCH_NAME"
    fi
    exit 0
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Ralph reached max iterations ($MAX_ITERATIONS) without completing all tasks."
echo "Check $PROGRESS_FILE for status."
exit 1
