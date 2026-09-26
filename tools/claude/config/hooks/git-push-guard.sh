#!/bin/bash
# Stop a git push that would run inside the sandbox and fail on its proxy. Only a Bash call that is
# exactly `git push origin …`, with nothing chained, piped or redirected, matches the sandbox
# exclusion, so every other push is blocked here with the command to use instead.
cmd=$(jq -r '.tool_input.command // empty')
[[ $cmd =~ ^git[[:space:]]+push[[:space:]]+origin([[:space:]][^\|\&\;\<\>\`\$\(]*)?$ ]] && exit 0

# Look for a push only where a command starts, so text that merely mentions one passes: drop
# everything from a heredoc onward, then the contents of quoted strings.
code=${cmd%%<<*}
code=$(sed -E "s/'[^']*'//g; s/\"[^\"]*\"//g" <<<"$code")
[[ $code =~ (^|[\;\&\|\(\`]|\$\()[[:space:]]*git([[:space:]]+-C[[:space:]]+[^[:space:]]+)?[[:space:]]+push([[:space:]]|$) ]] || exit 0

echo "This push would run inside the sandbox and fail on its proxy. Run \`git push origin <branch>\` as a Bash call of its own: no pipe, &&, ; or redirect, and nothing before it such as cd or git -C." >&2
# Exit 2 cancels the call and shows Claude the message above, which is all this needs. The JSON
# "deny" form does the same with more to get wrong.
exit 2
