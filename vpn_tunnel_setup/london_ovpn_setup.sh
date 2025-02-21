#!/bin/sh

# Define OpenVPN client configuration directory
OVPNCL_DIR="/tmp/openvpncl"

# Create the OpenVPN client configuration file
cat <<EOF > "$OVPNCL_DIR/openvpncl.conf"
ca /tmp/openvpncl/ca.crt
cert /tmp/openvpncl/client.crt
key /tmp/openvpncl/client.key
management 127.0.0.1 16
management-log-cache 100
verb 3
mute 3
syslog
writepid /var/run/openvpncl.pid
resolv-retry infinite
script-security 2
nobind
client
dev tun1
proto udp4
cipher CHACHA20-POLY1305
auth none
data-ciphers CHACHA20-POLY1305:AES-128-GCM:AES-256-GCM
remote smp420.duckdns.org 1194
tun-mtu 1400
mtu-disc yes
remote-cert-tls server
fast-io
route-up /tmp/openvpncl/route-up.sh
route-pre-down /tmp/openvpncl/route-down.sh
verb 5
EOF

# Apply configuration and restart OpenVPN client
echo "Restarting OpenVPN Client..."
stopservice openvpnclient
startservice openvpnclient

echo "OpenVPN Client Setup Completed!"
echo "Rebooting..."
reboot