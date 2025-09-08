#!/usr/bin/env fish

function cu
    set -gx CUDA_VISIBLE_DEVICES $argv[1]
end