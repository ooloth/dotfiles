#!/usr/bin/env bash
set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
  DRY_RUN=true
fi

# Track Claude process IDs
CLAUDE_PID=""

# Cleanup function to kill any running Claude instances
cleanup() {
  # Capture the exit code before doing anything
  local exit_code=$?

  # Remove the trap to prevent recursion
  trap - SIGINT SIGTERM EXIT

  echo ""
  echo "========================================="
  echo "Stopping loop and cleaning up..."
  echo "========================================="

  # Kill the specific Claude process we started
  if [[ -n "$CLAUDE_PID" ]] && kill -0 "$CLAUDE_PID" 2>/dev/null; then
    echo "Killing Claude process: $CLAUDE_PID"
    kill -TERM "$CLAUDE_PID" 2>/dev/null || true
    sleep 1
    # Force kill if still running
    if kill -0 "$CLAUDE_PID" 2>/dev/null; then
      kill -KILL "$CLAUDE_PID" 2>/dev/null || true
    fi
  fi

  # Kill any other Claude processes that might be lingering
  LINGERING_PIDS=$(pgrep -f "claude -p" || true)
  if [[ -n "$LINGERING_PIDS" ]]; then
    echo "Killing lingering Claude processes: $LINGERING_PIDS"
    echo "$LINGERING_PIDS" | xargs kill -TERM 2>/dev/null || true
    sleep 1
    # Force kill any that are still alive
    STILL_ALIVE=$(pgrep -f "claude -p" || true)
    if [[ -n "$STILL_ALIVE" ]]; then
      echo "$STILL_ALIVE" | xargs kill -KILL 2>/dev/null || true
    fi
  fi

  echo "Cleanup complete."
  exit $exit_code
}

# Set up signal handlers to catch interruptions
trap cleanup SIGINT SIGTERM EXIT

# Helper function to run Claude with PID tracking
run_claude() {
  "$@" &
  CLAUDE_PID=$!
  wait $CLAUDE_PID
  local exit_code=$?
  CLAUDE_PID=""
  return $exit_code
}

# Create directories if they don't exist
mkdir -p logs escalations reviews phase_reviews

ITERATION=0

while true; do
  ITERATION=$((ITERATION + 1))
  echo ""
  echo "========================================="
  echo "Loop iteration $ITERATION"
  echo "========================================="

  # -----------------------------------------------
  # Step 1: Check for escalations
  # -----------------------------------------------
  ESCALATION_FILES=$(find escalations/ -name '*.md' -type f 2>/dev/null)
  if [[ -n "$ESCALATION_FILES" ]]; then
    echo "ESCALATION FOUND. Halting loop."
    echo ""
    for f in $ESCALATION_FILES; do
      echo "--- $f ---"
      cat "$f"
      echo ""
    done
    echo "Resolve the issue and re-run the script."
    exit 1
  fi

  # -----------------------------------------------
  # Step 2: Check if a completed phase needs review by Holt
  # -----------------------------------------------
  # Extract phase numbers and check if each phase is complete
  CURRENT_PHASE=""
  PHASE_COMPLETE=false
  PHASE_NUM=""

  # Read through TODO.md to find phases
  while IFS= read -r line; do
    # Check if this is a phase header (e.g., "## Phase 1: ...")
    if echo "$line" | grep -q '^## Phase [0-9]\+:'; then
      # If we were tracking a previous phase and it was complete, check for review
      if [[ -n "$CURRENT_PHASE" ]] && [[ "$PHASE_COMPLETE" == true ]]; then
        REVIEW_FILE="phase_reviews/phase${PHASE_NUM}.md"
        if [[ ! -f "$REVIEW_FILE" ]]; then
          echo "Step 2: Phase $PHASE_NUM is complete but has no phase review. Running Holt."
          if [[ "$DRY_RUN" == true ]]; then
            echo "[DRY RUN] Would invoke Holt to review Phase $PHASE_NUM"
          else
            run_claude claude -p --system-prompt "$(cat HOLT.txt)" \
              "Phase $PHASE_NUM is complete. Review all work added to the repository for this phase. Read project_plan.md and TODO.md to understand what was supposed to be built. Read the task logs in logs/ and Amy's reviews in reviews/ for this phase. Check that:
