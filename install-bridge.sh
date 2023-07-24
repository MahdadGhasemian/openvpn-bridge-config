#!/bin/bash

## Write service file
cat <<EOF > /etc/systemd/system/tunnel-to-upstream.service
[Unit]
Description=Setup a secure tunnel to $4
Documentation=https://mahdad.me
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/bin/tunnel-to-upstream
ExecStart=/usr/bin/bash /bin/tunnel-to-upstream/tunnel-to-upstream.sh

RestartSec=5
Restart=always

[Install]
WantedBy=multi-user.target

EOF

mkdir -p /bin/tunnel-to-upstream

## Write script file
cat <<EOF > /bin/tunnel-to-upstream/tunnel-to-upstream.sh
#!/bin/bash

ssh -p$1 -f -N -L *:$2:localhost:$3 root@$4

EOF



systemctl daemon-reload
systemctl enable tunnel-to-upstream.service
systemctl start tunnel-to-upstream.service
systemctl status tunnel-to-upstream.service