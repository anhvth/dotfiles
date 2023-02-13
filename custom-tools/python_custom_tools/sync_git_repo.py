import os

import os
import subprocess

def is_folder_changed(folder):
    result = subprocess.run(['fswatch', '-r', folder, '-1'], capture_output=True, text=True)
    if result.returncode == 0:
        return True
    else:
        return False

def main():
    import time
    from loguru import logger
    t_start = time.time()
    import os
    import os.path as osp
    import argparse, tabulate, sys

    parser = argparse.ArgumentParser()
    parser.add_argument('remote_dir', type=str,)
    parser.add_argument('local_dir', type=str)
    parser.add_argument('--mode', type=str, choices=['pull', 'push', 'git'], default='push')
    parser.add_argument('--delete', action='store_true', default=False)
    parser.add_argument('--loop', action='store_true', default=False)
    parser.add_argument('--exclude', type=str, nargs='+', default=[], help="['.git', '.idea', '.vscode']")

    is_interactive = not hasattr(sys.modules['__main__'], '__file__')
    args = parser.parse_args()

    remote_server_name, remote_dir = args.remote_dir.split(':')
    local_dir = args.local_dir

    remote_dir = osp.normpath(osp.abspath(remote_dir))
    local_dir = osp.normpath(osp.abspath(local_dir))
    if args.mode == 'pull':
        # print(remote_server_name, remote_dir, local_dir)
        os.makedirs(local_dir+'/.git', exist_ok=True)
        pull_command = f'rsync -avP {remote_server_name}:{remote_dir}/.git/ {local_dir}/.git/'
        logger.info("This command is intended to use at setup time, when there is no git repository on the local server, \n {}", pull_command)
        
    elif args.mode == 'push':

        exclude = ''
        for ex in args.exclude:
            exclude += f' --exclude={ex}'

        if args.delete:
            cmd = f"git ls-files > /tmp/gitls && rsync -avP --delay-updates  --include-from /tmp/gitls --filter=':- .gitignore' {exclude}  {local_dir}/ {remote_server_name}:{remote_dir}/"
            cmd += ' --delete'
            logger.warning('Push code to remote server with deleted commands, ')
            os.system(cmd+' --dry-run | grep delet')
            if input("Enter y to delete: ") == 'y':
                os.system(cmd)

        else:
            cmd = f"cd {local_dir} && git ls-files > /tmp/gitls && rsync -avP --delay-updates  --include-from /tmp/gitls --filter=':- .gitignore' {exclude}  {local_dir}/ {remote_server_name}:{remote_dir}/"
            if args.loop:
                while True:
                    if is_folder_changed(local_dir):
                        logger.info('File changed, push code to remote server, this action may create trash on remote server, use git status to track new files')
                        os.system(cmd)
            else:
                os.system(cmd)
                runtime = time.time() - t_start

                logger.info(f'[{runtime:0.2f} s] Push code to remote server {remote_server_name}\n'
                f'{cmd=}'
                # f'Local dir: {local_dir}\n'
                # f'Remote server: {remote_dir}\n'
                )

    elif args.mode == 'git':
        cmd = f'rsync -avP {local_dir}/.git/ {remote_server_name}:{remote_dir}/.git/'
        print(cmd)
