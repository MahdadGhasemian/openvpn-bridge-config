## On foreign server (server 1):

* $ mkdir openvpn
* $ cd openvpn
* $ sudo curl -s https://raw.githubusercontent.com/MahdadGhasemian/openvpn-bridge-config/main/install-upstream.sh | bash -s open-vpn-port ca-passphrase upstream-server-ssh-port intranet-server-ip a-port-on-intranet-server
* $ sudo curl -s https://raw.githubusercontent.com/MahdadGhasemian/openvpn-bridge-config/main/install-upstream.sh | bash -s 7766 ca1234 2220 x.x.x.x 4444



