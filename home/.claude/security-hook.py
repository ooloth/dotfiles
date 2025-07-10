#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["rich>=13.0.0", "cachetools>=5.0.0"]
# ///

"""
Claude Code Security Hook (Python Edition)
Protects against dangerous operations when running in YOLO mode
"""

import json
import sys
import os
import re
import time
import subprocess
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
from cachetools import TTLCache
from rich.console import Console
from rich.panel import Panel
from rich.text import Text

# Configuration
AUDIT_LOG = Path.home() / ".claude" / "security-audit.log"
BLOCKED_LOG = Path.home() / ".claude" / "blocked-commands.log"
STATS_FILE = Path.home() / ".claude" / "security-stats.json"
EMERGENCY_STOP = Path.home() / ".claude" / "emergency-stop"

# Performance caches (in-memory, TTL-based)
domain_cache = TTLCache(maxsize=1000, ttl=3600)  # 1 hour TTL
pattern_cache = TTLCache(maxsize=500, ttl=7200)   # 2 hour TTL
performance_metrics = {}

# Shared configuration
ALLOWED_DOMAINS = [
    "github.com",
    "githubusercontent.com", 
    "docs.anthropic.com",
    "anthropic.com",
    "stackoverflow.com",
    "developer.mozilla.org",
    "rust-lang.org",
    "python.org",
    "nodejs.org",
    "npmjs.com"
]

# Dangerous command patterns
DANGEROUS_PATTERNS = [
    # Network access
    r"(^|[\s;|&])curl[\s]+(-[^\s]*[oO][^\s]*|.*-o|.*--output)",  # curl with output flags
    r"(^|[\s;|&])wget[\s]",
    r"(^|[\s;|&])nc[\s]",
    r"(^|[\s;|&])netcat[\s]",
    r"(^|[\s;|&])telnet[\s]",
    r"(^|[\s;|&])scp[\s]",
    r"(^|[\s;|&])rsync[\s]+[^\s]*:",
    r"(^|[\s;|&])sftp[\s]",
    r"(^|[\s;|&])ftp[\s]",

    # System destruction (more comprehensive)
    r"(^|[\s;|&])rm[\s]+(-[^\s]*[rR][fF]?|--recursive.*--force|-rf|-fr|-R.*-f|-f.*-R)[\s]+(/|\$HOME|~|\*)",
    r"(^|[\s;|&])dd[\s]+.*of=/dev/",
    r"(^|[\s;|&])mkfs([\s]|$)",
    r"(^|[\s;|&])fdisk([\s]|$)",
    r"(^|[\s;|&])parted([\s]|$)",
    r"(^|[\s;|&])format([\s]|$)",
    r"(^|[\s;|&])diskutil[\s]+erase",
    r"(^|[\s;|&])shred[\s]",
    r"(^|[\s;|&])wipefs([\s]|$)",

    # Privilege escalation
    r"(^|[\s;|&])sudo[\s]",
    r"(^|[\s;|&])su[\s]+(-|[^\s]*)",
    r"(^|[\s;|&])chroot([\s]|$)",
    r"(^|[\s;|&])doas[\s]",
    r"(^|[\s;|&])runuser[\s]",

    # Package management
    r"(^|[\s;|&])brew[\s]+(install|uninstall|remove|cask[\s]+install)",
    r"(^|[\s;|&])apt[\s]+install",
    r"(^|[\s;|&])apt-get[\s]+(install|remove|purge)",
    r"(^|[\s;|&])yum[\s]+(install|remove|erase)",
    r"(^|[\s;|&])dnf[\s]+(install|remove|erase)",
    r"(^|[\s;|&])pip[\s]+install",
    r"(^|[\s;|&])pip3[\s]+install",
    r"(^|[\s;|&])npm[\s]+install[\s]+(-g|--global)",
    r"(^|[\s;|&])gem[\s]+install",
    r"(^|[\s;|&])cargo[\s]+install",

    # System services
    r"(^|[\s;|&])systemctl[\s]+(start|stop|restart|enable|disable|mask)",
    r"(^|[\s;|&])service[\s]+[^\s]+[\s]+(start|stop|restart)",
    r"(^|[\s;|&])launchctl[\s]+(load|unload|start|stop|bootstrap|bootout)",
    r"(^|[\s;|&])initctl[\s]",

    # Dangerous file operations
    r"[\s]*:[\s]*>[\s]*/etc/",
    r"[\s]*>[\s]*/etc/",
    r"[\s]*>>[\s]*/etc/",
    r"(^|[\s;|&])tee[\s]+(/etc/|/usr/|/bin/|/sbin/)",
    r"(^|[\s;|&])dd[\s]+.*of=/etc/",

    # Process control
    r"(^|[\s;|&])kill[\s]+(-9|-KILL)[\s]",
    r"(^|[\s;|&])killall([\s]|$)",
    r"(^|[\s;|&])pkill([\s]|$)",
    r"(^|[\s;|&])xkill([\s]|$)",

    # System modification
    r"(^|[\s;|&])crontab[\s]+(-[er]|--edit|--remove)",
    r"(^|[\s;|&])at[\s]+[0-9]",
    r"(^|[\s;|&])visudo([\s]|$)",
    r"(^|[\s;|&])passwd[\s]+[^\s]*",
    r"(^|[\s;|&])chpasswd([\s]|$)",
    
    # Kernel and boot
    r"(^|[\s;|&])insmod([\s]|$)",
    r"(^|[\s;|&])rmmod([\s]|$)",
    r"(^|[\s;|&])modprobe[\s]+(-r|--remove)",
    r"(^|[\s;|&])kextload([\s]|$)",
    r"(^|[\s;|&])kextunload([\s]|$)",
    
    # Network configuration
    r"(^|[\s;|&])iptables([\s]|$)",
    r"(^|[\s;|&])ip6tables([\s]|$)",
    r"(^|[\s;|&])ufw[\s]",
    r"(^|[\s;|&])firewall-cmd([\s]|$)",
    r"(^|[\s;|&])pfctl([\s]|$)",
]

