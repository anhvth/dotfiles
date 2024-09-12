#!/Users/anhvth/miniconda3/bin/python
import os
import time
import subprocess
import sys

from loguru import logger


def check_port(port):
    """Check if the local port is used by any process."""
    result = subprocess.run(["lsof", "-i", f":{port}"], capture_output=True, text=True)
    return result.stdout


def kill_process_using_port(port):
    """Kill the process using a specific port."""
    port_usage_info = check_port(port)
    if port_usage_info:
        # Extract the process ID from the lsof output
        lines = port_usage_info.strip().split("\n")
        if len(lines) > 1:
            pid = int(lines[1].split()[1])
            subprocess.run(["kill", "-9", str(pid)])
            return pid
    return None


def assert_port_free(port):
    """Assert that the port is now free."""
    port_usage_info = check_port(port)
    assert not port_usage_info, f"Port {port} is still in use."


import os


def get_local_port_numbers(hostname, config_file=os.path.expanduser("~/.ssh/config")):
    with open(config_file, "r") as file:
        lines = file.readlines()

    host_found = False
    local_port_numbers = []

    for line in lines:
        line = line.strip()
        if line.startswith("Host ") and line.split()[1] == hostname:
            host_found = True
        elif host_found:
            if line.startswith("Host "):
                # Stop if another host entry is found
                break
            if line.startswith("LocalForward "):
                # Extract port number
                parts = line.split()
                if len(parts) > 2:
                    try:
                        local_port = int(parts[1])
                        local_port_numbers.append(local_port)
                    except ValueError:
                        continue

    return local_port_numbers


def generate_autossh_command(remote_machine):
    """Generate autossh command for port forwarding."""
    ports = get_local_port_numbers(remote_machine)
    ports_str = ""
    for port in ports:
        ports_str += f" -L {port}:localhost:{port}"
        # Kill any process using the local port
        pid = kill_process_using_port(port)
        if pid:
            logger.warning(f"Killed process {pid} using port {port}")
            assert_port_free(port)
            logger.info(f"Port {port} is now free.")
            time.sleep(0.1)

    return f"autossh -M 0 -f -N {remote_machine}"


def assert_port_mapping_working(local_port):
    """Assert that the port mapping is working by checking if the port is in use."""
    port_usage_info = check_port(local_port)
    assert port_usage_info, f"Port mapping to local port {local_port} is not working."


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="Port forwarding script using autossh."
    )
    parser.add_argument(
        "remote_machine", type=str, help="Remote machine to connect to."
    )
    args = parser.parse_args()
    remote_machine = args.remote_machine

    print(f"Generating autossh command...")
    autossh_cmd = generate_autossh_command(remote_machine)
    print(f"autossh command: {autossh_cmd}")

    print(f"Writing the autossh command to /tmp/keep-connect.sh...")
    with open("/tmp/keep-connect.sh", "w") as f:
        f.write(f"#!/bin/bash\n\n{autossh_cmd}\n")
    os.chmod("/tmp/keep-connect.sh", 0o755)
    print(f"Generated autossh command and saved to /tmp/keep-connect.sh.")
    print(f"Executing the /tmp/keep-connect.sh script to establish the connection...")
    subprocess.run(["/tmp/keep-connect.sh"])
    logger.info(f"Checking if the ports are mapped correctly...\n\n---\n\n")


if __name__ == "__main__":
    main()
