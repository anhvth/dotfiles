import os
import subprocess
import signal

def kill_processes_grep():
    # Get the list of running processes
    ps_output = subprocess.check_output(["ps", "-ef"]).decode("utf-8")
    
    # Use fzf for fuzzy finding
    try:
        fzf_process = subprocess.Popen(["fzf", "--multi"], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        selected_processes, _ = fzf_process.communicate(input=ps_output)
    except FileNotFoundError:
        print("Error: fzf is not installed. Please install it first.")
        return

    # Process the selected items
    for line in selected_processes.strip().split('\n'):
        if line:
            pid = line.split()[1]
            try:
                os.kill(int(pid), signal.SIGTERM)
                print(f"Killed process {pid}")
            except ProcessLookupError:
                print(f"Process {pid} not found")
            except PermissionError:
                print(f"Permission denied to kill process {pid}")

if __name__ == "__main__":
    kill_processes_grep()

