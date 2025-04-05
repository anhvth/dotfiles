venv_list() {
    ls ~/python-venv
}

# Function to activate a selected Python virtual environment
venv_atv() {
    local env_path
    env_path=$(find ~/python-venv -mindepth 1 -maxdepth 1 -type d | fzf)
    if [ -n "$env_path" ]; then
        source "$env_path/bin/activate"
        echo "ℹ️  Activated virtual environment: $env_path"
    else
        echo "⚠️  No virtual environment selected."
    fi
}
venv_create() {
    # Check if both arguments are provided
    if [ -z "$1" ] || [ -z "$2" ]; then
        echo "ℹ️  Usage: venv_create <python-version> <venv-name>"
        echo "ℹ️  Example: venv_create python3.9 my_project"
        return 1
    fi
    
    # Get parameters
    python_version=$1
    venv_name=$2
    oupath=~/python-venv/$venv_name
    
    # Find the Python executable
    python_path=$(which $python_version 2>/dev/null)
    
    if [ -z "$python_path" ]; then
        echo "❌ Python version '$python_version' not found in PATH"
        return 1
    fi
    
    echo "ℹ️  Creating virtual environment '$venv_name' using Python version '$python_path'..."
    
    # Check if venv already exists
    if [ -d "$oupath" ]; then
        echo "⚠️  Virtual environment '$venv_name' already exists. Please choose a different name."
        return 1
    fi
    
    # Create the virtual environment
    mkdir -p ~/python-venv
    $python_path -m venv "$oupath"
    
    if [ $? -eq 0 ]; then
        echo "✅ Virtual environment created successfully at $oupath"
        echo "ℹ️  To activate, run: source $oupath/bin/activate"
    else
        echo "❌ Failed to create virtual environment"
        return 1
    fi
}
venv_remove() {
    local env_path
    env_path=$(find ~/python-venv -mindepth 1 -maxdepth 1 -type d | fzf --prompt="Select a virtual environment to remove: " --header="Press [ESC] to cancel")
    if [ -n "$env_path" ]; then
        echo -n "⚠️  Are you sure you want to remove the virtual environment '$env_path'? [y/N]: "
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
}
venv() {
    # Select the default virtual environment
    local env_path
    env_path=$(find ~/python-venv -mindepth 1 -maxdepth 1 -type d | fzf)
    if [ -n "$env_path" ]; then
        # Check if VIRTUAL_ENV line exists in ~/.env
        if grep -q "^VIRTUAL_ENV=" ~/.env; then
            # Update the existing line
            sed -i.bak "/^VIRTUAL_ENV=/c\\VIRTUAL_ENV=$env_path" ~/.env
        else
            # Add a new line for VIRTUAL_ENV
            echo "VIRTUAL_ENV=$env_path" >> ~/.env
        fi
        echo "ℹ️  Set default virtual environment to: $env_path"
        source "$env_path/bin/activate"

    else
        echo "⚠️  No virtual environment selected."
    fi
}



# Function to activate the default virtual environment
atv() {
    if [ -n "$1" ]; then
        # If parameter is provided, activate that specific environment
        local env_path="$HOME/python-venv/$1"
        if [ -d "$env_path" ]; then
            source "$env_path/bin/activate"
            echo "ℹ️  Activated virtual environment: $env_path"
            # update VIRTUAL_ENV to ~/.env
            if grep -q "^VIRTUAL_ENV=" ~/.env; then
                sed -i.bak "/^VIRTUAL_ENV=/d" ~/.env
            fi
            echo "VIRTUAL_ENV=$env_path" >> ~/.env
        else
            echo "❌ Virtual environment '$1' not found in ~/python-venv/"
        fi
    else
        # No parameter, use fzf to select an environment
        local env_path
        env_path=$(find ~/python-venv -mindepth 1 -maxdepth 1 -type d | fzf --prompt="Select virtual environment to activate: ")
        if [ -n "$env_path" ]; then
            source "$env_path/bin/activate"
            echo "ℹ️  Activated virtual environment: $env_path"
            # update VIRTUAL_ENV to ~/.env
            if grep -q "^VIRTUAL_ENV=" ~/.env; then
                sed -i.bak "/^VIRTUAL_ENV=/d" ~/.env
            fi
            echo "VIRTUAL_ENV=$env_path" >> ~/.env
        else
            echo "⚠️  No virtual environment selected."
        fi
    fi
}

if [ -n "$VIRTUAL_ENV" ]; then
    # Check if the directory exists, if not, warn the user
    if [ ! -d "$VIRTUAL_ENV" ]; then
        echo "⚠️  Warning: The virtual environment directory '$VIRTUAL_ENV' does not exist. Please check your ~/.env file."
    else
        source "$VIRTUAL_ENV/bin/activate"
    fi
fi