1. All work matches the project plan
2. No tasks were skipped or done incorrectly
3. The codebase is in good shape to move to the next phase

Write your phase review to phase_reviews/phase${PHASE_NUM}.md. Your review must include:
- Summary of what was built in this phase
- Any concerns or issues you found
- Verdict: APPROVED or CHANGES REQUIRED

If APPROVED: The team can move to the next phase.

If CHANGES REQUIRED: Create new tasks in TODO.md under Phase $PHASE_NUM for Boyle and Amy to address. You may also adjust project_plan.md if you realize the plan needs refinement based on what you've learned."
          fi
          sleep 3
          continue 2  # Restart the main loop
        fi
      fi

      # Start tracking a new phase
      PHASE_NUM=$(echo "$line" | grep -o 'Phase [0-9]\+' | grep -o '[0-9]\+')
      CURRENT_PHASE="$line"
      PHASE_COMPLETE=true  # Assume complete until we find an incomplete task
    fi

    # Check if this line is a task in the current phase
    if [[ -n "$CURRENT_PHASE" ]]; then
      # If we hit the next phase header or end, we're done with current phase
      if echo "$line" | grep -q '^## Phase [0-9]\+:' && [[ "$line" != "$CURRENT_PHASE" ]]; then
        continue
      fi

      # Check for incomplete tasks
      if echo "$line" | grep -q '^\- \[ \]'; then
        PHASE_COMPLETE=false
      fi

      # Check for completed tasks without reviews
      if echo "$line" | grep -q '^\- \[x\]' && echo "$line" | grep -q '\[log\](logs/'; then
        LOG_FILE=$(echo "$line" | grep -o 'logs/[^)]*')
        TASK_NAME=$(basename "$LOG_FILE" .md)
        REVIEW_FILE="reviews/${TASK_NAME}.md"
        if [[ ! -f "$REVIEW_FILE" ]]; then
          PHASE_COMPLETE=false  # Can't consider phase complete if tasks aren't reviewed
        fi
      fi
    fi
  done < TODO.md

  # Check the last phase we were tracking
  if [[ -n "$CURRENT_PHASE" ]] && [[ "$PHASE_COMPLETE" == true ]]; then
    REVIEW_FILE="phase_reviews/phase${PHASE_NUM}.md"
    if [[ ! -f "$REVIEW_FILE" ]]; then
      echo "Step 2: Phase $PHASE_NUM is complete but has no phase review. Running Holt."
      if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY RUN] Would invoke Holt to review Phase $PHASE_NUM"
      else
        claude -p --system-prompt "$(cat HOLT.txt)" \
          "Phase $PHASE_NUM is complete. Review all work added to the repository for this phase. Read project_plan.md and TODO.md to understand what was supposed to be built. Read the task logs in logs/ and Amy's reviews in reviews/ for this phase. Check that:
1. All work matches the project plan
2. No tasks were skipped or done incorrectly
3. The codebase is in good shape to move to the next phase

Write your phase review to phase_reviews/phase${PHASE_NUM}.md. Your review must include:
- Summary of what was built in this phase
- Any concerns or issues you found
- Verdict: APPROVED or CHANGES REQUIRED

If APPROVED: The team can move to the next phase.