PROTECTED_PATHS = [
    "/etc", "/usr", "/bin", "/sbin", "/boot", "/dev", "/lib", "/lib64",
    "/proc", "/sys", "/var/log", "~/.ssh", "~/.gnupg"
]

PROTECTED_PREFIXES = [
    "/etc", "/usr", "/bin", "/sbin", "/boot", "/lib", "/System", "/Library",
    "/private/etc", "/private/var", "~/.ssh", "~/.gnupg", "~/Library/Keychains"
]

BLOCKED_FILE_PATTERNS = [
    "*.pem", "*.key", "*.crt", "*.p12", "id_rsa*", "id_ed25519*", 
    "id_ecdsa*", "*.kdbx", "*.1password", "*.keychain"
]

class SecurityHook:
    def __init__(self):
        self.console = Console(stderr=True)
        self.ensure_directories()
        
    def ensure_directories(self):
        """Ensure audit log directories exist"""
        AUDIT_LOG.parent.mkdir(exist_ok=True)
        
    def is_yolo_mode(self) -> bool:
        """Check if running in YOLO mode by looking for the flag in process tree"""
        try:
            result = subprocess.run(
                ["pgrep", "-f", "claude.*--dangerously-skip-permissions"],
                capture_output=True, text=True
            )
            return result.returncode == 0
        except Exception:
            return False
            
    def log_command(self, status: str, tool: str, details: str):
        """Log command attempt with timestamp"""
        timestamp = datetime.now().strftime("%a %d %b %Y %H:%M:%S %Z")
        log_entry = f"{timestamp}: [{status}] {tool}: {details}\n"
        
        with open(AUDIT_LOG, "a") as f:
            f.write(log_entry)
            
    def block_command(self, reason: str, details: str, tool_name: str):
        """Block command and log the reason"""
        self.console.print(f"[red]BLOCKED:[/red] {reason}", style="bold red")
        
        timestamp = datetime.now().strftime("%a %d %b %Y %H:%M:%S %Z")
        block_entry = f"{timestamp}: {reason} - {details}\n"
        
        with open(BLOCKED_LOG, "a") as f:
            f.write(block_entry)
            
        self.log_command("BLOCKED", tool_name, details)
        self.update_security_stats("blocked")
        sys.exit(1)
        
    def update_security_stats(self, event_type: str):
        """Update security statistics"""
        stats = self.load_security_stats()
        today = datetime.now().strftime("%Y-%m-%d")
        
        if today not in stats["daily"]:
            stats["daily"][today] = {"blocked": 0, "allowed": 0}
            
        stats["daily"][today][event_type] += 1
        stats["total"][event_type] += 1
        
        with open(STATS_FILE, "w") as f:
            json.dump(stats, f, indent=2)
            
    def load_security_stats(self) -> Dict[str, Any]:
        """Load security statistics"""
        default_stats = {
            "total": {"blocked": 0, "allowed": 0},
            "daily": {},
            "threats_detected": [],
            "last_summary": None
        }
        
        if not STATS_FILE.exists():
            return default_stats
            
        try:
            with open(STATS_FILE, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            return default_stats
            
    def show_security_status(self):
        """Display current security status (Item 9: User Education)"""
        stats = self.load_security_stats()
        today = datetime.now().strftime("%Y-%m-%d")
        
        today_stats = stats["daily"].get(today, {"blocked": 0, "allowed": 0})
        
        # Create rich status display
        status_text = Text()
        status_text.append("🔒 YOLO Security Active\n", style="bold green")
        status_text.append(f"📊 Today: {today_stats['blocked']} commands blocked, {today_stats['allowed']} allowed\n")
        status_text.append(f"🛡️  Total: {stats['total']['blocked']} threats blocked\n")
        status_text.append(f"📝 Monitoring: Network, file system, privileges, packages\n")
        status_text.append(f"🚨 Emergency stop: touch ~/.claude/emergency-stop")
        
        panel = Panel(
            status_text,
            title="[bold blue]Claude Security Status[/bold blue]",
            border_style="blue"
        )
        
        self.console.print(panel)
        
    def is_ssh_localhost(self, command: str) -> bool:
        """Check if SSH command is to localhost"""
        ssh_pattern = r"ssh\s+([^\s]+)"
        match = re.search(ssh_pattern, command)
        if not match:
            return False
            
        target = match.group(1)
        localhost_patterns = [
            "localhost", "127.0.0.1", "::1",
            r"[^@]*@localhost", r"[^@]*@127\.0\.0\.1"
        ]
        
        for pattern in localhost_patterns:
            if re.match(f"^{pattern}$", target):
                return True
        return False
        
    def extract_and_validate_url(self, command: str) -> Optional[str]:
        """Extract and validate URL from command (Item 12: Performance caching)"""
        # Check cache first
        cache_key = f"url:{command}"
        if cache_key in domain_cache:
            performance_metrics["cache_hits"] = performance_metrics.get("cache_hits", 0) + 1
            return domain_cache[cache_key]
            
        start_time = time.time()
        
        # Extract URL using regex
        url_pattern = r"(https?|ftp)://[^\s]+"
        match = re.search(url_pattern, command)
        
        if not match:
            result = None
        else:
            url = match.group(0)
            # Basic URL validation
            if re.match(r"^(https?|ftp)://[a-zA-Z0-9.-]+", url):
                result = url
            else:
                result = None
                
        # Cache result and track performance
        domain_cache[cache_key] = result
        end_time = time.time()
        performance_metrics["url_extraction_time"] = performance_metrics.get("url_extraction_time", [])
        performance_metrics["url_extraction_time"].append(end_time - start_time)
        
        return result
        
    def check_dangerous_patterns(self, command: str) -> Optional[str]:
        """Check command against dangerous patterns (with caching)"""
        cache_key = f"pattern:{command}"
        if cache_key in pattern_cache:
            performance_metrics["pattern_cache_hits"] = performance_metrics.get("pattern_cache_hits", 0) + 1
            return pattern_cache[cache_key]
            
        start_time = time.time()
        
        for pattern in DANGEROUS_PATTERNS:
            if re.search(pattern, command):
                result = pattern
                break
        else:
            result = None
            
        # Cache result and track performance
        pattern_cache[cache_key] = result
        end_time = time.time()
        performance_metrics["pattern_check_time"] = performance_metrics.get("pattern_check_time", [])
        performance_metrics["pattern_check_time"].append(end_time - start_time)
        
        return result
        
    def check_bash_command(self, command: str):
        """Check bash command for security violations"""
        self.log_command("ATTEMPT", "Bash", command)
        
        # Emergency stop check
        if EMERGENCY_STOP.exists():
            self.block_command(
                "EMERGENCY STOP: All operations blocked. Remove ~/.claude/emergency-stop to continue.",
                command, "Bash"
            )
            
        # Special handling for SSH
        if re.search(r"(^|[\s;|&])ssh\s", command):
            if not self.is_ssh_localhost(command):
                self.block_command("SSH to external host not allowed", command, "Bash")
                
        # Check dangerous patterns
        dangerous_pattern = self.check_dangerous_patterns(command)
        if dangerous_pattern:
            self.block_command(
                f"Dangerous command pattern detected: {dangerous_pattern}",
                command, "Bash"
            )
            
        # Check protected paths
        for path in PROTECTED_PATHS:
            expanded_path = os.path.expanduser(path)
            if re.search(rf"(rm|mv|cp|chmod|chown).*{re.escape(expanded_path)}", command):
                self.block_command(f"Attempt to modify protected path: {path}", command, "Bash")
                
        # Check network commands
        if re.search(r"(^|[\s;|&])(curl|wget|fetch)\s", command):
            if re.search(r"(localhost|127\.0\.0\.1|::1)", command):
                self.log_command("ALLOWED", "Bash", f"{command} (localhost)")
            else:
                url = self.extract_and_validate_url(command)
                if url:
                    domain_match = re.match(r"^(https?|ftp)://([^/:]+)", url)
                    if domain_match:
                        domain = domain_match.group(2)
                        
                        # Check against allowed domains
                        allowed = any(domain.endswith(allowed_domain) for allowed_domain in ALLOWED_DOMAINS)
                        
                        if not allowed:
                            self.block_command(
                                f"Network access to non-whitelisted domain: {domain}",
                                command, "Bash"
                            )
                            
                        self.log_command("ALLOWED", "Bash", f"{command} (allowed domain: {domain})")
                    else:
                        self.block_command("Invalid URL format in network command", command, "Bash")
                else:
                    if re.search(r"(http|https|ftp)://", command):
                        self.block_command(
                            "Network access attempted but URL could not be validated",
                            command, "Bash"
                        )
                        
        self.log_command("ALLOWED", "Bash", command)
        self.update_security_stats("allowed")
        
    def check_file_operation(self, tool_name: str, file_path: str):
        """Check file operations for security violations"""
        self.log_command("ATTEMPT", tool_name, file_path)
        
        if not file_path:
            return
            
        # Normalize path
        abs_path = os.path.abspath(os.path.expanduser(file_path))
        
        # Check protected prefixes
        for prefix in PROTECTED_PREFIXES:
            expanded_prefix = os.path.expanduser(prefix)
            if abs_path.startswith(expanded_prefix):
                self.block_command("Attempt to modify protected file", file_path, tool_name)
                
        # Check blocked file patterns
        filename = os.path.basename(file_path)
        for pattern in BLOCKED_FILE_PATTERNS:
            if re.match(pattern.replace("*", ".*"), filename):
                self.block_command("Attempt to modify sensitive file type", file_path, tool_name)
                
        self.log_command("ALLOWED", tool_name, file_path)
        self.update_security_stats("allowed")
        
    def check_web_fetch(self, url: str):
        """Check WebFetch operations for security violations"""
        self.log_command("ATTEMPT", "WebFetch", url)
        
        domain_match = re.match(r"^(https?|ftp)://([^/:]+)", url)
        if domain_match:
            domain = domain_match.group(2)
            allowed = any(domain.endswith(allowed_domain) for allowed_domain in ALLOWED_DOMAINS)
            
            if not allowed:
                self.block_command(f"WebFetch to non-whitelisted domain: {domain}", url, "WebFetch")
        else:
            self.block_command("WebFetch URL has invalid format", url, "WebFetch")
            
        self.log_command("ALLOWED", "WebFetch", url)
        self.update_security_stats("allowed")
        
    def process_hook_input(self):
        """Main hook processing function"""
        try:
            # Read input from stdin
            input_data = sys.stdin.read()
            hook_data = json.loads(input_data)
            
            tool_name = hook_data.get("tool_name", "")
            tool_input = hook_data.get("tool_input", {})
            
            # Check if we're in YOLO mode
            if not self.is_yolo_mode():
                # Not in YOLO mode, allow everything
                sys.exit(0)
                
            # Show security status periodically (Item 9: User Education)
            stats = self.load_security_stats()
            last_summary = stats.get("last_summary")
            if not last_summary or datetime.fromisoformat(last_summary) < datetime.now() - timedelta(hours=24):
                self.show_security_status()
                stats["last_summary"] = datetime.now().isoformat()
                with open(STATS_FILE, "w") as f:
                    json.dump(stats, f, indent=2)
                    
            # Route to appropriate handler
            if tool_name == "Bash":
                command = tool_input.get("command", "")
                self.check_bash_command(command)
            elif tool_name in ["Write", "Edit", "MultiEdit"]:
                file_path = tool_input.get("file_path", "")
                self.check_file_operation(tool_name, file_path)
            elif tool_name == "WebFetch":
                url = tool_input.get("url", "")
                self.check_web_fetch(url)
                
            # All checks passed
            sys.exit(0)
            
        except json.JSONDecodeError:
            # Invalid JSON input, allow by default
            sys.exit(0)
        except Exception as e:
            # Log error but don't block (fail open for reliability)
            self.log_command("ERROR", "Hook", f"Exception: {str(e)}")
            sys.exit(0)

def main():
    hook = SecurityHook()
    hook.process_hook_input()

if __name__ == "__main__":
    main()