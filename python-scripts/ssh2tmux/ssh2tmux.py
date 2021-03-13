import os
import sys
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("machine")
parser.add_argument("name")
parser.add_argument("--port", '-p', default=None)


args = parser.parse_args()

cmd=f'ssh {args.machine} '
if args.port is not None:
    cmd += f" -L {args.port}:localhost:{args.port}"

cmd += f' -t "source ~/.zshrc && tm {args.name}"'
print(cmd)
try:
    while 1:
        result=os.system(cmd)
        print("result:", result)
        if result == 0:
            break
        else:
            print("Try.")
except KeyboardInterrupt:
    print("Exit")
