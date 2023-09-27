#!/bin/bash

# Start the SSH tunnel
ssh m2 -N -L 9223:localhost:9223 &

# Store the SSH process ID
SSH_PID=$!

# Run the Python script
/Users/anhvth/miniconda3/bin/python /Users/anhvth/dotfiles/tools/bin/auto-auth/auth.py

# Kill the SSH tunnel
kill $SSH_PID
