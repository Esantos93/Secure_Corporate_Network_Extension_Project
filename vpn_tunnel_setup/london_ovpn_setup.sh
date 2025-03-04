#!/bin/sh

# Define OpenVPN client configuration directory
OVPNCL_DIR="/tmp/openvpncl"


extract_cert() {
    awk '/-----BEGIN CERTIFICATE-----/{flag=1} flag; /-----END CERTIFICATE-----/{flag=0}' "$1"
}

extract_key() {
    awk '/-----BEGIN PRIVATE KEY-----/{flag=1} flag; /-----END PRIVATE KEY-----/{flag=0}' "$1"
}

# Clear old OpenVPN settings
nvram unset openvpncl_ca
nvram unset openvpncl_client
nvram unset openvpncl_key
nvram commit

# Store certificates and key in NVRAM using extracted values
nvram set openvpncl_ca="$(extract_cert $OVPNCL_DIR/ca.crt)"
nvram set openvpncl_client="$(extract_cert $OVPNCL_DIR/cert.pem)"
nvram set openvpncl_key="$(extract_key $OVPNCL_DIR/key.pem)"
nvram commit



# Create the OpenVPN client configuration file
cat <<EOF > "$OVPNCL_DIR/openvpncl.conf"
ca /tmp/openvpncl/ca.crt
cert /tmp/openvpncl/cert.pem
key /tmp/openvpncl/key.pem
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
remote 130.237.11.40 1194
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
