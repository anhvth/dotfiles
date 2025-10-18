#!/bin/bash
set -e

echo "🔧 Fixing Zsh autoload and compinit issues..."

# 1. Ensure Zsh is installed
if ! command -v zsh >/dev/null 2>&1; then
  echo "⚠️ Zsh not found. Installing with Homebrew..."
  brew install zsh
fi

# 2. Remove broken zcompdump cache files
echo "🧹 Cleaning up old .zcompdump files..."
rm -f ~/.zcompdump* || true

# 3. Restore default fpath directories
ZSH_PATHS=(
  "/usr/share/zsh/functions"
  "/usr/local/share/zsh/functions"
  "/opt/homebrew/share/zsh/functions"
  "/usr/share/zsh/site-functions"
  "/usr/local/share/zsh/site-functions"
  "/opt/homebrew/share/zsh/site-functions"
)

echo "🔍 Checking valid Zsh function paths..."
VALID_PATHS=()
for p in "${ZSH_PATHS[@]}"; do
  if [ -d "$p" ]; then
    VALID_PATHS+=("$p")
  fi
done

if [ ${#VALID_PATHS[@]} -eq 0 ]; then
  echo "❌ No valid Zsh function paths found. Reinstalling Zsh..."
  brew reinstall zsh
fi

# 4. Fix .zshrc configuration
ZSHRC=~/.zshrc
echo "📝 Updating $ZSHRC..."

cat <<'EOF' > "$ZSHRC"
# --- Zsh Clean Base Config ---

# Fix fpath for autoload functions
fpath=(
  /usr/local/share/zsh/site-functions
  /usr/local/share/zsh/functions
  /opt/homebrew/share/zsh/site-functions
  /opt/homebrew/share/zsh/functions
  $fpath
)

autoload -Uz compinit add-zsh-hook is-at-least
compinit -u

# Basic prompt
PROMPT='%F{green}%n@%m%f %F{blue}%1~%f %# '

# Aliases (optional)
alias ll='ls -la'
EOF

echo "✅ Updated .zshrc successfully."

# 5. Remove VS Code temporary Zsh files
TEMP_DIR=$(find /private/var/folders -type d -name "*zsh*" 2>/dev/null | grep "code-insiders-zsh" || true)
if [ -n "$TEMP_DIR" ]; then
  echo "🗑️ Removing temporary VS Code Zsh folder..."
  rm -rf "$TEMP_DIR"
fi

# 6. Reinitialize Zsh
echo "🔁 Reloading shell..."
exec zsh -l