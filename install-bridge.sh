#!/bin/bash

## Write service file
cat <<EOF > /etc/systemd/system/tunnel-to-upstream.service
[Unit]
Description=Setup a secure tunnel to $4
Documentation=https://mahdad.me
After=network.target

[Service]
User=root
Group=root
Restart=on-failure
RestartSec=5
ExecStart=/usr/bin/ssh -NTC -o ServerAliveInterval=60 -o ExitOnForwardFailure=yes -p$1 -L *:$2:localhost:$3 root@$4

[Install]
WantedBy=multi-user.target

EOF

systemctl daemon-reload
systemctl enable tunnel-to-upstream.service
systemctl start tunnel-to-upstream.service
systemctl status tunnel-to-upstream.service