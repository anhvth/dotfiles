#!/usr/bin/env python
import argparse
import os


def main():
    """
    Executes a list of commands in parallel using tmux.

    This function takes command-line arguments and performs the following steps:
    1. Parses the command-line arguments using `argparse`.
    2. Reads the list of commands from a file specified by the `listcmd` argument.
    3. Divides the available CPU cores among the specified number of workers.
    4. Assigns a GPU to each worker based on the available GPUs and the worker's ID.
    5. Generates a list of commands for each worker, with appropriate GPU and CPU assignments.
    6. Writes the list of commands for each worker to separate files.
    7. Executes the commands using `tmux` in parallel.

    Args:
        None

    Returns:
        None
    """
    parser = argparse.ArgumentParser()
    parser.add_argument('listcmd')
    parser.add_argument('num_workers', type=int)
    parser.add_argument('--name', default='run_list_commands')
    parser.add_argument('--gpus', default=os.environ.get('CUDA_VISIBLE_DEVICES', '0,1,2,3,4,5,6,7'))
    parser.add_argument('--dry-run', action='store_true')

    args = parser.parse_args()
    args.done_log = f"/tmp/{args.name}.done"
    args.gpus = [int(x) for x in args.gpus.split(',')]
    list_commands = open(args.listcmd).readlines()

    num_cpu = os.cpu_count()
    num_cpu_per_worker = num_cpu // args.num_workers  # Use integer division for clarity
    workerid_to_range_cpu = {i: [i * num_cpu_per_worker, (i + 1) * num_cpu_per_worker - 1] for i in range(args.num_workers)}

    dict_tmux_id_to_list_commands = {i: [] for i in range(args.num_workers)}
    for process_id, cmd in enumerate(list_commands):
        tmux_id = process_id % args.num_workers
        cpu_list = workerid_to_range_cpu[tmux_id]

        cmd = cmd.strip()
        gpu = args.gpus[tmux_id % len(args.gpus)]
        cmd = f'CUDA_VISIBLE_DEVICES={gpu} taskset --cpu-list {cpu_list[0]}-{cpu_list[1]} {cmd}'
        dict_tmux_id_to_list_commands[tmux_id].append(cmd)

    print("Summary:", "GPUs:", args.gpus, "Num workers:", args.num_workers, "Num cmds:", len(list_commands))

    for tmux_id, commands in dict_tmux_id_to_list_commands.items():
        cmd_file = f'/tmp/listcmd_{tmux_id}.txt'
        with open(cmd_file, 'w') as f:
            f.write('\n'.join(commands))
        
        if tmux_id == 0:
            tmuxcmd = f"tmux new -s {args.name} -d 'sh {cmd_file}'"
        else:
            tmuxcmd = f"tmux new-window -t {args.name} -n 'window-{tmux_id}' 'sh {cmd_file}'"
        
        print('Running:', tmuxcmd)
        if not args.dry_run:
            os.system(tmuxcmd)


if __name__ == "__main__":
    main()
