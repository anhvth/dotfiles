#!/usr/bin/env uv
"""
Python Package Initializer

A comprehensive tool to create production-ready Python packages with:
- Proper src/ layout structure
- Complete pyproject.toml configuration
- Development tools setup (testing, linting, formatting)
- Interactive dependency selection
- Documentation scaffolding
- CI/CD templates
"""

import argparse
import subprocess
import sys
from pathlib import Path
from textwrap import dedent
from typing import Union


PY_GITIGNORE = dedent(
    """
    # Byte-compiled / optimized / DLL files
    __pycache__/
    *.py[cod]
    *$py.class

    # C extensions
    *.so

    # Distribution / packaging
    .Python
    build/
    develop-eggs/
    dist/
    downloads/
    eggs/
    .eggs/
    lib/
    lib64/
    parts/
    sdist/
    var/
    wheels/
    pip-wheel-metadata/
    share/python-wheels/
    *.egg-info/
    .installed.cfg
    *.egg
    MANIFEST

    # Virtual environments
    venv/
    ENV/
    env/
    .venv/
    .env/

    # PyInstaller
    *.manifest
    *.spec

    # Installer logs
    pip-log.txt
    pip-delete-this-directory.txt

    # Unit test / coverage reports
    htmlcov/
    .tox/
    .nox/
    .coverage
    .coverage.*
    .cache
    nosetests.xml
    coverage.xml
    *.cover
    *.py,cover
    .hypothesis/
    .pytest_cache/

    # MyPy
    .mypy_cache/
    .dmypy.json
    dmypy.json

    # Pyre type checker
    .pyre/

    # pytype static type analyzer
    .pytype/

    # Cython debug symbols
    cython_debug/

    # IDEs
    .vscode/
    .idea/
    *.swp
    *.swo
    *~

    # OS
    .DS_Store
    Thumbs.db
    """
)


class PackageConfig:
    """Configuration for the Python package being created."""

    def __init__(self):
        self.name: str = ""
        self.description: str = ""
        self.author: str = ""
        self.email: str = ""
        self.version: str = "0.1.0"
        self.python_version: str = ">=3.8"
        self.license: str = "MIT"
        self.dependencies: list[str] = []
        self.dev_dependencies: list[str] = []
        self.include_cli: bool = False
        self.cli_name: str = ""


def run_cmd(cmd: list[str], cwd: Union[Path, None] = None) -> None:
    """Run a shell command and exit on failure."""
    try:
        subprocess.run(cmd, cwd=cwd, check=True)
    except subprocess.CalledProcessError as e:
        print(f"❌ Command failed: {cmd}\n{e}")
        exit(1)


def get_user_input() -> PackageConfig:
    """Collect package information from user."""
    config = PackageConfig()

    print("🚀 Python Package Initializer")
    print("=" * 40)

    config.name = input("📦 Package name: ").strip()
    if not config.name:
        print("❌ Package name is required!")
        exit(1)

    config.description = input("📝 Description (A Python package for...): ").strip()
    if not config.description:
        config.description = "A Python package"

    config.author = input("👤 Author name: ").strip()
    config.email = input("📧 Author email: ").strip()

    version = input("🔢 Version (0.1.0): ").strip()
    if version:
        config.version = version

    python_ver = input("🐍 Python version requirement (>=3.8): ").strip()
    if python_ver:
        config.python_version = python_ver

    license_choice = input("📄 License (MIT): ").strip()
    if license_choice:
        config.license = license_choice

    # CLI option
    cli_choice = input("🖥️  Include CLI entry point? (y/N): ").strip().lower()
    if cli_choice in ["y", "yes"]:
        config.include_cli = True
        config.cli_name = input(f"   CLI command name ({config.name}): ").strip()
        if not config.cli_name:
            config.cli_name = config.name

    return config


