import os
import subprocess
from typing import Optional

import typer

app = typer.Typer()


@app.command()
def report_errors(
    file_path: str,
    output_file: str = "pylance_errors.json",
    json_format: bool = True,
    project_root: Optional[str] = None,
    verbose: bool = False,
):
    if project_root is None:
        project_root = os.getcwd()

    pyproject_path = os.path.join(project_root, "pyproject.toml")

    cmd = ["pyright", "--project", pyproject_path, file_path]
    if json_format:
        cmd.append("--outputjson")
    if verbose:
        cmd.append("--verbose")

    result = subprocess.run(cmd, capture_output=True, text=True)

    with open(output_file, "w") as file:
        file.write(result.stdout)

    if result.stderr:
        typer.echo(result.stderr, err=True)

    typer.echo(f"Errors for {file_path} reported to {output_file}")


if __name__ == "__main__":
    app()
