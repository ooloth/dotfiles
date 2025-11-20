# Zsh Startup Optimization Plan

## Problem Statement

Zsh shell startup has become slow due to automatic file sourcing. Current startup process performs expensive operations on every shell initialization.

## Root Causes

### 1. Multiple Expensive `find` Operations (Primary Bottleneck)

**Location:** `tools/zsh/config/tools.zsh:8-59`

The file executes **6 separate `find` commands** on every shell startup:

1. `find` for `shell.zsh` files in features/ (→ 10 files)
2. `find` for `shell.zsh` files in tools/ (→ 27 files, including @archive)
3. `find` for `shell/variables.zsh` files (→ 11 files)
4. `find` for `shell/aliases.zsh` in features/ (→ 0 files)
5. `find` for `shell/aliases.zsh` in tools/ (→ 11 files)
6. `find` for `shell/integration.zsh` files (→ 10 files)

**Total:** ~69 files sourced after 6 directory tree traversals

**Impact:** Each `find` command traverses the entire directory tree, making this extremely expensive. This compounds because:
- The dotfiles repository has many directories to search
- Operations are sequential (not parallel)
- This happens on every single shell startup

### 2. Redundant Sourcing of Common Files ✅ FIXED

**Location:** Nearly every `shell.zsh` file

**Pattern:**
```zsh
source "${DOTFILES}/tools/zsh/utils.zsh" # sourced in ~56 files
```

**Impact:**
- `utils.zsh` was sourced ~56 times
- `utils.zsh` itself sources `macos/shell/aliases.zsh`
- Resulted in dozens of redundant file reads and executions

**Fix Applied:** Removed all 56 redundant source statements. Now sourced once in `.zshrc:9`.

### 3. Multiple `eval` Commands

**Locations:**
- `tools/fzf/shell.zsh:15` - `eval "$(fzf --zsh)"`
- `tools/homebrew/shell.zsh:12` - `eval "$(/opt/homebrew/bin/brew shellenv)"`
- `tools/mise/shell/integration.zsh:5` - `eval "$(mise activate zsh)"`
- `tools/zoxide/shell/integration.zsh:5` - `eval "$(zoxide init zsh)"`
- `tools/fnm/shell.zsh:18` - `eval "$(fnm env --use-on-cd --shell zsh ...)"`
- `tools/uv/shell.zsh:15-16` - `eval "$(uv generate-shell-completion zsh)"` + uvx completion

**Impact:** Each `eval` spawns a subprocess and executes commands, adding latency

### 4. Repeated `have` Function Calls

**Location:** Throughout shell.zsh files (16 files)

**Pattern:**
```zsh
if have <tool>; then
  # setup for tool
fi
```

**Impact:** The `have` function uses `type` command which can be slow when called repeatedly. However, this is good practice for conditional loading and shouldn't be removed.

### 5. Archive Files Exclusion ✅ VERIFIED WORKING

**Location:** `tools/zsh/config/tools.zsh:15`

**Status:** Verified that `find` commands correctly exclude @archive directories via `-prune` flag. No issues found.

### 6. Many Small Files with High Overhead

**Finding:** 34 shell.zsh files sourced at startup, with ~20 of them containing only 1-3 lines of actual content

**Examples:**
- 10 files with just 1 line (single alias like `alias cat="bat"`)
- Files have extensive boilerplate (section headers) but minimal content
- Each file requires I/O operation regardless of size

**Impact:** Overhead of sourcing 34 files individually vs. consolidated approach

## Optimization Strategies

### Strategy 1: Pre-Generate File Manifest (Recommended)

**Approach:** Create a manifest file listing all files to source, regenerated only when the repository structure changes.

**Implementation:**
1. Create a script to generate `${DOTFILES}/.cache/shell-files-manifest.zsh`
2. Manifest contains hardcoded paths (no `find` needed)
3. Source manifest instead of running `find` commands
4. Regenerate manifest:
   - After install/update scripts run
   - When new tools are added
   - Optionally: check if manifest is stale (compare timestamp to newest .zsh file)

**Pros:**
- Eliminates all `find` operations
- Fastest possible approach
- Simple implementation

