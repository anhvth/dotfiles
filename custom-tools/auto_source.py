#!/usr/bin/env python3
import os
from pathlib import Path
from typing import Optional
import json as std_json

try:
    import json5
except ImportError:
    # run pip install json5 if json5 is not available
    os.system('pip install json5')
    import json5

# from loguru import logger


def find_venv_python() -> Optional[Path]:
    """Find Python executable in virtual environment."""
    current_dir = Path.cwd()
    
    # Check current directory and up to 3 parent directories
    search_dirs = [current_dir]
    for i in range(3):
        parent = search_dirs[-1].parent
        if parent != search_dirs[-1]:  # Not at filesystem root
            search_dirs.append(parent)
        else:
            break
    
    # Check common venv locations in each directory
    venv_patterns = [
        'venv/bin/python',
        '.venv/bin/python',
        'env/bin/python',
    ]
    
    for search_dir in search_dirs:
        for pattern in venv_patterns:
            venv_python = search_dir / pattern
            if venv_python.exists():
                print(f'Found venv Python: {venv_python}')
                return venv_python
    
    return None


def update_vscode_settings(python_path: Path) -> None:
    """Update .vscode/settings.json with Python interpreter path."""
    vscode_dir = Path('.vscode')
    settings_file = vscode_dir / 'settings.json'
    
    # Create .vscode directory if it doesn't exist
    vscode_dir.mkdir(exist_ok=True)
    
    # Load existing settings or create new
    settings = {}
    if settings_file.exists():
        try:
            with open(settings_file, 'r') as f:
                content = f.read()
                settings = json5.loads(content)
        except (std_json.JSONDecodeError, ValueError):
            print('Invalid JSON in settings.json, creating new')

    # Update Python interpreter path
    settings['python.defaultInterpreterPath'] = str(python_path.absolute()) # type: ignore
    settings['python.analysis.typeCheckingMode'] = 'basic' # type: ignore
    
    # Write updated settings using standard json for output
    with open(settings_file, 'w') as f:
        std_json.dump(settings, f, indent=4)
    


def main() -> None:
    """Main function to find venv and update VS Code settings."""
    python_path = find_venv_python()
    if python_path is None:
        print('No virtual environment found')
        return
    
    update_vscode_settings(python_path)
    print('VS Code settings updated successfully')


if __name__ == '__main__':
    main()
