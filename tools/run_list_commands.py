
from glob import glob
import argparse, os
parser = argparse.ArgumentParser()

parser.add_argument('listcmd')
parser.add_argument('num_workers', type=int)
parser.add_argument('--name', default='run_list_commands')

parser.add_argument('--gpus', default=os.environ.get('CUDA_VISIBLE_DEVICES', '0,1,2,3,4,5,6,7'))
parser.add_argument('--dry-run', default=False, action='store_true')

args = parser.parse_args()
args.done_log = "/tmp/{args.name}.done"
args.gpus = [int(x) for x in args.gpus.split(',')]

cmds = open(args.listcmd).readlines()

list_cmds_by_process = {i:[] for i in range(args.num_workers)}
for i, cmd in enumerate(cmds):
    cmd = cmd.strip()
    gpu = args.gpus[i % len(args.gpus)]
    cmd = f'CUDA_VISIBLE_DEVICES={gpu} {cmd}'
    list_cmds_by_process[i % args.num_workers].append(cmd)

print("Summary: ", "GPUS: ", args.gpus, "Num workers: ", args.num_workers, "Num cmds: ", len(cmds))

for i, cmds in list_cmds_by_process.items():
    with open('/tmp/listcmd_{}.txt'.format(i), 'w') as f:
        for cmd in cmds:
            f.write(cmd + '\n')
    if i == 0:
        tmuxcmd = f"tmux new -s {args.name} -d 'sh /tmp/listcmd_0.txt'"
    else:
        tmuxcmd = f"tmux new-window -t {args.name} -n 'window-{i}' 'sh /tmp/listcmd_{i}.txt'"
    print('Running: ', tmuxcmd)
    if not args.dry_run:
        os.system(tmuxcmd)