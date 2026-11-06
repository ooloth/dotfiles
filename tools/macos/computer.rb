# Which Mac a Brewfile is evaluated on, by the same rule as tools/macos/utils.bash and shell.zsh:
# "Air" and "Mini" are the personal Macs, and every other name, an empty one included, is a work
# Mac. A Brewfile loads this with `require_relative "../macos/computer"`, which also resolves from
# tools/homebrew/Brewfile.generated, one folder down from tools/ like every tool's own Brewfile.
#
# Homebrew's bin/brew re-runs itself under `env -i`, keeping only a short list of variables and
# every HOMEBREW_* one, so COMPUTER never reaches a Brewfile and this asks networksetup itself.
# networksetup exists only on macOS; elsewhere the name is empty, so "work".

def computer_for(name)
  case name
  when "Air" then "air"
  when "Mini" then "mini"
  else "work"
  end
end

NETWORKSETUP = "/usr/sbin/networksetup"
name = File.executable?(NETWORKSETUP) ? `#{NETWORKSETUP} -getcomputername`.chomp : ""
COMPUTER = computer_for(name)

def air?
  COMPUTER == "air"
end

def mini?
  COMPUTER == "mini"
end

def work?
  COMPUTER == "work"
end
