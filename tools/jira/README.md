# Jira CLI

[acli](https://developer.atlassian.com/cloud/acli/guides/introduction/), Atlassian's own Jira CLI,
set up on the work laptop only, for when the Atlassian MCP server will not connect.

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

Choose the site in `$PRIVATE_JIRA_SITE` (see `private.env.example`) at the site prompt and
accept the grant in the browser. Then `acli jira auth status` reports `Authenticated` with
`Authentication Type: oauth`.

### Why it is set up this way

acli logs in with OAuth because it rejects a scoped API token for writes. Tested with acli
1.3.39 on 2026-10-22: a scoped API token logged in, but posting a comment returned
`401 Unauthorized; scope does not match` with `X-Failure-Category: FAILURE_CLIENT_SCOPE_CHECK`.
acli writes through its own endpoint, `api.atlassian.com/acli/<cloudId>/…`, not Jira's public
REST API, and its help text documents API tokens only "without scopes". An unscoped token would
work, but it can do anything the account can across Jira and Confluence, which is what a scoped
token would avoid.

The OAuth grant is broader than a scoped token would be. The consent screen asks for:

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
