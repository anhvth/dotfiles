
from glob import glob
import argparse, os


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('listcmd')
    parser.add_argument('num_workers', type=int)
    parser.add_argument('--name', default='run_list_commands')

    parser.add_argument('--gpus', default=os.environ.get('CUDA_VISIBLE_DEVICES', '0,1,2,3,4,5,6,7'))
    parser.add_argument('--dry-run', default=False, action='store_true')

    args = parser.parse_args()
    args.done_log = "/tmp/{args.name}.done"
    args.gpus = [int(x) for x in args.gpus.split(',')]
    list_commands = open(args.listcmd).readlines()

    num_cpu = os.cpu_count()
    num_cpu_per_worker = num_cpu / args.num_workers
    workerid_to_range_cpu = {i:[int(i*num_cpu_per_worker), int((i+1)*num_cpu_per_worker)] for i in range(args.num_workers)}


    dict_tmux_id_to_list_commands = {i:[] for i in range(args.num_workers)}
    for process_id, cmd in enumerate(list_commands):
        tmux_id = process_id % args.num_workers
        cpu_list = workerid_to_range_cpu[tmux_id]

        cmd = cmd.strip()
        
        gpu = args.gpus[tmux_id % len(args.gpus)]
        cmd = f'CUDA_VISIBLE_DEVICES={gpu} taskset --cpu-list {cpu_list[0]}-{cpu_list[1]} {cmd}'
        dict_tmux_id_to_list_commands[tmux_id % args.num_workers].append(cmd)

    print("Summary: ", "GPUS: ", args.gpus, "Num workers: ", args.num_workers, "Num cmds: ", len(list_commands))
    # print(f"{workerid_to_range_cpu=}")
    for tmux_id, list_commands in dict_tmux_id_to_list_commands.items():
        
        with open('/tmp/listcmd_{}.txt'.format(tmux_id), 'w') as f:
            for cmd in list_commands:
                f.write(f'{cmd}\n')
        if tmux_id == 0:
            tmuxcmd = f"tmux new -s {args.name} -d 'sh /tmp/listcmd_0.txt'"
        else:
            tmuxcmd = f"tmux new-window -t {args.name} -n 'window-{tmux_id}' 'sh /tmp/listcmd_{tmux_id}.txt'"
        print('Running: ', tmuxcmd)
        if not args.dry_run:
            os.system(tmuxcmd)
