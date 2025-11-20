#!/usr/bin/env zsh

# Generate a manifest of all shell configuration files to source
# This eliminates expensive find operations on every shell startup

DOTFILES="${DOTFILES:-${HOME}/Repos/ooloth/dotfiles}"
MANIFEST="${DOTFILES}/.cache/shell-files-manifest.zsh"

# Create cache directory if it doesn't exist
mkdir -p "$(dirname "$MANIFEST")"

# Start writing the manifest
cat > "$MANIFEST" <<'EOF'
# Auto-generated manifest of shell configuration files
# Regenerate by running: zsh ${DOTFILES}/features/update/zsh/generate-manifest.zsh

############################
# COMPLETE SHELL.ZSH FILES #
############################

# Features shell.zsh files
EOF

# Find all shell.zsh files in features (except @new and @archive)
find "${DOTFILES}/features" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell.zsh" -print | sort | while read file; do
  echo "source \"${file}\"" >> "$MANIFEST"
done

cat >> "$MANIFEST" <<'EOF'

# Tools shell.zsh files
EOF

# Find all shell.zsh files in tools (except @new and @archive)
find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell.zsh" -print | sort | while read file; do
  echo "source \"${file}\"" >> "$MANIFEST"
done

cat >> "$MANIFEST" <<'EOF'

#####################################
# LEGACY: SHELL/VARIABLES.ZSH FILES #
#####################################

EOF

# Find all shell/variables.zsh files in tools (except @new and @archive)
find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell/variables.zsh" -print | sort | while read file; do
  echo "source \"${file}\"" >> "$MANIFEST"
done

cat >> "$MANIFEST" <<'EOF'

###################################
# LEGACY: SHELL/ALIASES.ZSH FILES #
###################################

EOF

# Find all shell/aliases.zsh files in features (except @new and @archive)
find "${DOTFILES}/features" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell/aliases.zsh" -print | sort | while read file; do
  echo "source \"${file}\"" >> "$MANIFEST"
done

# Find all shell/aliases.zsh files in tools (except @new and @archive)
find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell/aliases.zsh" -print | sort | while read file; do
  echo "source \"${file}\"" >> "$MANIFEST"
done

cat >> "$MANIFEST" <<'EOF'

#######################################
# LEGACY: SHELL/INTEGRATION.ZSH FILES #
#######################################

EOF

# Find all shell/integration.zsh files in tools (except @new and @archive)
find "${DOTFILES}/tools" -type d \( -name "@new" -o -name "@archive" \) -prune -o -type f -path "*/shell/integration.zsh" -print | sort | while read file; do
  echo "source \"${file}\"" >> "$MANIFEST"
done
