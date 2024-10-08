#!/usr/bin/env python3
import argparse
import itertools
import multiprocessing  # Import multiprocessing module
import os
import shlex  # To properly escape command line arguments

import shutil
import subprocess

# Your other variables like 'gpu', 'cpu_start', 'cpu_end', 'cmd_str', 'i', 'args.total_fold' should be defined above this
taskset_path = shutil.which("taskset")


def run_in_tmux(commands_to_run, tmux_name, num_windows):
    with open("/tmp/start_multirun_tmux.sh", "w") as script_file:
        # first cmd is to kill the session if it exists

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

        # Make the script executable
        script_file.write("chmod +x /tmp/start_multirun_tmux.sh\n")
        print("Run /tmp/start_multirun_tmux.sh")


def main():
    parser = argparse.ArgumentParser(description="Process fold arguments")
    parser.add_argument(
        "--total_fold", "-t", default=16, type=int, help="total number of folds"
    )
    parser.add_argument("--gpus", type=str, default="0,1,2,3,4,5,6,7")
    parser.add_argument("--ignore_gpus", "-ig", type=str, default="")
    parser.add_argument(
        "--total_cpu",
        type=int,
        default=multiprocessing.cpu_count(),
        help="total number of cpu cores available",
    )
    parser.add_argument(
        "cmd", nargs=argparse.REMAINDER
    )  # This will gather the remaining unparsed arguments

    args = parser.parse_args()

    if not args.cmd or (args.cmd[0] == "--" and len(args.cmd) == 1):
        parser.error("Invalid command provided")

    cmd_str = None
    if args.cmd[0] == "--":
        cmd_str = " ".join(shlex.quote(arg) for arg in args.cmd[1:])
    else:
        cmd_str = " ".join(shlex.quote(arg) for arg in args.cmd)

    gpus = args.gpus.split(",")
    gpus = [gpu for gpu in gpus if not gpu in args.ignore_gpus.split(",")]
    num_gpus = len(gpus)

    cpu_per_process = max(args.total_cpu // args.total_fold, 1)
    cmds = []
    for i in range(args.total_fold):
        gpu = gpus[i % num_gpus]
        cpu_start = (i * cpu_per_process) % args.total_cpu
        cpu_end = ((i + 1) * cpu_per_process - 1) % args.total_cpu

        if taskset_path:
            fold_cmd = f"CUDA_VISIBLE_DEVICES={gpu} {taskset_path} -c {cpu_start}-{cpu_end} python {cmd_str} --fold {i} {args.total_fold}"
        else:
            fold_cmd = f"CUDA_VISIBLE_DEVICES={gpu} python {cmd_str} --fold {i} {args.total_fold}"

        cmds.append(fold_cmd)

    run_in_tmux(cmds, "mpython", args.total_fold)


if __name__ == "__main__":
    main()
