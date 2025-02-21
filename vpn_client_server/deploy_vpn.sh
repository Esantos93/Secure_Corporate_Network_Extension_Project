#!/bin/bash
# Script to deploy OpenVPN server using Docker and generate client configuration

# Configuration
DOCKER_IMAGE="kylemanna/openvpn"
OVPN_DATA_DIR="./openvpn-data"
#PUBLIC_IP="smp420.duckdns.org"
PUBLIC_IP="130.237.11.52"
CLIENT_NAME="CLIENTNAME"

# Step 1: Pull the Docker Image
echo "Pulling OpenVPN Docker image..."
docker pull $DOCKER_IMAGE

# Step 2: Create OpenVPN Config Directory
echo "Creating OpenVPN data directory..."
mkdir -p $OVPN_DATA_DIR

# Step 3: Generate OpenVPN Configuration
echo "Generating OpenVPN configuration..."
docker run -v $OVPN_DATA_DIR:/etc/openvpn --rm $DOCKER_IMAGE ovpn_genconfig -u udp://$PUBLIC_IP

# Step 4: Initialize the PKI and CA
echo "Initializing PKI and generating CA..."
docker run -v $OVPN_DATA_DIR:/etc/openvpn --rm -it $DOCKER_IMAGE ovpn_initpki

# Step 5: Deploy the OpenVPN Server
echo "Starting OpenVPN server..."
docker run -v $OVPN_DATA_DIR:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN $DOCKER_IMAGE

# Step 6: Generate Client Certificates
echo "Generating client certificate for $CLIENT_NAME..."
docker run -v $OVPN_DATA_DIR:/etc/openvpn --rm -it $DOCKER_IMAGE easyrsa build-client-full $CLIENT_NAME nopass

# Step 7: Retrieve the Client Configuration File
echo "Retrieving client configuration..."
docker run -v $OVPN_DATA_DIR:/etc/openvpn --rm $DOCKER_IMAGE ovpn_getclient $CLIENT_NAME > ./${CLIENT_NAME}.ovpn

echo "OpenVPN server is deployed and client config is ready at ./${CLIENT_NAME}.ovpn"
echo "configuring forwarding rules"

ansible-playbook -i inventory.ini router_config.yaml

echo "configuring forwarding rules done"

