#!/bin/bash

# Define directories
EASYRSA_DIR=easy-rsa
KEY_DIR="$EASYRSA_DIR/easyrsa3/pki"
EASYRSA_BIN=$EASYRSA_DIR/easyrsa3

# Clone EasyRSA repository if not already present
if [ ! -d "$EASYRSA_DIR" ]; then
    echo "Cloning EasyRSA repository..."
    git clone https://github.com/OpenVPN/easy-rsa.git
fi

# Navigate to EasyRSA directory
cd "$EASYRSA_BIN" || exit

# Initialize PKI
echo "Initializing PKI..."
yes | ./easyrsa init-pki

# Build CA (Certificate Authority)
echo "Generating CA..."
yes | ./easyrsa build-ca nopass

# Generate Server Certificate
echo "Generating Server Certificate..."
yes | ./easyrsa gen-req server-g6 nopass
./easyrsa sign-req server server-g6

# Generate Client Certificate
echo "Generating Client Certificate..."
yes | ./easyrsa gen-req client-g6 nopass
./easyrsa sign-req client client-g6

# Generate Diffie-Hellman Parameters (Not needed as we're using ECDH)
echo "Skipping DH parameters (using ECDH instead)..."

# Display paths of generated files
echo "Keys and certificates generated:"

# Instructions to copy keys
echo "Copy the following files to the DD-WRT server:"
echo "- CA Certificate: $KEY_DIR/ca.crt"
echo "- Server Certificate: $KEY_DIR/issued/server-g6.crt"
echo "- Server Private Key: $KEY_DIR/private/server-g6.key"
echo "- Client Certificate: $KEY_DIR/issued/client-g6.crt"
echo "- Client Private Key: $KEY_DIR/private/client-g6.key"
