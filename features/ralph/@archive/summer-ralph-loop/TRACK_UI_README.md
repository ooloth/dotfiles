# BookShelf Development Loop with Track UI Integration

This setup integrates the development loop with Claude Code's track UI, making all progress visible and trackable.

## Overview

The tracked version enhances the original loop with task tracking capabilities:

- **Original files**: `run_loop.sh`, `BOYLE.txt`, `AMY.txt`, `HOLT.txt`
- **Tracked files**: `run_loop_tracked.sh`, `BOYLE_TRACKED.txt`, `AMY_TRACKED.txt`, `HOLT_TRACKED.txt`

## What's Different?

### Enhanced Prompts
Each agent (Boyle, Amy, Holt) now:
1. **Creates tasks** at the start of their work using `TaskCreate`
2. **Updates task status** as they progress using `TaskUpdate`
3. **Marks tasks complete** with metadata when done

### Enhanced Loop Script
The `run_loop_tracked.sh` script includes:
- ✅ Visual progress indicators (emojis and structured output)
- 📊 Better logging of each step
- 🎯 Clear indication of what each agent is doing
- ⚙️  All agent activities are tracked in the UI

## How to Use

### Option 1: Run the loop script directly
```bash
./run_loop_tracked.sh
```

All stdout will appear in your terminal, and the agents (Boyle, Amy, Holt) will create and update tasks in the track UI as they work.

### Option 2: Run as a background task (Recommended)
To capture all output in the track UI and monitor it asynchronously:

```bash
# From Claude Code, run:
claude -c "Run the tracked loop as a background task"
```

Or manually with the Bash tool using `run_in_background=true`.

### Option 3: Dry run mode
Test the loop without actually running agents:
```bash
./run_loop_tracked.sh --dry-run
```

## What You'll See in Track UI

When the loop runs, you'll see tasks like:

### From Boyle:
- **Task**: "Complete phase1_task15_vite_proxy"
  - **Status**: in_progress → completed
  - **Metadata**: `{"files_changed": 5, "tests_passed": true}`

### From Amy:
- **Task**: "Review phase1_task15_vite_proxy"
  - **Status**: in_progress → completed
  - **Metadata**: `{"verdict": "APPROVED"}`

### From Holt:
- **Task**: "Review Phase 1"
  - **Status**: in_progress → completed
  - **Metadata**: `{"verdict": "APPROVED"}`

## File Structure

```
agent-test/
├── run_loop.sh              # Original loop (no tracking)
├── run_loop_tracked.sh      # Enhanced loop with tracking
├── BOYLE.txt                # Original Boyle prompt
├── BOYLE_TRACKED.txt        # Enhanced Boyle with task tracking
├── AMY.txt                  # Original Amy prompt
├── AMY_TRACKED.txt          # Enhanced Amy with task tracking
├── HOLT.txt                 # Original Holt prompt
├── HOLT_TRACKED.txt         # Enhanced Holt with task tracking
├── TODO.md                  # Task list
├── PROJECT_PLAN.md          # Architecture and requirements
├── logs/                    # Boyle's task logs
├── reviews/                 # Amy's reviews
├── phase_reviews/           # Holt's phase reviews
└── escalations/             # Escalation files
```

## Benefits of Track UI Integration

1. **Real-time visibility**: See exactly what each agent is doing
2. **Progress tracking**: Track completion of tasks and reviews
3. **Historical record**: All task metadata is preserved
4. **Better debugging**: When something goes wrong, check task history
5. **Async monitoring**: Run the loop in background and check progress anytime

## Switching Between Versions

- **Use original version** (`run_loop.sh`) if you prefer simpler output
- **Use tracked version** (`run_loop_tracked.sh`) for better visibility and integration with track UI

Both versions are functionally equivalent; the tracked version just adds task tracking on top.

## Examples

### Running with tracking
```bash
./run_loop_tracked.sh
```

Output will show:
```
╔════════════════════════════════════════╗
║   BookShelf Development Loop Started   ║
║      Using Task Tracking (Track UI)    ║
╚════════════════════════════════════════╝

ℹ️  All progress will be visible in the track UI
ℹ️  Boyle, Amy, and Holt will create and update tasks

═══════════════════════════════════════════════════════
🔄 Loop iteration 1
═══════════════════════════════════════════════════════
📋 Step 1: Checking for escalations...
   ✓ No escalations found
📋 Step 2: Checking if any phase needs review...
   ✓ No phases need review
📋 Step 3: Checking if any task needs review...
   ✓ No tasks need review
📋 Step 4: Finding next task...

🎯 Next task (line 31):
   - [ ] Configure Vite proxy to Django dev server
   ⚙️  Invoking Charles Boyle to execute this task...
   ✓ Boyle's work complete
```

And in the track UI, you'll see Boyle's task appear and update in real-time.

## Migration from Original Version

If you're currently using `run_loop.sh`:

1. The original version still works fine
2. To try the tracked version: `./run_loop_tracked.sh`
3. Both versions use the same TODO.md, logs/, reviews/, etc.
4. You can switch between them at any time

No migration needed - just choose which script to run!
