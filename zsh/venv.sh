venv() {
    case "$1" in
        --help|help)
            echo "Usage: venv [OPTION] [ARGS]"
            echo "Options:"
            echo "  --help                Show this help message"
            echo "  --list                List all available virtual environments"
            echo "  --create <python-version> <venv-name>"
            echo "                        Create a new virtual environment"
            echo "  --remove              Remove a selected virtual environment"
            echo "  --set-default         Set and activate the default virtual environment"
            echo "  --activate [venv-name]"
            echo "                        Activate a specific or default virtual environment"
            ;;
        --list|list)
            echo "Available virtual environments:"
            ls ~/python-venv
            ;;
        --create|create)
            if [ -z "$2" ] || [ -z "$3" ]; then
                echo "ℹ️  Usage: venv --create <python-version> <venv-name>"
                return 1
            fi
            local python_version=$2
            local venv_name=$3
            local oupath=~/python-venv/$venv_name
            local python_path=$(which $python_version 2>/dev/null)
            if [ -z "$python_path" ]; then
                echo "❌ Python version '$python_version' not found in PATH"
                return 1
            fi
            if [ -d "$oupath" ]; then
                echo "⚠️  Virtual environment '$venv_name' already exists."
                return 1
            fi
            mkdir -p ~/python-venv
            $python_path -m venv "$oupath"
            if [ $? -eq 0 ]; then
                echo "✅ Virtual environment created at $oupath"
            else
                echo "❌ Failed to create virtual environment"
                return 1
            fi
            ;;
        --remove|remove)
            local env_path=$(find ~/python-venv -mindepth 1 -maxdepth 1 -type d | fzf --prompt="Select a virtual environment to remove: ")
            if [ -n "$env_path" ]; then
                echo -n "⚠️  Are you sure you want to remove '$env_path'? [y/N]: "
                read confirmation
                if [[ "$confirmation" =~ ^[Yy]$ ]]; then
                    rm -rf "$env_path"
                    echo "✅ Removed virtual environment: $env_path"
                else
                    echo "ℹ️  Operation canceled."
                fi
            else
                echo "⚠️  No virtual environment selected."
            fi
            ;;
        --set-default|set-default)
            local env_path=$(find ~/python-venv -mindepth 1 -maxdepth 1 -type d | fzf)
            if [ -n "$env_path" ]; then
                if grep -q "^VIRTUAL_ENV=" ~/.env; then
                    sed -i.bak "s|^VIRTUAL_ENV=.*|VIRTUAL_ENV=$env_path|" ~/.env
                else
                    echo "VIRTUAL_ENV=$env_path" >> ~/.env
                fi
                echo "✅ Default VENV set to: $env_path"
                source "$env_path/bin/activate"
            else
                echo "⚠️  No virtual environment selected."
            fi
            ;;
        --activate|activate)
            local venv_name=$2
            if [ -z "$venv_name" ]; then
                # If no venv name provided, use default or try to select with fzf
                local default_env=""
                if [ -f ~/.env ] && grep -q "^VIRTUAL_ENV=" ~/.env; then
                    default_env=$(grep "^VIRTUAL_ENV=" ~/.env | cut -d= -f2)
                fi
                
                if [ -n "$default_env" ] && [ -d "$default_env" ]; then
                    source "$default_env/bin/activate"
                    echo "✅ Activated default virtual environment: $(basename $default_env)"
                else
                    local env_path=$(find ~/python-venv -mindepth 1 -maxdepth 1 -type d | fzf --prompt="Select a virtual environment to activate: ")
                    if [ -n "$env_path" ]; then
                        source "$env_path/bin/activate"
                        echo "✅ Activated virtual environment: $(basename $env_path)"
                    else
                        echo "⚠️  No virtual environment selected."
                    fi
                fi
            else
                local env_path=~/python-venv/$venv_name
                if [ -d "$env_path" ]; then
                    source "$env_path/bin/activate"
                    echo "✅ Activated virtual environment: $venv_name"
                else
                    echo "❌ Virtual environment '$venv_name' does not exist."
                fi
            fi
            ;;
        *)
            # Check if the first argument might be a venv name (without any flags)
            if [ -n "$1" ] && [ -d ~/python-venv/$1 ]; then
                source ~/python-venv/$1/bin/activate
                echo "✅ Activated virtual environment: $1"
            else
                venv --help
            fi
            ;;
    esac
}



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
        echo "❌ Failed to download Python $python_version"
        rm -rf "$temp_dir"
        return 1
    fi

    echo "ℹ️  Extracting Python $python_version..."
    tar -xzf "$temp_dir/Python-$python_version.tgz" -C "$temp_dir"
    if [ $? -ne 0 ]; then
        echo "❌ Failed to extract Python $python_version"
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
        echo "❌ Failed to build and install Python $python_version"
    fi

    rm -rf "$temp_dir"
}
