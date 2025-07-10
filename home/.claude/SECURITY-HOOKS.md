# Claude Code Security Hooks

This document describes the security hook system that protects your system when running Claude Code with `--dangerously-skip-permissions` (YOLO mode).

## Overview

The security hooks provide defense-in-depth protection by intercepting and validating all potentially dangerous operations before they execute. While not as secure as full containerization, this system blocks most accidental damage while maintaining excellent developer experience.

**Important**: These hooks ONLY activate when running Claude Code with the `--dangerously-skip-permissions` flag. Normal Claude Code usage is unaffected.

## Components

### 1. Security Hook Script (`~/.claude/security-hook.sh`)
- Validates all Bash commands, file operations, and web requests
- Blocks dangerous patterns and protected paths
- Logs all attempts and blocks for audit purposes

### 2. Audit Logs
- `~/.claude/security-audit.log` - All tool usage attempts
- `~/.claude/blocked-commands.log` - Blocked operations only

### 3. Emergency Stop
- Create `~/.claude/emergency-stop` file to block ALL operations
- Remove the file to resume normal operation

## What's Blocked

### Network Access
- External curl/wget commands (localhost allowed)
- SSH to external hosts
- Network utilities (nc, telnet)

### System Modifications
- Package managers (brew install, apt install, etc.)
- System services (systemctl, launchctl)
- Privilege escalation (sudo, su)
- System destruction (rm -rf /, mkfs, fdisk)

### Protected Paths
- System directories: /etc, /usr, /bin, /sbin, /boot
- Security files: ~/.ssh, ~/.gnupg, keychains
- Sensitive file types: *.key, *.pem, *.crt, id_rsa*

### Process Control
- kill -9, killall, pkill
- crontab modifications
- visudo

## Monitoring

Check audit logs to see what's happening:
```bash
# View recent activity
tail -f ~/.claude/security-audit.log

# View blocked commands
cat ~/.claude/blocked-commands.log

# Count blocked attempts by type
grep BLOCKED ~/.claude/security-audit.log | awk -F': ' '{print $3}' | sort | uniq -c
```

## Emergency Procedures

### If Claude Code is misbehaving:
1. **Immediate stop**: `touch ~/.claude/emergency-stop`
2. **Review logs**: Check what was attempted
3. **Resume when safe**: `rm ~/.claude/emergency-stop`

### To temporarily disable hooks:
1. Edit `~/.claude/settings.json`
2. Remove or comment out the `hooks` section
3. Remember to re-enable after!

## Customization

### Allow additional domains for WebFetch:
Edit the `ALLOWED_DOMAINS` array in `security-hook.sh`

### Add protected paths:
Edit the `PROTECTED_PATHS` or `PROTECTED_PREFIXES` arrays

### Modify dangerous patterns:
Edit the `DANGEROUS_PATTERNS` array

## Limitations

- Not as secure as Docker containerization
- Can potentially be bypassed by sophisticated attacks
- Some patterns may have false positives
- Performance overhead on every tool call

## Best Practices

1. **Regular review**: Check logs weekly
2. **Update patterns**: Add new dangerous patterns as discovered
3. **Test changes**: Verify hooks still work after modifications
4. **Backup first**: Always backup before running in YOLO mode
5. **Stay alert**: Watch for unusual behavior

Remember: These hooks are a safety net, not a guarantee. Use YOLO mode responsibly!