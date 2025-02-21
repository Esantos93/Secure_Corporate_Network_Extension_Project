#!/bin/bash

# Variables
ROUTER_USER="root"
ROUTER_IP="192.168.10.1"
REMOTE_DIR="/tmp/openvpn"
SCRIPT_SETUP="stockholm_ovpn_setup.sh"

bash generate_certs.sh

# Ensure OpenVPN is enabled and create directory on the router
echo "Enabling OpenVPN and creating directory on the router..."
ssh -o StrictHostKeyChecking=no -i "~/.ssh/bnss" "$ROUTER_USER@$ROUTER_IP" << EOF
    nvram set openvpn_enable=1
    nvram commit
    mkdir -p $REMOTE_DIR
EOF

# Copy certificates and keys to the router
echo "Transferring keys and certificates to the router..."
scp -i "~/.ssh/bnss" "easy-rsa/easyrsa3/pki/ca.crt" "$ROUTER_USER@$ROUTER_IP:$REMOTE_DIR/"
scp -i "~/.ssh/bnss" "easy-rsa/easyrsa3/pki/issued/server-g6.crt" "$ROUTER_USER@$ROUTER_IP:$REMOTE_DIR/cert.pem"
scp -i "~/.ssh/bnss" "easy-rsa/easyrsa3/pki/private/server-g6.key" "$ROUTER_USER@$ROUTER_IP:$REMOTE_DIR/key.pem"

echo "Files successfully transferred to the router at $REMOTE_DIR."


# Copy script to router
scp -i "~/.ssh/bnss" $SCRIPT_SETUP $ROUTER_USER@$ROUTER_IP:/tmp/

# Execute script remotely, passing SSID and password as arguments
ssh -i "~/.ssh/bnss" $ROUTER_USER@$ROUTER_IP "sh /tmp/$SCRIPT_SETUP"
