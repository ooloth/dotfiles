# Claude Code Security Hooks

This document describes the security hook system that protects your system when running Claude Code with `--dangerously-skip-permissions` (YOLO mode).

## Overview

The security hooks provide defense-in-depth protection by intercepting and validating all potentially dangerous operations before they execute. While not as secure as full containerization, this system blocks most accidental damage while maintaining excellent developer experience.

**Important**: These hooks activate when running Claude Code in YOLO mode with the proper environment variable set. Normal Claude Code usage is unaffected.

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

### Network Access (Domain Whitelisting)
- **curl/wget to non-whitelisted domains** - Only allowed: github.com, docs.anthropic.com, stackoverflow.com, etc.
- **SSH to external hosts** - Only localhost/127.0.0.1 allowed
- **Network utilities** - nc, netcat, telnet, scp, sftp, ftp, rsync to external hosts

### System Destruction Prevention
- **Recursive file deletion** - rm -rf targeting /, $HOME, ~, or *
- **Disk operations** - dd to /dev/, mkfs, fdisk, parted, format
- **Data destruction** - shred, wipefs, diskutil erase

### Privilege Escalation
- **Privilege commands** - sudo, su, chroot, doas, runuser

### Package Management
- **Installation commands** - brew install, apt install, pip install, npm -g, gem install, cargo install
- **Removal commands** - brew uninstall, apt remove, yum erase

### System Services
- **Service control** - systemctl start/stop/restart, launchctl load/unload, service commands
- **System daemons** - initctl operations

### Protected Paths
- **System directories** - /etc, /usr, /bin, /sbin, /boot, /lib, /System, /Library
- **Security files** - ~/.ssh, ~/.gnupg, keychains, certificates
- **Sensitive file types** - *.key, *.pem, *.crt, *.p12, id_rsa*, *.kdbx, *.1password

### Process Control
- **Forced termination** - kill -9, killall, pkill, xkill
- **System scheduling** - crontab modifications, at commands
- **System administration** - visudo, passwd, chpasswd

### Kernel and Network Configuration
- **Kernel modules** - insmod, rmmod, modprobe, kextload/kextunload
- **Firewall rules** - iptables, ufw, firewall-cmd, pfctl

## User Education & Security Awareness

### Security Status Indicators
When the hooks are active, you'll see clear feedback:
```
🔒 YOLO Security Active - Enhanced protection engaged
📊 Today: 3 commands blocked, 47 allowed
🛡️  Monitoring: Network, file system, privileges, packages
🚨 Emergency stop: touch ~/.claude/emergency-stop
```

### Understanding Protection Levels
The security hooks provide **defense-in-depth** protection:

1. **🌐 Network Protection** - Only whitelisted domains allowed for external access
2. **🗂️  File System Protection** - System directories and sensitive files protected  
3. **⚡ Privilege Protection** - No unauthorized system-level changes
4. **📦 Package Protection** - Prevents installation of potentially malicious packages
5. **🔧 Service Protection** - System services remain stable and secure

### Daily Security Summary
Check your security posture regularly:
```bash
# Quick security overview
echo "🔒 Security Summary for $(date +%Y-%m-%d)"
echo "📊 Commands blocked today: $(grep "$(date +%Y-%m-%d)" ~/.claude/blocked-commands.log | wc -l)"
echo "📈 Total protection events: $(wc -l < ~/.claude/security-audit.log)"
echo "🚨 Last threat blocked: $(tail -1 ~/.claude/blocked-commands.log | cut -d':' -f1-2)"
```

## Monitoring

Check audit logs to see what's happening:
```bash
# View recent activity
tail -f ~/.claude/security-audit.log

# View blocked commands  
cat ~/.claude/blocked-commands.log

# Count blocked attempts by type
grep BLOCKED ~/.claude/security-audit.log | awk -F': ' '{print $3}' | sort | uniq -c

# Security dashboard
echo "=== Claude Security Dashboard ==="
echo "Active since: $(head -1 ~/.claude/security-audit.log | cut -d':' -f1-2)"
echo "Total events: $(wc -l < ~/.claude/security-audit.log)"
echo "Threats blocked: $(grep -c BLOCKED ~/.claude/security-audit.log)"
echo "Commands allowed: $(grep -c ALLOWED ~/.claude/security-audit.log)"
echo "Protection rate: $(( $(grep -c BLOCKED ~/.claude/security-audit.log) * 100 / $(wc -l < ~/.claude/security-audit.log) ))%"
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

## Usage

The security hooks activate when Claude Code is running in YOLO mode with the proper environment variable set.

### Basic Usage

1. **Normal Claude Code usage** - Security hooks remain inactive
   ```bash
   claude
   ```

2. **YOLO mode with security protection** - Set environment variable to activate hooks
   ```bash
   CLAUDE_YOLO_MODE=true claude --dangerously-skip-permissions
   ```

**Important**: Due to Claude Code's process isolation, the hooks cannot automatically detect YOLO mode from command-line arguments. You must set the `CLAUDE_YOLO_MODE=true` environment variable to activate security protection.

### Alternative Activation Methods

For testing or troubleshooting:
```bash
# Manual override (for testing)
touch ~/.claude/yolo-mode-override
claude --dangerously-skip-permissions

# Remove override when done
rm ~/.claude/yolo-mode-override
```

## Limitations

- **Manual environment setup required** - Must set CLAUDE_YOLO_MODE=true for activation
- **Not containerized isolation** - Not as secure as Docker/sandbox environments
- **Sophisticated bypass potential** - Advanced users could potentially circumvent patterns
- **Pattern matching limitations** - Complex command obfuscation might evade detection
- **Minimal performance overhead** - ~1-2ms per tool call (negligible in practice)

## Best Practices

1. **Regular review**: Check logs weekly
2. **Update patterns**: Add new dangerous patterns as discovered
3. **Test changes**: Verify hooks still work after modifications
4. **Backup first**: Always backup before running in YOLO mode
5. **Stay alert**: Watch for unusual behavior

Remember: These hooks are a safety net, not a guarantee. Use YOLO mode responsibly!