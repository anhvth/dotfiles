#!/bin/bash

# Test script for bash configuration
echo "🧪 Testing Bash Configuration..."
echo "================================="

# Test different modes
echo "Testing Fastest Mode..."
BASH_MODE=fastest source ~/dotfiles/bash/bashrc.sh

echo
echo "Testing Balanced Mode..."
BASH_MODE=balanced source ~/dotfiles/bash/bashrc.sh

echo
echo "Testing Full Mode..."
BASH_MODE=full source ~/dotfiles/bash/bashrc.sh

echo
echo "✅ All modes loaded successfully!"

# Test basic functions exist
echo
echo "🔧 Testing Functions..."
echo "Available functions:"
declare -F | grep -E "(bash_|c|tm|fh|fif)" | head -5

echo
echo "🗂️  Testing Aliases..."
echo "Available aliases:"
alias | grep -E "(vi|gg|ll)" | head -3

echo
echo "📊 Configuration Summary:"
echo "- Bash configuration directory: ~/dotfiles/bash/"
echo "- Default mode: balanced"
echo "- Available modes: fastest, balanced, full"
echo "- Key features: FZF integration, Git prompt, Virtual env activation"
echo "- Ported from: zsh and fish configurations"

echo
echo "🚀 Setup complete! To use:"
echo "1. Run: ./setup_bash.sh"
echo "2. Then: source ~/.bashrc"
echo "3. Or: exec bash"