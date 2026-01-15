#!/bin/bash
# Convert input file to prd.json using Ralph skill
# Usage: .ralph/convert_prd.sh <input_file> (run from project root)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Converting $1 to prd.json"

# read the contents of convert_prd.prompt and replace <input_file> in the text with the name of the input file (first argument). Assign that to $PROMPT
PROMPT=$(sed "s|<input_file>|$1|g" "$SCRIPT_DIR/convert_prd.prompt")

claude -p "$PROMPT" --dangerously-skip-permissions --print
echo "Converted to prd.json"
