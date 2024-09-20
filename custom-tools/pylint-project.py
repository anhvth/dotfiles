#!/Users/anhvth/miniconda3/envs/py312/bin/python
import os
import subprocess
from speedy import multi_thread

# Report file name
REPORT_FILE = ".cache/report.md"

# Clear the report file if it exists
if os.path.exists(REPORT_FILE):
    os.remove(REPORT_FILE)

# Function to run pylint on a single file
def run_pylint(file_path: str) -> str:
    try:
        # Run pylint with --errors-only
        result = subprocess.run(
            ["pylint", "--errors-only", file_path],
            capture_output=True,
            text=True,
            check=False  # Allow pylint to fail without raising an exception
        )
        # Format the output
        output = f"Running pylint on {file_path}\n{result.stdout or result.stderr}\n"
    except (subprocess.CalledProcessError, OSError) as e:
        output = f"Error running pylint on {file_path}: {str(e)}\n"
    return output

# Find all Python files in the current directory and subdirectories
python_files = [os.path.join(root, file)
                for root, _, files in os.walk(".")
                for file in files if file.endswith(".py")]

# Run pylint in parallel using a thread pool
reports = multi_thread(run_pylint, python_files, workers=32)

# Write all reports to the report file at once
with open(REPORT_FILE, "w", encoding="utf-8") as report:
    report.writelines(reports)

print(f"Error report generated in {REPORT_FILE}")