If CHANGES REQUIRED: Create new tasks in TODO.md under Phase $PHASE_NUM for Boyle and Amy to address. You may also adjust project_plan.md if you realize the plan needs refinement based on what you've learned."
      fi
      sleep 3
      continue
    fi
  fi

  # -----------------------------------------------
  # Step 3: Check if a completed task needs review by Amy
  # -----------------------------------------------
  # Find tasks marked [x] in TODO.md and check for missing reviews
  NEEDS_REVIEW=false
  while IFS= read -r line; do
    # Extract a task identifier from the line for matching to review files
    # Look for log links like [log](logs/phase1_task3.md) to derive the task name
    if echo "$line" | grep -q '\[log\](logs/'; then
      LOG_FILE=$(echo "$line" | grep -o 'logs/[^)]*')
      TASK_NAME=$(basename "$LOG_FILE" .md)
      REVIEW_FILE="reviews/${TASK_NAME}.md"
      if [[ ! -f "$REVIEW_FILE" ]]; then
        NEEDS_REVIEW=true
        echo "Step 3: Task '$TASK_NAME' is completed but has no review. Running Amy."
        if [[ "$DRY_RUN" == true ]]; then
          echo "[DRY RUN] Would invoke Amy to review task: $TASK_NAME"
        else
          run_claude claude -p --system-prompt "$(cat AMY.txt)" \
            "Review the work for the completed task linked to $LOG_FILE in TODO.md. Read the log file at $LOG_FILE to understand what Boyle did. Check that the code changes are correct, tests pass, and the implementation matches PROJECT_PLAN.md. Write your review to reviews/${TASK_NAME}.md. If the work is unacceptable, mark the task back to [ ] in TODO.md and note what needs to be fixed."
        fi
        break
      fi
    fi
  done < <(grep '\[x\]' TODO.md 2>/dev/null || true)

  if [[ "$NEEDS_REVIEW" == true ]]; then
    # Check if Amy approved the task (it's still marked [x] and review file now exists)
    if [[ -f "$REVIEW_FILE" ]] && grep -q '\[x\].*'"$TASK_NAME" TODO.md 2>/dev/null; then
      # Check if Amy created a follow-up task instead of fully approving
      if grep -q '\[x\].*'"$TASK_NAME"'.*REVIEW: follow-up task created' TODO.md 2>/dev/null; then
        echo "Task '$TASK_NAME' marked complete by Amy, but follow-up task created. Skipping commit until follow-up is complete."
      else
        echo "Task '$TASK_NAME' approved by Amy. Committing changes."
        if [[ "$DRY_RUN" == true ]]; then
          echo "[DRY RUN] Would run: git add -A && git commit"
        else
          git add -A
          git commit -m "Complete task: $TASK_NAME (reviewed and approved)"
        fi
      fi
    fi
    sleep 3
    continue
  fi

  # -----------------------------------------------
  # Step 4: Find and assign the next task
  # -----------------------------------------------
  NEXT_TASK=$(grep -n '^\- \[ \]' TODO.md 2>/dev/null | head -1 || true)

  if [[ -z "$NEXT_TASK" ]]; then
    # -----------------------------------------------
    # Step 5: All tasks done
    # -----------------------------------------------
    echo "All tasks complete. Project finished."
    exit 0
  fi

  TASK_LINE_NUM=$(echo "$NEXT_TASK" | cut -d: -f1)
  TASK_TEXT=$(echo "$NEXT_TASK" | cut -d: -f2-)
  echo "Step 4: Next task (line $TASK_LINE_NUM): $TASK_TEXT"

  if [[ "$DRY_RUN" == true ]]; then
    echo "[DRY RUN] Would invoke Boyle to execute this task."
  else
    run_claude claude -p --system-prompt "$(cat BOYLE.txt)" \
      "Read TODO.md and PROJECT_PLAN.md. Execute the following task (line $TASK_LINE_NUM in TODO.md): $TASK_TEXT

Follow these rules:
1. Only work on this ONE task.
2. Write all code changes needed for the task.
3. Run any relevant tests to confirm your work. A task is not done until tests pass.
4. Write a log file to logs/ describing what you did, what files you changed, and what tests you ran.
5. If you complete the task successfully, mark it [x] in TODO.md and link your log file next to the task.
6. If you get stuck or need permissions, write an escalation file to escalations/ explaining the blocker. Note the escalation in TODO.md next to the task.
7. Do NOT move on to another task. Stop after this one task."
  fi

  sleep 3
done