def select_dependencies() -> tuple[list[str], list[str]]:
    """Interactive dependency selection."""
    print("\n📚 Select dependencies:")

    # Common production dependencies
    common_deps = {
        "requests": "HTTP library for API calls",
        "pydantic": "Data validation and settings management",
        "click": "Command line interface creation",
        "fastapi": "Modern web framework for APIs",
        "pandas": "Data analysis and manipulation",
        "numpy": "Scientific computing",
        "python-dotenv": "Load environment variables from .env files",
        "rich": "Rich text and beautiful formatting in terminal",
        "typer": "Type-based CLI framework",
    }

    # Development dependencies (usually selected)
    dev_deps = {
        "pytest": "Testing framework",
        "pytest-cov": "Coverage plugin for pytest",
        "black": "Code formatter",
        "ruff": "Fast Python linter and formatter",
        "mypy": "Static type checker",
        "pre-commit": "Git pre-commit hooks",
    }

    selected_deps = []
    selected_dev_deps = []

    print(
        "Select production dependencies (enter numbers separated by spaces, or 'skip'):"
    )
    for i, (dep, desc) in enumerate(common_deps.items(), 1):
        print(f"  {i}. {dep} - {desc}")

    deps_input = input("Dependencies: ").strip()
    if deps_input.lower() != "skip":
        try:
            indices = [int(x) for x in deps_input.split()]
            dep_list = list(common_deps.keys())
            selected_deps = [
                dep_list[i - 1] for i in indices if 1 <= i <= len(dep_list)
            ]
        except (ValueError, IndexError):
            print("⚠️ Invalid selection, skipping dependencies")

    # Custom dependencies
    custom_deps = input("Additional dependencies (comma-separated): ").strip()
    if custom_deps:
        selected_deps.extend(
            [dep.strip() for dep in custom_deps.split(",") if dep.strip()]
        )

    # Development dependencies - auto-select recommended ones
    print("\nDevelopment dependencies (recommended tools will be included):")
    for dep, desc in dev_deps.items():
        print(f"  ✓ {dep} - {desc}")

    skip_dev = input("Skip development dependencies? (y/N): ").strip().lower()
    if skip_dev not in ["y", "yes"]:
        selected_dev_deps = list(dev_deps.keys())

    return selected_deps, selected_dev_deps


def create_pyproject_toml(config: PackageConfig, project_path: Path) -> None:
    """Create comprehensive pyproject.toml file."""
    deps_str = ""
    if config.dependencies:
        deps_list = ",\n    ".join(f'"{dep}"' for dep in config.dependencies)
        deps_str = f"[\n    {deps_list},\n]"
    else:
        deps_str = "[]"

    dev_deps_str = ""
    if config.dev_dependencies:
        dev_deps_list = ",\n    ".join(f'"{dep}"' for dep in config.dev_dependencies)
        dev_deps_str = f"[\n    {dev_deps_list},\n]"
    else:
        dev_deps_str = "[]"

    # Entry points section
    entry_points = ""
    if config.include_cli:
        entry_points = f'''

[project.scripts]
{config.cli_name} = "{config.name}.cli:main"'''

    pyproject_content = f'''[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "{config.name}"
version = "{config.version}"
description = "{config.description}"
readme = "README.md"
license = {{ text = "{config.license}" }}
requires-python = "{config.python_version}"
authors = [
    {{ name = "{config.author}", email = "{config.email}" }},
]
keywords = ["python", "package"]
classifiers = [
    "Development Status :: 3 - Alpha",
    "Intended Audience :: Developers",
    "License :: OSI Approved :: MIT License",
    "Programming Language :: Python :: 3",
    "Programming Language :: Python :: 3.8",
    "Programming Language :: Python :: 3.9",
    "Programming Language :: Python :: 3.10",
    "Programming Language :: Python :: 3.11",
    "Programming Language :: Python :: 3.12",
]
dependencies = {deps_str}{entry_points}

[project.urls]
Homepage = "https://github.com/{config.author}/{config.name}"
Documentation = "https://github.com/{config.author}/{config.name}#readme"
Repository = "https://github.com/{config.author}/{config.name}.git"
Issues = "https://github.com/{config.author}/{config.name}/issues"

[project.optional-dependencies]
dev = {dev_deps_str}

[tool.hatch.build.targets.wheel]
packages = ["src/{config.name}"]

[tool.hatch.build.targets.sdist]
include = [
    "/src",
    "/tests",
    "/README.md",
    "/LICENSE",
]

# Testing configuration
[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
addopts = [
    "--strict-markers",
    "--strict-config",
    "--cov={config.name}",
    "--cov-report=term-missing",
    "--cov-report=html",
    "--cov-report=xml",
]

# Linting and formatting
[tool.ruff]
target-version = "py38"
line-length = 88
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # pyflakes
    "I",   # isort
    "B",   # flake8-bugbear
    "C4",  # flake8-comprehensions
    "UP",  # pyupgrade
]
ignore = [
    "E501",  # line too long, handled by black
    "B008",  # do not perform function calls in argument defaults
    "C901",  # too complex
]

[tool.ruff.per-file-ignores]
"__init__.py" = ["F401"]
"tests/**/*" = ["B011"]

[tool.black]
line-length = 88
target-version = ["py38", "py39", "py310", "py311", "py312"]
include = '\\.pyi?$'

# Type checking
[tool.mypy]
python_version = "3.8"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_incomplete_defs = true
check_untyped_defs = true
disallow_untyped_decorators = true
no_implicit_optional = true
warn_redundant_casts = true
warn_unused_ignores = true
warn_no_return = true
warn_unreachable = true
strict_equality = true

[[tool.mypy.overrides]]
module = "tests.*"
disallow_untyped_defs = false
'''

    pyproject_path = project_path / "pyproject.toml"
    pyproject_path.write_text(pyproject_content, encoding="utf-8")
    print("✅ Created pyproject.toml")


