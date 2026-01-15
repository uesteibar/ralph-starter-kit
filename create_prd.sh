#!/bin/bash
# Start a conversation with Claude to create a PRD
# Usage: .ralph/create_prd.sh (run from project root)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

claude "$(cat "$SCRIPT_DIR/create_prd.prompt")" --dangerously-skip-permissions
