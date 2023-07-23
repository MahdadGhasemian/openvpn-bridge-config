#!/bin/bash

## Write service file
cat <<EOF > /etc/systemd/system/tunnel-to-upstream.service
[Unit]
Description=tunneling to upstream server
Documentation=https://mahdad.me
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/bin/bash ssh -p$1 -f -N -L *:$2:localhost:$3 root@$4

[Install]
WantedBy=multi-user.target

EOF


systemctl daemon-reload
systemctl enable tunnel-to-upstream.service
systemctl start tunnel-to-upstream.service
systemctl status tunnel-to-upstream.service