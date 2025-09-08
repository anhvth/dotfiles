#!/usr/bin/env fish

function cuda-ls
    nvidia-smi --query-gpu=index,gpu_name,memory.free --format=csv,noheader | sort -t ',' -k3 -n -r
end