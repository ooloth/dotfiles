# Tools

Facts about how `tools/{name}/` directories actually work — properties
this repo's install/update automation and symlink model depend on, not
observations about typical practice.

- Every tool lives in its own `tools/{name}/` directory. `tools/@new/` is
  the template for creating one; `tools/@archive/` holds deprecated ones —
  neither is a real tool.
- A tool's config files live in `tools/{name}/config/`. The install/update
  automation and every `link.bash` depend on this path.
- Config files meant to live at a canonical filesystem location are
  symlinked — never copied — into place. Editing the repo copy must be
  enough to change the live config; a copy would silently stop reflecting
  edits.
- A `config/` directory with no `link.bash` is legitimate only for two
  reasons: the config is consumed directly by that tool's own install
  logic instead of being placed under `$HOME` (e.g. macOS defaults,
  applied via `defaults write`), or the config has no filesystem target at
  all and is meant for manual copy-paste elsewhere (e.g. a browser
  extension's settings).