**Cons:**
- Requires remembering to regenerate manifest when adding new tools
- Could get out of sync (mitigated by staleness check)

### Strategy 2: Lazy Loading

**Approach:** Defer loading of non-essential tools until first use.

**Implementation:**
1. Categorize files into:
   - **Critical:** Must load on startup (PATH, core aliases)
   - **Deferred:** Can load on first use (tool-specific features)
2. For deferred tools, create wrapper functions that:
   - Load the real implementation on first call
   - Replace themselves with the real function

**Example:**
```zsh
# Instead of sourcing fzf immediately, create wrapper:
fzf() {
  unfunction fzf
  eval "$(fzf --zsh)"
  fzf "$@"
}
```

**Pros:**
- Dramatically faster startup for features you don't use immediately
- No manifest to maintain

**Cons:**
- Complexity: requires categorizing files and creating wrappers
- First use of each tool has slight delay
- Some tools (like PATH modifications) can't be deferred

### Strategy 3: Consolidate Shell Files

**Approach:** Merge the 69 separate files into a smaller number of consolidated files.

**Implementation:**
1. Eliminate `shell.zsh` pattern entirely
2. Create consolidated files:
   - `${DOTFILES}/.cache/all-variables.zsh` (all environment variables)
   - `${DOTFILES}/.cache/all-aliases.zsh` (all aliases)
   - `${DOTFILES}/.cache/all-completions.zsh` (all completions)
3. Source just these 3-4 files instead of 69

**Pros:**
- Fewer file I/O operations
- Eliminates redundant sourcing of utils.zsh
- Clean separation of concerns

**Cons:**
- Loses modular structure
- Harder to understand what each tool contributes
- Requires generation step (similar to manifest approach)

### Strategy 4: Fix Redundant Sourcing ✅ COMPLETED

**Approach:** Source common files (like utils.zsh) once instead of in every shell.zsh file.

**Implementation:**
1. Move `source utils.zsh` from individual files to main .zshrc (before sourcing other files)
2. Remove all `source utils.zsh` lines from shell.zsh files
3. Ensure utils.zsh is sourced exactly once

**Result:** Removed from 56 files. **Massive improvement** reported by user.

**Pros:**
- Simple change
- Immediate improvement
- No architectural changes needed

**Cons:**
- Doesn't solve the fundamental `find` performance issue
- Still sourcing 69 files

### Strategy 5: Cache `eval` Results

**Approach:** Cache the output of expensive `eval` commands.

**Implementation:**
For each expensive `eval`:
```zsh
# Before
eval "$(mise activate zsh)"

# After
_mise_cache="${DOTFILES}/.cache/mise-activate.zsh"
if [[ ! -f "$_mise_cache" ]] || [[ $(mise --version) != $(cat "${_mise_cache}.version" 2>/dev/null) ]]; then
  mise activate zsh > "$_mise_cache"
  mise --version > "${_mise_cache}.version"
fi
source "$_mise_cache"
```

**Candidates for caching:**
- `mise activate zsh` - version manager activation
- `zoxide init zsh` - cd replacement
- `fzf --zsh` - fuzzy finder
- `fnm env` - node version manager
- `uv generate-shell-completion zsh` - Python tool completions
- `brew shellenv` - if still needed after manifest

**Pros:**
- Eliminates subprocess spawning on most startups
- Can be combined with other strategies

**Cons:**
- Cache can become stale if tool is updated
- Requires version checking logic
- Modest gains compared to fixing `find` issue

## Reassessment: Additional Low-Hanging Fruit

After Phase 1 completion, additional analysis revealed:

### No Redundant Operations Found ✅

1. **No duplicate source operations** - All removed in Phase 1
2. **No duplicate PATH exports** - Each tool adds unique paths
3. **Conditional loading working well** - 16 files use `if have` checks appropriately
4. **@archive exclusion working** - No archived files being sourced

### Potential Quick Wins Remaining

**None identified** in the "straight-forward" category like Phase 1.

Remaining optimizations require structural changes:
- **Phase 2** (manifest generation) - 60-80% improvement potential
- **Phase 3** (eval caching, lazy loading) - 15-30% additional improvement

### Current State

