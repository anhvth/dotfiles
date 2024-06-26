Here is a documented version of the alias.sh file:

**Table of Contents**
======================

1. [General Aliases](#general-aliases)
2. [Docker Aliases](#docker-aliases)
3. [Jupyter and IPython Aliases](#jupyter-and-ipython-aliases)
4. [GPU-related Aliases](#gpu-related-aliases)
5. [File Management Aliases](#file-management-aliases)
6. [SSH and Remote Access Aliases](#ssh-and-remote-access-aliases)
7. [Productivity Aliases](#productivity-aliases)
8. [Miscellaneous Aliases](#miscellaneous-aliases)

**General Aliases**
-----------------

### vi

Alias for `nvim`

### fzc

Alias for `fzf | xargs -r code`, opens files in VS Code using fzf

### cd

Alias for `cd`, standard change directory command

### dki

Alias for `docker images`, lists Docker images

### gg

Alias for `git status`, displays Git repository status

### tb

Alias for `tensorboard --logdir`, starts TensorBoard with specified log directory

### ta

Alias for `tmux a -t`, attaches to a tmux session

### tk

Alias for `tmux kill-session -t`, kills a tmux session

### i

Alias for `ipython`, starts IPython shell

### iav

Alias for `ipython --profile av`, starts IPython shell with specified profile

### checksize

Alias for `du -h ./ | sort -rh`, checks directory sizes and sorts them in human-readable format

**Docker Aliases**
-----------------

### dk

Alias for `docker kill`, kills a Docker container

### docker-run

Alias for `docker run` with additional options, starts a new Docker container

### docker-attatch

Alias for `docker attach`, attaches to a running Docker container

### docker-commit

Alias for `docker commit`, commits changes to a Docker container

### docker-kill

Alias for `docker kill $(docker ps -qa)`, kills all running Docker containers

**Jupyter and IPython Aliases**
-----------------------------

### ju

Alias for `jupyter lab --allow-root --ip 0.0.0.0 --port`, starts Jupyter Lab server

### nb-clean

Alias for `jupyter nbconvert --ClearOutputPreprocessor.enabled=True --inplace`, clears Jupyter notebook output

**GPU-related Aliases**
-------------------------

### gpus

Alias for `watch -n0.1 nvidia-smi`, monitors GPU usage

### nvidia-smi-watch

Alias for `watch -n0.1 nvidia-smi`, monitors GPU usage

**File Management Aliases**
---------------------------

### absp

Alias for generating an absolute path using `fzf`

### c

Alias for `cd` with `ls`, changes directory and lists contents

### p

Alias for running Python with specified CUDA device

### j

Alias for running Jupyter Lab with specified CUDA device

**SSH and Remote Access Aliases**
-------------------------------

### rs-git

Alias for `rsync` with Git filter, synchronizes files with Git repository

### rs-git-sync

Alias for `rsync` with Git filter and watch, synchronizes files with Git repository continuously

### get_remote_file

Alias for downloading files from remote server using `scp`

**Productivity Aliases**
-------------------------

### atv

Alias for activating a conda environment

### tm

Alias for `tmux`, starts a tmux session

### fh

Alias for `fc -l 1`, displays command history

### tssh

Alias for `ssh` with automatic reconnect, reconnects to SSH server after disconnection

### fif

Alias for searching files with `fzf` and printing the result

### fiv

Alias for opening a file with `vim` using `fif`

### fic

Alias for opening a file with `code` using `fif`

**Miscellaneous Aliases**
-------------------------

### rs-current-dir

Alias for `rs` with current directory, synchronizes files with remote server

### kill-all-python-except-jupyter

Alias for killing all Python processes except Jupyter

### kill-all-python-jupyter

Alias for killing all Python processes including Jupyter

### use-ssh

Alias for switching SSH configurations

### rss

Alias for `rsync` with interactive host selection, synchronizes files with remote server

### rsab

Alias for `rsync` with multiple targets, synchronizes files with multiple remote servers

### wget-rs

Alias for downloading files with `wget` and synchronizing with remote server using `rsync`

### convert2mp4

Alias for converting files to MP4 format using `ffmpeg`

### ju-convert

Alias for converting Jupyter notebooks to Python files using `nbconvert`

### pyf

Alias for sorting imports and formatting Python files