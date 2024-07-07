#!/usr/bin/env python3
import argparse
import itertools
import multiprocessing
import os
import shlex
import shutil
import subprocess

def run_in_tmux(commands_to_run, tmux_name, num_windows):
    with open("/tmp/start_multirun_tmux.sh", "w") as script_file:
        script_file.write("#!/bin/bash\n\n")
        script_file.write(f"tmux kill-session -t {tmux_name}\nsleep .1\n")
        script_file.write(f"tmux new-session -d -s {tmux_name}\n")
        for i, cmd in enumerate(itertools.cycle(commands_to_run)):
            if i >= num_windows:
                break
            window_name = f"{tmux_name}:{i}"
            if i == 0:
                script_file.write(f"tmux send-keys -t {window_name} '{cmd}' C-m\n")
            else:
                script_file.write(f"tmux new-window -t {tmux_name}\n")
                script_file.write(f"tmux send-keys -t {window_name} '{cmd}' C-m\n")

        script_file.write("chmod +x /tmp/start_multirun_tmux.sh\n")
        print("Run /tmp/start_multirun_tmux.sh")

def main():
    parser = argparse.ArgumentParser(description="Run commands from a file in tmux sessions")
    parser.add_argument("file_path", help="Path to the file containing commands")
    parser.add_argument("--gpus", type=str, default="0,1,2,3,4,5,6,7")
    parser.add_argument("--ignore_gpus", "-ig", type=str, default="")
    parser.add_argument(
        "--total_cpu",
        type=int,
        default=multiprocessing.cpu_count(),
        help="total number of cpu cores available",
    )

    args = parser.parse_args()

    # Read commands from the file
    with open(args.file_path, 'r') as file:
        commands = [line.strip() for line in file if line.strip()]

    gpus = args.gpus.split(",")
    gpus = [gpu for gpu in gpus if gpu not in args.ignore_gpus.split(",")]
    num_gpus = len(gpus)

    cpu_per_process = max(args.total_cpu // len(commands), 1)
    taskset_path = shutil.which("taskset")

    modified_commands = []
    for i, cmd in enumerate(commands):
        gpu = gpus[i % num_gpus]
        cpu_start = (i * cpu_per_process) % args.total_cpu
        cpu_end = ((i + 1) * cpu_per_process - 1) % args.total_cpu

        if taskset_path:
            modified_cmd = f"CUDA_VISIBLE_DEVICES={gpu} {taskset_path} -c {cpu_start}-{cpu_end} {cmd}"
        else:
            modified_cmd = f"CUDA_VISIBLE_DEVICES={gpu} {cmd}"

        modified_commands.append(modified_cmd)

    run_in_tmux(modified_commands, "run_list_cmd", len(modified_commands))

if __name__ == "__main__":
    main()
