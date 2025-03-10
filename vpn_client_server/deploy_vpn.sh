#!/bin/bash
# Script to deploy OpenVPN server using Docker and generate client configuration

# Configuration
DOCKER_IMAGE="kylemanna/openvpn"
OVPN_DATA_DIR="./openvpn-data"
PUBLIC_IP="sniffstockholm.duckdns.org"
#PUBLIC_IP="130.237.11.45"
CLIENT_NAME="CLIENTTEST1"

# Detect the local IP of the machine within 192.168.10.0/24
LOCAL_IP=$(ip -4 addr show | grep -oP '192\.168\.10\.\d+' | head -n 1)

# Ensure an IP was found
if [[ -z "$LOCAL_IP" ]]; then
    echo "Error: Could not detect a valid IP in 192.168.10.0/24"
    exit 1
fi

# Stop and remove any running containers using the same image
EXISTING_CONTAINERS=$(docker ps -aq --filter ancestor=$DOCKER_IMAGE)
echo "existing container : $EXISTING_CONTAINER"
if [[ -n "$EXISTING_CONTAINER" ]]; then
    echo "Stopping existing OpenVPN container..."
    docker stop $EXISTING_CONTAINER
    echo "Removing existing OpenVPN container..."
    docker rm $EXISTING_CONTAINER
fi


# Step 1: Pull the Docker Image
echo "Pulling OpenVPN Docker image..."
docker pull $DOCKER_IMAGE

# Step 2: Create OpenVPN Config Directory
echo "Creating OpenVPN data directory..."
mkdir -p $OVPN_DATA_DIR

# Step 3: Generate OpenVPN Configuration
echo "Generating OpenVPN configuration..."
sudo rm -rf ./openvpn-data/*
docker run -v $OVPN_DATA_DIR:/etc/openvpn --rm $DOCKER_IMAGE ovpn_genconfig -u udp://$PUBLIC_IP

# Step 4: Initialize the PKI and CA and CRL
echo "Initializing PKI and generating CA..."
docker run -v $OVPN_DATA_DIR:/etc/openvpn --rm -it $DOCKER_IMAGE ovpn_initpki

## CRL
docker run -v $OVPN_DATA_DIR:/etc/openvpn --rm -it $DOCKER_IMAGE easyrsa gen-crl

# Step 5: Deploy the OpenVPN Server and modify openvpn.conf file
echo "Starting OpenVPN server..."
docker run -v $OVPN_DATA_DIR:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN $DOCKER_IMAGE

### Repeat steps 6-7 for each new user
# Step 6: Generate Client Certificates
echo "Generating client certificate for $CLIENT_NAME..."
docker run -v $OVPN_DATA_DIR:/etc/openvpn --rm -it $DOCKER_IMAGE easyrsa build-client-full $CLIENT_NAME nopass

# Step 7: Retrieve the Client Configuration File
echo "Retrieving client configuration..."
docker run -v $OVPN_DATA_DIR:/etc/openvpn --rm $DOCKER_IMAGE ovpn_getclient $CLIENT_NAME > ~/${CLIENT_NAME}.ovpn

# Step 8: Append custom DNS configuration
echo "Adding custom DNS setting to client configuration..."
echo "dhcp-option DNS 192.168.10.56" >> ~/${CLIENT_NAME}.ovpn

echo "OpenVPN server is deployed and client config is ready at ~/${CLIENT_NAME}.ovpn"

ansible-playbook -i inventory.ini router_config.yaml -e "vpn_ip=$LOCAL_IP"

echo "configuring forwarding rules done"

