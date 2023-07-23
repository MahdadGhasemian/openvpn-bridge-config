#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root user or run with sudo"
  exit
fi

## System IP
IP=$(curl -s "https://api.ipify.org/" )

## Check for docker
docker --version
if [ $? -ne 0 ]
  then
    curl -fsSL https://get.docker.com | sh
fi

## Check for docker compose
docker-compose --version
if [ $? -ne 0 ]
  then
    curl -L "https://github.com/docker/compose/releases/download/$(curl --silent "https://api.github.com/repos/docker/compose/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

rm -f docker-compose.yml
rm -f create_ca.exp
rm -f create_user.exp
rm -f add_user.sh
rm -f info.log
rm -rf openvpn-data
rm -rf ./*.ovpn

## Write compose file
cat <<EOF > ./docker-compose.yml
version: '2'
services:
    openvpn:
        cap_add:
            - NET_ADMIN
        image: kylemanna/openvpn
        container_name: openvpn
        ports:
            - "$1:$1/tcp"
        restart: always
        volumes:
            - ./openvpn-data/conf:/etc/openvpn

EOF

## Write create_ca file
cat <<EOF > ./create_ca.exp
#!/usr/bin/expect -f

spawn docker-compose run --rm openvpn ovpn_initpki

proc respond_with_passphrase {} {
    expect {
        -re {Enter pass phrase for .*} {
            sleep 1
            send -- "$2\r"
            exp_continue
        }
        -re {CRL file: /etc/openvpn/pki/crl.pem} {
            # Matched the CRL file line, so end the script
            sleep 1
            exit
        }
        timeout {
            # If the prompt doesn't appear, loop back and wait again
            respond_with_passphrase
        }
    }
}

expect {
    "Confirm removal: " {
        sleep 1
        send "yes\r"
        exp_continue
    }
    "Enter New CA Key Passphrase: " {
        sleep 1
        send "$2\r"
        exp_continue
    }
    "Re-Enter New CA Key Passphrase: " {
        sleep 1
        send "$2\r"
        exp_continue
    }
    -re {Common Name \(.*\) \[.*\]:$} {
        sleep 1
        send "\r"
        exp_continue
    }
}

# Wait for the prompt and respond with passphrase
respond_with_passphrase


EOF

## Write create_user file
cat <<EOF > ./create_user.exp
#!/usr/bin/expect -f

set passphrase $2

set username [lindex \$argv 0]
set password [lindex \$argv 1]

spawn docker-compose run --rm openvpn easyrsa build-client-full \$username

proc respond_with_passphrase {} {
    expect {
        "Enter PEM pass phrase:" {
            # Respond with the passphrase
            sleep 1
            send "$::password\r"
            exp_continue
        }
        "Verifying - Enter PEM pass phrase:" {
            # Confirm the passphrase
            sleep 1
            send "$::password\r"
            exp_continue
        }
        "Enter pass phrase for /etc/openvpn/pki/private/ca.key:" {
            # Respond with the passphrase for the CA key
            sleep 1
            send "$::passphrase\r"
            exp_continue
        }
        "Data Base Updated" {
            # Successfully created the user, so end the script
            sleep 1
            exit
        }
        timeout {
            # Handle timeout situations, if necessary
            puts "Timeout occurred."
            exit 1
        }
    }
}

# Wait for the prompt and respond with passphrase
respond_with_passphrase

EOF

## Write add_user file
cat <<EOF > ./add_user.sh
#!/bin/bash

./create_user.exp \$1 \$2

docker-compose run --rm openvpn ovpn_getclient \$1 > \$1.ovpn

sed -i -E 's/^remote[[:space:]]+[0-9.]+[[:space:]]+[0-9]+[[:space:]]+tcp$/remote $4 $5 tcp/' \$1.ovpn

EOF

chmod +x ./create_ca.exp
chmod +x ./create_user.exp
chmod +x ./add_user.sh

docker-compose down

docker-compose run --rm openvpn ovpn_genconfig -u tcp://$IP

sed -i -e "s/^port [0-9]\+$/port $1/" ./openvpn-data/conf/openvpn.conf

./create_ca.exp

chown -R $(whoami): ./openvpn-data

docker-compose up -d
docker-compose ps

echo ""
echo ""
echo ""
echo ""

cat <<EOF > ./info.log
================================================

## Run this command on your bridge(interanet) server:
sudo curl -s https://raw.githubusercontent.com/MahdadGhasemian/openvpn-bridge-config/main/install-bridge.sh | bash -s $3 $5 $1 $IP


## RUN this command to add new user (on the upstream server)
./add_user.sh USERNAME PASSWORD
example: ./add_user user1 1234

================================================

EOF

cat ./info.log
