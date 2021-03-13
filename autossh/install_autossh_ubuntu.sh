# /bin/bash
sudo touch /etc/systemd/system/autossh-mysql-tunnel.service 

mess='[Unit]
Description=AutoSSH tunnel service everythingcli MySQL on local port 5000
After=network.target

[Service]
Environment="AUTOSSH_GATETIME=0"
ExecStart=/usr/bin/autossh -M 0 -o "ServerAliveInterval 30" -o "ServerAliveCountMax 3" -NL 2223:localhost:22 cytopia@everythingcli.org -p 1022

[Install]
WantedBy=multi-user.target
'
sudo echo $mess > /etc/systemd/system/autossh-mysql-tunnel.service

sudo systemctl daemon-reload

sudo systemctl start autossh-mysql-tunnel.service

sudo systemctl enable autossh-mysql-tunnel.service

sudo systemctl status autossh-mysql-tunnel

