#!/usr/bin/env python3
"""
Process Kill with Grep - Interactive process killer using fzf for selection.

This tool displays running processes and allows interactive selection
for termination using fzf fuzzy finder.
"""

import os
import subprocess
import signal
import sys


def kill_processes_grep():
    """Show running processes and allow interactive selection for killing."""
    try:
        # Get the list of running processes
        ps_output = subprocess.check_output(["ps", "-ef"]).decode("utf-8")
    except subprocess.CalledProcessError as e:
        print(f"Error getting process list: {e}")
        return 1
    
    # Use fzf for fuzzy finding
    try:
        fzf_process = subprocess.Popen(
            ["fzf", "--multi", "--header=Select processes to kill (use TAB for multi-select)"], 
            stdin=subprocess.PIPE, 
            stdout=subprocess.PIPE, 
            text=True
        )
        selected_processes, _ = fzf_process.communicate(input=ps_output)
    except FileNotFoundError:
        print("Error: fzf is not installed. Please install it first.")
        return 1

    # Process the selected items
    killed_count = 0
    for line in selected_processes.strip().split('\n'):
        if line:
            try:
                pid = line.split()[1]
                pid_int = int(pid)
                
                # Don't kill PID 1 or our own process
                if pid_int == 1 or pid_int == os.getpid():
                    print(f"Skipping critical process {pid}")
                    continue
                    
                os.kill(pid_int, signal.SIGTERM)
                print(f"Killed process {pid}")
                killed_count += 1
            except (ValueError, IndexError):
                print(f"Invalid process line: {line}")
            except ProcessLookupError:
                print(f"Process {pid} not found")
            except PermissionError:
                print(f"Permission denied to kill process {pid}")
            except Exception as e:
                print(f"Error killing process {pid}: {e}")
    
    print(f"Killed {killed_count} processes")
    return 0


def main():
    """Main entry point for the kill-process-grep command."""
    return kill_processes_grep()


if __name__ == "__main__":
    exit(main())