# Which Mac a Brewfile is evaluated on, by the same rule as tools/macos/utils.bash and shell.zsh:
# "Air" and "Mini" are the personal Macs, and every other name, an empty one included, is a work
# Mac. A Brewfile loads this with `require_relative "../macos/computer"`, which also resolves from
# tools/homebrew/Brewfile.generated, one folder down from tools/ like every tool's own Brewfile.
#
# Homebrew clears COMPUTER from the environment before it evaluates a Brewfile, so this asks
# networksetup itself. networksetup exists only on macOS; elsewhere the name is empty, so "work".

def computer_for(name)
  case name
  when "Air" then "air"
  when "Mini" then "mini"
  else "work"
  end
end

NETWORKSETUP = "/usr/sbin/networksetup"
COMPUTER = computer_for(File.executable?(NETWORKSETUP) ? `#{NETWORKSETUP} -getcomputername`.chomp : "")

def computer
  COMPUTER
end

def air?
  COMPUTER == "air"
end

def mini?
  COMPUTER == "mini"
end

def work?
  COMPUTER == "work"
end
