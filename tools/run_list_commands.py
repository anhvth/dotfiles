
from glob import glob
import argparse, os
parser = argparse.ArgumentParser()

parser.add_argument('listcmd')
parser.add_argument('totalgpu')
parser.add_argument('--dry-run', default=False, action='store_true')

args = parser.parse_args()

# inputs="/data/DMS_Behavior_Detection/RawVideos/Action_Eating/*/*.mp4"
cmds = []
for cmd in open(args.listcmd):
    cmds.append(cmd[:-1])

wi = 0
ngpu = min(int(args.totalgpu), len(cmds))
num_jobs_per_window = len(cmds)//ngpu
for i in range(0, len(cmds), max(num_jobs_per_window, 1)):
    
    _cmds = cmds[i:i+num_jobs_per_window]
    _cmds = "\n".join(_cmds)
    # import ipdb; ipdb.set_trace()
    
    tmpsh = f'/tmp/script-{wi}.sh'
    with open(tmpsh, 'w') as f:
        f.write(_cmds)
    gpu = wi%8
    if i == 0:
        target_tmux = "run-0"
        tmuxcmd = f"tmux new -s '{target_tmux}' -d 'CUDA_VISIBLE_DEVICES={gpu} sh {tmpsh} || echo Done && sleep 10cat'"
    else:
        tmuxcmd = f"tmux new-window -n w{wi} -t {target_tmux}: 'CUDA_VISIBLE_DEVICES={gpu} sh {tmpsh} || echo Done && sleep 10'"
    wi += 1
    print(tmuxcmd)
    if not args.dry_run:
        os.system(tmuxcmd)