def create_package_structure(config: PackageConfig, project_path: Path) -> None:
    """Create the src/ layout package structure."""
    # Create src directory structure
    src_dir = project_path / "src" / config.name
    src_dir.mkdir(parents=True, exist_ok=True)

    # Create __init__.py with package metadata
    init_content = f'''"""
{config.description}
"""

__version__ = "{config.version}"
__author__ = "{config.author}"
__email__ = "{config.email}"

# Public API
from .core import main_function

__all__ = ["main_function", "__version__"]
'''

    (src_dir / "__init__.py").write_text(init_content, encoding="utf-8")

    # Create core module
    core_content = f'''"""
Core functionality for {config.name}.
"""

from typing import Any


def main_function() -> str:
    """
    Main entry point for the package.
    
    Returns:
        str: A greeting message
    """
    return "Hello from {config.name}!"


def example_function(value: Any) -> Any:
    """
    Example function with type hints.
    
    Args:
        value: Input value of any type
        
    Returns:
        The same value (identity function)
    """
    return value
'''

    (src_dir / "core.py").write_text(core_content, encoding="utf-8")

    # Create CLI module if requested
    if config.include_cli:
        cli_content = f'''"""
Command-line interface for {config.name}.
"""

import click
from .core import main_function


@click.command()
@click.option("--verbose", "-v", is_flag=True, help="Enable verbose output")
def main(verbose: bool) -> None:
    """
    {config.description}
    """
    if verbose:
        click.echo(f"Running {config.name} in verbose mode...")
    
    result = main_function()
    click.echo(result)


if __name__ == "__main__":
    main()
'''
        (src_dir / "cli.py").write_text(cli_content, encoding="utf-8")

    print("✅ Created package structure")


def create_tests(config: PackageConfig, project_path: Path) -> None:
    """Create test structure and example tests."""
    tests_dir = project_path / "tests"
    tests_dir.mkdir(exist_ok=True)

    # Create __init__.py
    (tests_dir / "__init__.py").write_text("", encoding="utf-8")

    # Create test for core module
    test_core_content = f'''"""
Tests for {config.name}.core module.
"""

import pytest
from {config.name}.core import main_function, example_function


def test_main_function():
    """Test the main function."""
    result = main_function()
    assert isinstance(result, str)
    assert "{config.name}" in result


def test_example_function():
    """Test the example function."""
    # Test with different types
    assert example_function(42) == 42
    assert example_function("hello") == "hello"
    assert example_function([1, 2, 3]) == [1, 2, 3]


def test_example_function_with_none():
    """Test example function with None."""
    assert example_function(None) is None


@pytest.mark.parametrize("input_value,expected", [
    (1, 1),
    ("test", "test"),
    ([1, 2], [1, 2]),
    ({{"key": "value"}}, {{"key": "value"}}),
])
def test_example_function_parametrized(input_value, expected):
    """Test example function with various inputs."""
    assert example_function(input_value) == expected
'''

    (tests_dir / "test_core.py").write_text(test_core_content, encoding="utf-8")

    # Create CLI tests if CLI is included
    if config.include_cli:
        test_cli_content = f'''"""
Tests for {config.name}.cli module.
"""

from click.testing import CliRunner
from {config.name}.cli import main


def test_cli_basic():
    """Test basic CLI functionality."""
    runner = CliRunner()
    result = runner.invoke(main)
    assert result.exit_code == 0
    assert "{config.name}" in result.output


def test_cli_verbose():
    """Test CLI with verbose flag."""
    runner = CliRunner()
    result = runner.invoke(main, ["--verbose"])
    assert result.exit_code == 0
    assert "verbose mode" in result.output
'''
        (tests_dir / "test_cli.py").write_text(test_cli_content, encoding="utf-8")

    # Create conftest.py for pytest configuration
    conftest_content = '''"""
Pytest configuration and fixtures.
"""

import pytest


@pytest.fixture
def sample_data():
    """Provide sample data for tests."""
    return {
        "string": "test string",
        "number": 42,
        "list": [1, 2, 3],
        "dict": {"key": "value"},
    }
'''

    (tests_dir / "conftest.py").write_text(conftest_content, encoding="utf-8")
    print("✅ Created test structure")


