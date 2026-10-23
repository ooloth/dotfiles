# Jira CLI

Two Jira CLIs, set up on the work laptop only, for when the Atlassian MCP server will not connect:

- [acli](https://developer.atlassian.com/cloud/acli/guides/introduction/), Atlassian's own CLI,
  is the one to use.
- [jira-cli](https://github.com/ankitpokhrel/jira-cli) stays until acli has worked at least as
  well for a week, and is then removed ([#196](https://github.com/ooloth/dotfiles/issues/196)).

## acli

### Install

`tools/jira/Brewfile` installs it from Atlassian's tap, `atlassian/acli`. Homebrew refuses to load
a formula from a tap it does not trust, and `tools/homebrew/update.bash` trusts every tap that is
already tapped, so on a fresh machine run `brew trust --taps atlassian/acli` once after the first
`brew bundle` taps it, then bundle again.

Atlassian supports each acli version for 6 months after its release
([install guide](https://developer.atlassian.com/cloud/acli/guides/install-macos/)), and `u`
upgrades it with every other formula.

### Log in

```sh
acli jira auth login --web
```

Choose `recursion.atlassian.net` at the site prompt and accept the grant in the browser. Then
`acli jira auth status` reports `Authenticated` with `Authentication Type: oauth`.

### Why it is set up this way

acli logs in with OAuth because it rejects a scoped API token for writes. Tested with acli
1.3.39 on 2026-10-22: the scoped token below logged in, but posting a comment returned
`401 Unauthorized; scope does not match` with `X-Failure-Category: FAILURE_CLIENT_SCOPE_CHECK`.
acli writes through its own endpoint, `api.atlassian.com/acli/<cloudId>/…`, not Jira's public
REST API, and its help text documents API tokens only "without scopes". An unscoped token would
work, but it can do anything the account can across Jira and Confluence, which is what the scoped
token below exists to avoid.

The OAuth grant is broader than the scoped token. The consent screen asks for:

- **Jira:** `read:jira-work`, `write:jira-work`, `read:jira-user`, `manage:jira-project` and
  `manage:jira-configuration`
- **Confluence:** read and write on content, spaces and properties, and
  `manage:confluence-configuration`
- **User:** `read:me`

Atlassian checks each request against the account's own permissions as well as the grant, so for
an account that is not a site admin the `manage:*` scopes add nothing it could not already do in
the browser. The grant is revoked under connected apps at
https://id.atlassian.com/manage-profile/apps.

acli keeps the OAuth token in the login keychain through
[`zalando/go-keyring`](https://github.com/zalando/go-keyring). The files it writes to
`~/.config/acli/` hold the site, cloud ID, account ID, name, email and auth type, and no token.
Nothing in this repo links or tracks them.

acli sends usage analytics to `as.atlassian.com` on every command: a hashed user ID, an anonymous
ID, the cloud ID, the command name, its flag names and its duration. The comment body is not in
the event. No setting or environment variable turns this off in acli 1.3.39.

## jira-cli

### Install

Install via Homebrew:
https://github.com/ankitpokhrel/jira-cli/wiki/Installation#homebrew

### Set up the token

1. Find the site's cloud ID: e.g. open https://recursion.atlassian.net/_edge/tenant_info and copy
   the `cloudId` value.
2. Create an API token:

   - Go to https://id.atlassian.com/manage-profile/security/api-tokens
   - Click "Create API token with scopes"
   - Select "Jira" and click "Next"
   - Select the scopes `read:jira-work`, `write:jira-work`, `read:jira-user`, `read:me`,
     `read:account`, `read:project:jira`, `read:board-scope:jira-software` and
     `write:board-scope:jira-software`. `jira init` lists the project's boards through Jira
     Software's agile API, which needs both `read:project:jira` and
     `read:board-scope:jira-software`
     ([Get all boards](https://developer.atlassian.com/cloud/jira/software/rest/api-group-board/)).
     A scope cannot be added to a token later. The token expires within a year, so note the date.

3. Copy the token, store it in the login keychain from the clipboard, then clear the clipboard.
   The interactive prompt (`-w` with nothing after it) keeps only the first 128 characters, which
   cuts the token off. `$(pbpaste)` keeps the token out of shell history:

   ```sh
   security add-generic-password -a <your-work-email> -s jira-cli -w "$(pbpaste)"
   pbcopy < /dev/null
   ```

4. Point jira-cli at Atlassian's API gateway rather than the site:

   ```sh
   jira init --installation cloud --server https://api.atlassian.com/ex/jira/<cloudId> --login <your-work-email> --force
   ```

5. Run `jira me`, choose "Always Allow" at the keychain prompt, and expect your email back.

To replace an expired token, create a new one and run step 3 with `-U` added, which updates the
existing item.

### Why it is set up this way

jira-cli looks for the token in `JIRA_API_TOKEN` first, then `.netrc`, then a keychain item named
`jira-cli` whose account is your login
([discussion #356](https://github.com/ankitpokhrel/jira-cli/discussions/356)). The keychain keeps
the token out of every shell's environment, where any command or agent could print it, and out of
plain-text files. The login keychain does not sync off this laptop. So `JIRA_API_TOKEN` is never
exported.

A scoped token limits what a lost token can do to Jira work items, where an unscoped one can do
anything the account can across Jira and Confluence. Atlassian accepts a scoped token only through
`api.atlassian.com/ex/jira/<cloudId>`, not the site URL. jira-cli 1.7.0 has no scoped-token
support of its own ([PR #928](https://github.com/ankitpokhrel/jira-cli/pull/928) is unmerged),
and setting `--server` to the gateway is the workaround reported in
[issue #850](https://github.com/ankitpokhrel/jira-cli/issues/850). If `jira me` returns 401
through the gateway, create an unscoped token instead and run step 4 with
`--server https://recursion.atlassian.net`.
