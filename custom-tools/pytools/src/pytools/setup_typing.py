import json
import os
from typing import Optional
import typer

app = typer.Typer()


@app.command()
def setup_typing(
    python_version: str = "3.11",
    type_checking_mode: str = "basic",
    project_root: Optional[str] = None,
) -> None:
    if project_root is None:
        project_root = os.getcwd()

    vscode_dir = os.path.join(project_root, ".vscode")
    os.makedirs(vscode_dir, exist_ok=True)

    settings_path = os.path.join(vscode_dir, "settings.json")
    settings = load_or_create_json(settings_path)

    settings["python.analysis.typeCheckingMode"] = type_checking_mode
    settings["python.analysis.autoImportCompletions"] = True
    settings["python.analysis.diagnosticSeverityOverrides"] = {
        "reportUnusedImport": "none"
    }
    settings["ruff.lint.run"] = "onSave"
    settings["ruff.lint.args"] = ["--config=pyproject.toml"]
    settings["python.analysis.indexing"] = False
    settings["python.analysis.completeFunctionParens"] = False
    settings["python.analysis.inMemoryPackageIndex"] = False
    settings["python.analysis.diagnosticSeverityOverrides"].update(
        {"reportMissingTypeStubs": "none", "reportUnknownVariableType": "none"}
    )

    with open(settings_path, "w") as file:
        json.dump(settings, file, indent=4)

    pyproject_path = os.path.join(project_root, "pyproject.toml")
    pyproject_content = load_or_create_toml(pyproject_path)

    mypy_section = "[tool.mypy]\n"
    mypy_section += f'python_version = "{python_version}"\n'
    mypy_section += "warn_return_any = true\n"
    mypy_section += "warn_unused_configs = true\n"
    mypy_section += "disallow_untyped_defs = true\n"
    mypy_section += 'exclude = ["venv", "tests"]\n'
    mypy_section += "namespace_packages = true\n"
    mypy_section += "explicit_package_bases = true\n"

    ruff_section = "[tool.ruff]\n"
    ruff_section += 'select = ["E", "F", "ANN"]\n'
    ruff_section += 'ignore = ["ANN101", "ANN102"]\n'
    ruff_section += "line-length = 88\n"
    ruff_section += f'target-version = "py{python_version.replace(".", "")}"\n'

    updated_content = update_or_append_section(
        pyproject_content, "[tool.mypy]", mypy_section
    )
    updated_content = update_or_append_section(
        updated_content, "[tool.ruff]", ruff_section
    )

    with open(pyproject_path, "w") as file:
        file.write(updated_content)


def load_or_create_json(path: str) -> dict:
    if os.path.exists(path):
        with open(path, "r") as file:
            return json.load(file)
    return {}


def load_or_create_toml(path: str) -> str:
    if os.path.exists(path):
        with open(path, "r") as file:
            return file.read()
    return ""


def update_or_append_section(
    content: str, section_header: str, new_section: str
) -> str:
    if section_header in content:
        lines = content.splitlines()
        start_index = next(
            i for i, line in enumerate(lines) if line.strip() == section_header
        )
        end_index = start_index + 1
        while (
            end_index < len(lines)
            and lines[end_index].strip()
            and not lines[end_index].startswith("[")
        ):
            end_index += 1
        updated_lines = (
            lines[:start_index] + new_section.splitlines() + lines[end_index:]
        )
        return "\n".join(updated_lines) + "\n"
    else:
        return content.rstrip() + "\n\n" + new_section


if __name__ == "__main__":
    app()
