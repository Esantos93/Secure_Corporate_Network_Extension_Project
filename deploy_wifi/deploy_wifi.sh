#!/bin/bash

ROUTER_IP="192.168.11.1"
USER="root"
SCRIPT="set_password.sh"

# Ask user for SSID and password securely
read -p "Enter new Wi-Fi SSID: " NEW_SSID
read -s -p "Enter new Wi-Fi password: " NEW_PASS
echo ""

# Copy script to router
scp -i "~/.ssh/bnss" $SCRIPT $USER@$ROUTER_IP:/tmp/

# Execute script remotely, passing SSID and password as arguments
ssh -i "~/.ssh/bnss" $USER@$ROUTER_IP "sh /tmp/$SCRIPT \"$NEW_SSID\" \"$NEW_PASS\""
