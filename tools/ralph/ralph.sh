#!/usr/bin/env bash
set -e

MAX_ITERATIONS=${1:-50}
RALPH_DIR=".ralph"

# Check .ralph/ exists
if [[ ! -d "$RALPH_DIR" ]]; then
  echo "❌ No .ralph/ directory found in current directory."
  echo "Create one with: prompt.md, prd.json, progress.txt, config.json"
  exit 1
fi

# Check required files exist
for file in prompt.md prd.json progress.txt config.json; do
  if [[ ! -f "$RALPH_DIR/$file" ]]; then
    echo "❌ Missing required file: $RALPH_DIR/$file"
    exit 1
  fi
done

echo "🚀 Starting Ralph (max $MAX_ITERATIONS iterations)"
echo "📁 Working directory: $(pwd)"
echo "📋 Reading: $RALPH_DIR/prompt.md"
echo ""

for i in $(seq 1 "$MAX_ITERATIONS"); do
  echo "════════════════════════════════════════"
  echo "   Iteration $i of $MAX_ITERATIONS"
  echo "════════════════════════════════════════"
  echo ""

  # Run claude-code with prompt, capture output
  OUTPUT=$(cat "$RALPH_DIR/prompt.md" | claude-code --dangerously-skip-permissions 2>&1 | tee /dev/stderr) || true

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "════════════════════════════════════════"
    echo "✅ All tasks complete!"
    echo "════════════════════════════════════════"
    exit 0
  fi

  # Small delay between iterations
  sleep 2
  echo ""
done

echo ""
echo "════════════════════════════════════════"
echo "⚠️  Max iterations reached ($MAX_ITERATIONS)"
echo "════════════════════════════════════════"
echo ""
echo "Check .ralph/prd.json to see remaining tasks"
exit 1
