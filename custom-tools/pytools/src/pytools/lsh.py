#!/usr/bin/env python3
"""List Shell (lsh) - Run command lists in parallel inside tmux.

This utility reads a text file containing shell commands (one per line) and
opens a tmux window per worker. Each window runs a queue of commands while
pinning them to specific CPU cores and GPUs. It is tailored for ML workflows
where you want reproducible GPU assignment without hand-managing tmux panes.
"""

import argparse
import os
import shutil
from pathlib import Path
from typing import Literal


def main() -> Literal[1] | Literal[0]:
    """Entry point for the lsh CLI."""
    parser = argparse.ArgumentParser(
        description=(
            "Run commands from a file in parallel using tmux. Each worker gets "
            "its own tmux window plus dedicated CPU cores and GPU assignment."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  lsh commands.txt 4 --name research --gpus 0,1,2,3\n"
            "  lsh runs.txt 2 --dry-run  # show the tmux commands without running"
        ),
    )
    parser.add_argument(
        "commands_file",
        metavar="COMMANDS_FILE",
        type=Path,
        help="Text file with one shell command per line",
    )
    parser.add_argument(
        "workers",
        metavar="WORKERS",
        type=int,
        help="Number of parallel workers (each worker becomes a tmux window)",
    )
    parser.add_argument(
        "--name",
        "--session-name",
        dest="session_name",
        default="run_list_commands",
        help="Name of the tmux session that will be created",
    )
    parser.add_argument(
        '--gpus',
        default=os.environ.get('CUDA_VISIBLE_DEVICES', '0,1,2,3,4,5,6,7'),
        help='Comma-separated list of GPU IDs to cycle through per worker',
    )
    parser.add_argument(
        "--cpu-per-worker",
        type=int,
        default=None,
        help=(
            "Limit each worker to this many CPU cores (defaults to sharing all cores evenly)"
        ),
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Print the tmux commands that would run without launching tmux',
    )

    args = parser.parse_args()

    if args.workers < 1:
        print("Error: WORKERS must be at least 1")
        return 1

    if shutil.which("tmux") is None:
        print("Error: tmux is required but was not found in PATH")
        return 1

    try:
        raw_commands = args.commands_file.read_text().splitlines()
    except FileNotFoundError:
        print(f"Error: command file '{args.commands_file}' not found")
        return 1

    commands = [line.strip() for line in raw_commands if line.strip()]
    if not commands:
        print(f"Error: command file '{args.commands_file}' is empty")
        return 1

    try:
        args.gpus = [int(x) for x in args.gpus.split(',') if x.strip()]
    except ValueError:
        print("Error: --gpus must be a comma-separated list of integer GPU IDs")
        return 1

    if not args.gpus:
        print("Error: --gpus did not include any GPU IDs")
        return 1

    cpu_count = max(1, os.cpu_count() or 1)
    if args.cpu_per_worker:
        cpu_per_worker = max(1, args.cpu_per_worker)
    else:
        cpu_per_worker = max(1, cpu_count // args.workers)

    worker_cpu_ranges = {}
    cpu_cursor = 0
    for worker_id in range(args.workers):
        start = cpu_cursor
        end = min(cpu_count - 1, start + cpu_per_worker - 1)
        worker_cpu_ranges[worker_id] = (start, end)
        cpu_cursor = end + 1
        if cpu_cursor >= cpu_count:
            cpu_cursor = 0

    worker_commands = {i: [] for i in range(args.workers)}

    for process_id, cmd in enumerate(commands):
        worker_id = process_id % args.workers
        cpu_start, cpu_end = worker_cpu_ranges[worker_id]

        gpu = args.gpus[worker_id % len(args.gpus)]
        full_cmd = (
            f'CUDA_VISIBLE_DEVICES={gpu} '
            f'taskset --cpu-list {cpu_start}-{cpu_end} '
            f'{cmd}'
        )
        worker_commands[worker_id].append(full_cmd)

    total = sum(len(cmds) for cmds in worker_commands.values())
    print(
        f"Preparing {total} commands across {args.workers} worker(s). "
        f"CPUs: {cpu_count} available, {cpu_per_worker} per worker. "
        f"GPUs: {args.gpus}"
    )
    if args.dry_run:
        print("Dry run enabled; tmux sessions will not be created.")

    for worker_id, worker_cmds in worker_commands.items():
        if not worker_cmds:
            continue

        cmd_file = Path(f"/tmp/lsh_{args.session_name}_{worker_id}.sh")
        with open(cmd_file, 'w') as f:
            f.write('\n'.join(worker_cmds))

        tmux_cmd: str
        if worker_id == 0:
            tmux_cmd = f"tmux new -s {args.session_name} -d 'sh {cmd_file}'"
        else:
            tmux_cmd = (
                f"tmux new-window -t {args.session_name} "
                f"-n 'worker-{worker_id}' 'sh {cmd_file}'"
            )

        print('Running:', tmux_cmd)
        if not args.dry_run:
            os.system(tmux_cmd)

    return 0


if __name__ == "__main__":
    exit(main())
