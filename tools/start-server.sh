#!/usr/bin/env bash
echo "start hosting checkpoint at port 8000 nhe" && cd /checkpoints 

s="python -m http.server 8000"
tmux new -s "ckpt8000" -d $s

s="tensorboard --logdir /checkpoints/coco-person-20/ --port 8001"
tmux new -s "tensorboard8001" -d $s
