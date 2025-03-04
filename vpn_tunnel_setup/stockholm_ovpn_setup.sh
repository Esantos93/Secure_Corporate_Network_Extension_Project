#!/bin/sh

# Define OpenVPN configuration directory
OVPN_DIR="/tmp/openvpn"

extract_cert() {
    sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' "$1"
}

extract_key() {
    sed -n '/-----BEGIN PRIVATE KEY-----/,/-----END PRIVATE KEY-----/p' "$1"
}

# Clear old OpenVPN settings
nvram unset openvpn_ca
nvram unset openvpn_crt
nvram unset openvpn_key
nvram commit

# Store certificates and key in NVRAM using extracted values
nvram set openvpn_ca="$(extract_cert $OVPN_DIR/ca.crt)"
nvram set openvpn_crt="$(extract_cert $OVPN_DIR/cert.pem)"
nvram set openvpn_key="$(extract_key $OVPN_DIR/key.pem)"
nvram commit

# Create the OpenVPN server configuration file
cat <<EOF > "$OVPN_DIR/openvpn.conf"
ca /tmp/openvpn/ca.crt
cert /tmp/openvpn/cert.pem
key /tmp/openvpn/key.pem
keepalive 10 120
verb 3
mute 3
syslog
writepid /var/run/openvpnd.pid
management 127.0.0.1 14
management-log-cache 100
topology subnet
script-security 2
port 1194
proto udp4
auth none
data-ciphers CHACHA20-POLY1305:AES-128-GCM:AES-256-GCM
client-connect /tmp/openvpn/clcon.sh
client-disconnect /tmp/openvpn/cldiscon.sh
client-config-dir /tmp/openvpn/ccd
duplicate-cn
client-to-client
push "redirect-gateway def1"
fast-io
tun-mtu 1400
mtu-disc yes
server 10.8.0.0 255.255.255.0
dev tun2
dh none
ecdh-curve secp384r1
route-up /tmp/openvpn/route-up.sh
route-pre-down /tmp/openvpn/route-down.sh
verb 5
route 192.168.11.0 255.255.255.0 vpn_gateway
EOF

# Set up firewall rules
echo "Configuring firewall..."
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o $(nvram get wan_iface) -j MASQUERADE
iptables -A INPUT -i tun2 -j ACCEPT
iptables -A FORWARD -i tun2 -o $(nvram get wan_iface) -j ACCEPT
iptables -A FORWARD -i $(nvram get wan_iface) -o tun2 -j ACCEPT

# Apply configuration and restart OpenVPN
echo "Restarting OpenVPN..."
nvram commit
stopservice openvpn
startservice openvpn

echo "OpenVPN Server Setup Completed!"
echo "Rebooting..."