def create_additional_files(config: PackageConfig, project_path: Path) -> None:
    """Create additional configuration and documentation files."""

    # Create comprehensive README.md
    readme_content = f"""# {config.name}

{config.description}

## Installation

Install from PyPI:

```bash
pip install {config.name}
```

Or install from source:

```bash
git clone https://github.com/{config.author}/{config.name}.git
cd {config.name}
pip install -e .
```

## Usage

### As a Python package

```python
from {config.name} import main_function

result = main_function()
print(result)
```

"""

    if config.include_cli:
        readme_content += f"""### As a command-line tool

```bash
{config.cli_name} --help
{config.cli_name} --verbose
```

"""

    readme_content += f"""## Development

### Setup development environment

```bash
git clone https://github.com/{config.author}/{config.name}.git
cd {config.name}

# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # On Windows: .venv\\Scripts\\activate

# Install in development mode with dev dependencies
pip install -e ".[dev]"

# Or using uv (recommended)
uv sync --dev
```

### Running tests

```bash
pytest
```

### Code formatting and linting

```bash
black src tests
ruff check src tests
mypy src
```

### Using pre-commit hooks

```bash
pre-commit install
pre-commit run --all-files
```

## License

This project is licensed under the {config.license} License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
"""

    (project_path / "README.md").write_text(readme_content, encoding="utf-8")

    # Create LICENSE file
    if config.license == "MIT":
        license_content = f"""MIT License

Copyright (c) 2024 {config.author}

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""
        (project_path / "LICENSE").write_text(license_content, encoding="utf-8")

    # Create .pre-commit-config.yaml
    precommit_content = """repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict

  - repo: https://github.com/psf/black
    rev: 23.12.1
    hooks:
      - id: black
        language_version: python3

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.8
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.8.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
"""

    (project_path / ".pre-commit-config.yaml").write_text(
        precommit_content, encoding="utf-8"
    )

    # Create .gitignore
    (project_path / ".gitignore").write_text(
        PY_GITIGNORE.strip() + "\n", encoding="utf-8"
    )

    print("✅ Created additional files")


def main() -> None:
    """Main function to create a Python package."""
    try:
        # Get package configuration
        config = get_user_input()

        # Select dependencies
        print("\n" + "=" * 50)
        config.dependencies, config.dev_dependencies = select_dependencies()

        # Create project directory
        project_path = Path(config.name)
        if project_path.exists():
            overwrite = (
                input(
                    f"\n⚠️ Directory '{config.name}' already exists. Overwrite? (y/N): "
                )
                .strip()
                .lower()
            )
            if overwrite not in ["y", "yes"]:
                print("❌ Cancelled.")
                return

        project_path.mkdir(exist_ok=True)

        print(f"\n🚀 Creating package '{config.name}'...")
        print("=" * 50)

        # Create all components
        create_pyproject_toml(config, project_path)
        create_package_structure(config, project_path)
        create_tests(config, project_path)
        create_additional_files(config, project_path)

        # Initialize git repository
        print("\n🔧 Setting up development environment...")
        run_cmd(["git", "init"], cwd=project_path)
        run_cmd(["git", "add", "."], cwd=project_path)
        run_cmd(["git", "commit", "-m", "Initial commit"], cwd=project_path)

        # Install package in development mode using uv
        try:
            run_cmd(["uv", "sync", "--dev"], cwd=project_path)
            print("✅ Installed package with uv")
        except Exception:
            print("⚠️ uv not available, install manually with: pip install -e .[dev]")

        print(f"\n🎉 Package '{config.name}' created successfully!")
        print(f"📁 Location: {project_path.absolute()}")

        print("\n📋 Next steps:")
        print(f"   cd {config.name}")
        print("   source .venv/bin/activate  # or .venv\\Scripts\\activate on Windows")
        if config.include_cli:
            print(f"   {config.cli_name} --help")
        print("   pytest")
        print("   git remote add origin <your-repo-url>")

    except KeyboardInterrupt:
        print("\n❌ Cancelled by user.")
    except Exception as e:
        print(f"\n❌ Error: {e}")


if __name__ == "__main__":
    main()
