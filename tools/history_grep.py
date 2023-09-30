import os
lines = open(".history").readlines()
history = set()
for line in lines:
    line = "  ".join(line.split("  ")[3:]).strip()
    history.add(line)
    
history = list(history)
history.reverse()
for i, line in enumerate(history):
    print("{}".format( line))
os.remove(".history")
