import re
import os
import fire

def parse_to_config(ssh_cmd, host_name='vastai'):
    """Parse ssh command to SSH Config"""
    pattern = re.compile(r'ssh -p (\d+) ([^@]+)@([^\s]+) -L (\d+):([^:]+):(\d+)')
    match = pattern.match(ssh_cmd)
    
    if match:
        port, user, hostname, local_port, local_hostname, local_hostport = match.groups()
        
        config = f"""Host {host_name}
User {user}
Hostname {hostname}
Port {port}
LocalForward {local_port} {local_hostname}:{local_hostport}
"""
        return config
    else:
        raise ValueError("Invalid SSH command")
    return config

import pyperclip

def main(ssh_cmd, host_name='vastai'):
    s = parse_to_config(ssh_cmd, host_name)
    print(s)
    pyperclip.copy(s)
    os.system("vi ~/.ssh/config")


if __name__ == '__main__':
    fire.Fire(main)

