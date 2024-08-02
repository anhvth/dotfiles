#!/Users/anhvth/miniconda3/bin/python
import os
import time
import subprocess
import sys
from loguru import logger

def check_port(port):
    """Check if the local port is used by any process."""
    result = subprocess.run(['lsof', '-i', f':{port}'], capture_output=True, text=True)
    return result.stdout

def kill_process_using_port(port):
    """Kill the process using a specific port."""
    port_usage_info = check_port(port)
    if port_usage_info:
        # Extract the process ID from the lsof output
        lines = port_usage_info.strip().split('\n')
        if len(lines) > 1:
            pid = int(lines[1].split()[1])
            subprocess.run(['kill', '-9', str(pid)])
            return pid
    return None

def assert_port_free(port):
    """Assert that the port is now free."""
    port_usage_info = check_port(port)
    assert not port_usage_info, f"Port {port} is still in use."

def generate_autossh_command(remote_machine, ports):
    """Generate autossh command for port forwarding."""
    ports_str = ''
    for port in ports:
        ports_str += f' -L {port}:localhost:{port}'
        # Kill any process using the local port
        pid = kill_process_using_port(port)
        if pid:
            print(f"Killed process {pid} using port {port}")
            # Assert that the port is now free
            assert_port_free(port)
            print(f"Port {port} is now free.")
            # Wait for a short period to ensure the port is fully released
            time.sleep(1)

    return f"autossh -M 0 -f -N {ports_str} {remote_machine}"

def assert_port_mapping_working(local_port):
    """Assert that the port mapping is working by checking if the port is in use."""
    port_usage_info = check_port(local_port)
    assert port_usage_info, f"Port mapping to local port {local_port} is not working."

def main():
    import argparse
    parser = argparse.ArgumentParser(description='Port forwarding script using autossh.')
    parser.add_argument('remote_machine', type=str, help='Remote machine to connect to.')
    parser.add_argument('ports', type=int, nargs='+', help='Local ports to forward.')
    # gds = sys.argv[1]
    # ports = [sys.argv[2], sys.argv[3]]
    args = parser.parse_args()
    remote_machine = args.remote_machine
    ports = args.ports

    
    print(f"Generating autossh command...")
    autossh_cmd = generate_autossh_command(remote_machine, ports)
    print(f"autossh command: {autossh_cmd}")
    
    print(f"Writing the autossh command to /tmp/keep-connect.sh...")
    with open('/tmp/keep-connect.sh', 'w') as f:
        f.write(f"#!/bin/bash\n\n{autossh_cmd}\n")
    os.chmod('/tmp/keep-connect.sh', 0o755)
    print(f"Generated autossh command and saved to /tmp/keep-connect.sh.")
    
    print(f"Executing the /tmp/keep-connect.sh script to establish the connection...")
    subprocess.run(['/tmp/keep-connect.sh'])
    # Check the status of the ports
    logger.info(f"Checking if the ports are mapped correctly...\n\n---\n\n")
    for port in ports:
        logger.info(f"Checking if port mapping to local port {port} is working...")
        assert_port_mapping_working(port)
        logger.success("Port mapping to local port {}:{} is working.".format(remote_machine, port))
if __name__ == "__main__":
    main()