After Phase 1:
- ✅ Eliminated 56 redundant file sources
- ✅ Verified exclusion patterns working
- ✅ **Massive improvement** in startup time reported
- Still sourcing 34 shell.zsh files via 6 `find` operations
- Still running 6+ `eval` commands on startup

## Recommended Implementation Plan

### Phase 1: Quick Wins (Immediate) ✅ COMPLETED

1. **Fix redundant sourcing** (Strategy 4) ✅
   - ~~Move `source utils.zsh` to .zshrc:9~~ (already present)
   - Removed redundant `source utils.zsh` from 56 shell.zsh files
   - **Result:** Massive improvement reported by user

2. **Fix @archive exclusion** ✅
   - Verified find exclusion patterns work correctly
   - @archive directories are already properly excluded via `-prune` flag
   - **No changes needed** - exclusion already working

### Phase 2: Core Optimization (Primary fix for remaining slowness) ✅ COMPLETED

3. **Implement file manifest** (Strategy 1) ✅
   - Created `features/update/zsh/generate-manifest.zsh` script
   - Generates `.cache/shell-files-manifest.zsh` with all files to source
   - Modified `tools.zsh` to use manifest with automatic staleness detection
   - Added `regen` alias for manual regeneration (rarely needed)
   - Staleness check uses single `find` for timestamps (not full traversal)
   - **Estimated impact:** 60-80% improvement over Phase 1 state

### Phase 3: Advanced Optimization (Optional)

4. **Add lazy loading** (Strategy 2) for specific tools:
   - Identify rarely-used tools (claude, gcloud, etc.)
   - Implement lazy loading wrappers
   - **Estimated impact:** Additional 10-20% improvement

5. **Cache eval commands** (Strategy 5) for:
   - `mise activate zsh`
   - `zoxide init zsh`
   - `fzf --zsh`
   - `fnm env`
   - `uv generate-shell-completion zsh`
   - `brew shellenv` (if still needed after manifest)
   - **Estimated impact:** Additional 5-10% improvement

## Success Criteria

- [x] Phase 1: Massive improvement from removing redundant sources
- [ ] Shell startup time < 200ms (if further optimization needed)
- [ ] No performance regression when adding new tools
- [ ] Solution is maintainable (clear when manifest needs regeneration)
- [ ] All existing functionality preserved

## Measurement

Before Phase 1:
```zsh
# User reported slow startup
```

After Phase 1:
```zsh
zt  # User reported "massive improvement"
```

After Phase 2 (if implemented):
```zsh
zt  # Should show additional 60-80% improvement
```

## Files Modified (Phase 1)

- 56 `*/shell.zsh` and `*/shell/*.zsh` files - Removed `source utils.zsh` lines

## Files to Modify (Phase 2)

### Phase 2 (Core Optimization) - If Needed
- **New:** `features/update/zsh/generate-manifest.zsh` - Manifest generation script
- **New:** `${DOTFILES}/.cache/shell-files-manifest.zsh` - Generated manifest (gitignored)
- `tools/zsh/config/tools.zsh` - Replace `find` commands with manifest sourcing
- `features/update/zsh/homebrew.zsh` - Add manifest regeneration step
- `.gitignore` - Add `.cache/` directory

### Phase 3 (Advanced) - If Needed
- Individual tool shell.zsh files - Add lazy loading where appropriate
- **New:** Cache files in `.cache/` for eval results

## Non-Goals

- Don't migrate to bash yet (that's a separate project per CLAUDE.md)
- Don't change the tool directory structure
- Don't remove functionality or aliases

## Risks & Mitigations

**Risk:** Manifest gets out of sync after adding new tools
**Mitigation:**
- Add staleness check that compares manifest timestamp to newest .zsh file
- Include regeneration in update script
- Clear documentation about when to regenerate

**Risk:** Breaking changes to existing shell sessions
**Mitigation:**
- Test each phase independently
- Keep rollback plan (git revert)
- Verify all tools still work after changes

**Risk:** Lazy loading breaks tools that depend on each other
**Mitigation:**
- Only lazy-load truly independent tools
- Load dependencies eagerly if needed
- Document which tools are lazy-loaded
