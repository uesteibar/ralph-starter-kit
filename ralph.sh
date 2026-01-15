#!/bin/bash
# Ralph Wiggum - Long-running AI agent loop
# Usage: ./ralph.sh <max_iterations>  - Setup worktree and run agent
#        ./ralph.sh cleanup           - Remove all Ralph worktrees
#
# This is a convenience wrapper. For more control, use:
#   ./ralph_setup.sh  - Just setup the worktree
#   ./ralph_run.sh    - Run the agent (from within worktree)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$1" = "cleanup" ]; then
  exec "$SCRIPT_DIR/ralph_setup.sh" cleanup
fi

if [ -z "$1" ]; then
  echo "Usage: $0 <max_iterations>"
  echo "       $0 cleanup"
  exit 1
fi

MAX_ITERATIONS=$1

# Run setup
"$SCRIPT_DIR/ralph_setup.sh"

# Get worktree path from setup
WORKTREES_DIR="$SCRIPT_DIR/.worktrees"
PRD_FILE="$SCRIPT_DIR/prd.json"
BRANCH_NAME=$(jq -r '.branchName // empty' "$PRD_FILE" 2>/dev/null || echo "")
WORKTREE_PATH="$WORKTREES_DIR/$BRANCH_NAME"

# Run agent in worktree
cd "$WORKTREE_PATH"
exec .ralph/ralph_run.sh "$MAX_ITERATIONS"
