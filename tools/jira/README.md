# Jira CLI

[jira-cli](https://github.com/ankitpokhrel/jira-cli), set up on the work laptop only.

## Install

Install via Homebrew:
https://github.com/ankitpokhrel/jira-cli/wiki/Installation#homebrew

## Set up the token

1. Find the site's cloud ID: e.g. open https://recursion.atlassian.net/_edge/tenant_info and copy
   the `cloudId` value.
2. Create an API token:
   a. Go to https://id.atlassian.com/manage-profile/security/api-tokens
   b. Click "Create API token with scopes"
   c. Select "Jira" and click "Next"
   d. Select the scopes `read:jira-work`, `write:jira-work`, `read:jira-user`, `read:me`,
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

## Why it is set up this way

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
