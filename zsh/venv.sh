# Activate a virtual environment
atv() {
    local lst selected_venv

    lst="$(ls ~/python-venv/*/bin/activate 2>/dev/null)"
    if [ -z "$lst" ]; then
        echo "❌ No virtual environments found in ~/python-venv."
        return 1
    fi

    if [ -z "$1" ]; then
        selected_venv=$(echo "$lst" | fzf --height 40% --reverse --inline-info \
            --preview 'head -n 10 {}' --preview-window=up:30%:wrap)
    else
        selected_venv="$1"
    fi

    if [ -z "$selected_venv" ]; then
        echo "❌ No virtual environment selected."
        return 1
    fi

    set_env "VIRTUAL_ENV" "$selected_venv"
    zsh
}

# Create a virtual environment
venv_create() {
    if [ -z "$1" ]; then
        echo "ℹ️  Usage: venv_create <venv-name>"
        return 1
    fi

    local venv_name=$1
    local venv_dir=~/python-venv/$venv_name

    if [ -d "$venv_dir" ]; then
        echo "❌ Virtual environment '$venv_name' already exists."
        return 1
    fi

    python3 -m venv "$venv_dir"
    if [ $? -eq 0 ]; then
        echo "✅ Virtual environment '$venv_name' created at $venv_dir"
        source "$venv_dir/bin/activate"
    else
        echo "❌ Failed to create virtual environment '$venv_name'."
    fi
}

# Install a specific Python version
install_python() {
    if [ -z "$1" ]; then
        echo "ℹ️  Usage: install_python <python-version>"
        return 1
    fi

    local python_version=$1
    local python_url="https://www.python.org/ftp/python/$python_version/Python-$python_version.tgz"
    local temp_dir=$(mktemp -d)
    local install_dir=~/python-builds/$python_version

    echo "ℹ️  Downloading Python $python_version..."
    curl -o "$temp_dir/Python-$python_version.tgz" "$python_url"
    if [ $? -ne 0 ]; then
        echo "❌ Failed to download Python $python_version."
        rm -rf "$temp_dir"
        return 1
    fi

    echo "ℹ️  Extracting Python $python_version..."
    tar -xzf "$temp_dir/Python-$python_version.tgz" -C "$temp_dir"
    if [ $? -ne 0 ]; then
        echo "❌ Failed to extract Python $python_version."
        rm -rf "$temp_dir"
        return 1
    fi

    echo "ℹ️  Building and installing Python $python_version..."
    cd "$temp_dir/Python-$python_version"
    ./configure --prefix="$install_dir" && make && make install
    if [ $? -eq 0 ]; then
        echo "✅ Python $python_version installed at $install_dir"
        echo "ℹ️  Add $install_dir/bin to your PATH to use this Python version."
    else
        echo "❌ Failed to build and install Python $python_version."
    fi

    rm -rf "$temp_dir"
}


