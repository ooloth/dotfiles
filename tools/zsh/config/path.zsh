# Default
export PATH="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:${PATH}" # Default system paths
export PATH="/opt/local/bin:/opt/local/sbin:${PATH}" # Add MacPorts to PATH
export PATH="${HOME}/.local/bin:${PATH}" # Add local bin to PATH

# Go
export PATH="${HOME}/go/bin:${PATH}"

# OpenSSL
export PATH="/opt/homebrew/opt/openssl@3/bin:${PATH}"

# Homebrew (keep last so will be at front of PATH)
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH" # Add Homebrew's executable directory to front of PATH
