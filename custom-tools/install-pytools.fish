#!/usr/bin/env fish

# PyTools Installation Script
# This script installs the pytools package which provides centralized Python utilities

set pytools_dir "$HOME/dotfiles/custom-tools/pytools"

echo "🔧 Installing PyTools - Centralized Python Utilities"
echo "=================================================="

# Check if uv is available
if not command -v uv >/dev/null 2>&1
    echo "❌ uv is not installed. Please install uv first:"
    echo "   curl -LsSf https://astral.sh/uv/install.sh | sh"
    exit 1
end

# Check if pytools directory exists
if not test -d "$pytools_dir"
    echo "❌ PyTools directory not found at: $pytools_dir"
    exit 1
end

echo "📁 Found pytools directory: $pytools_dir"

# Navigate to pytools directory
cd "$pytools_dir"

# Install the package
echo "📦 Installing pytools package..."
if uv pip install -e . --system
    echo "✅ PyTools installed successfully!"
    echo ""
    echo "🎉 Available commands:"
    echo "   lsh                 - Execute commands in parallel with tmux"
    echo "   hf-down             - Download from Hugging Face Hub"
    echo "   kill-process-grep   - Interactive process killer"
    echo "   print-ipv4          - Show public IP address"
    echo "   cat-projects        - Create code snapshots for LLMs"
    echo "   organize-downloads  - Organize downloads by date"
    echo "   pyinit              - Initialize Python projects"
    echo "   keep-ssh            - Keep SSH connections alive"
    echo ""
    echo "💡 Note: Old fish aliases have been cleaned up."
    echo "   The tools are now available as system binaries."
else
    echo "❌ Failed to install pytools. Trying with virtual environment..."
    
    # Create and activate virtual environment
    if not test -d ".venv"
        echo "🔨 Creating virtual environment..."
        uv venv
    end
    
    echo "🔨 Installing in virtual environment..."
    if source .venv/bin/activate.fish && uv pip install -e .
        echo "✅ PyTools installed in virtual environment!"
        echo ""
        echo "⚠️  Commands are available in the virtual environment:"
        echo "   cd $pytools_dir && source .venv/bin/activate.fish"
        echo ""
        echo "🔗 You may want to add the venv bin directory to your PATH:"
        echo "   set -gx PATH $pytools_dir/.venv/bin \$PATH"
    else
        echo "❌ Installation failed!"
        exit 1
    end
end

echo ""
echo "🔄 Please restart your shell or run 'source ~/.config/fish/config.fish' to refresh aliases."