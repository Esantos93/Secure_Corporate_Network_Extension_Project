DOCKER_IMAGE="kylemanna/openvpn"
OVPN_DATA_DIR="./openvpn-data"
CLIENT_NAME="CLIENTTEST1"

# Generate Client Certificates
echo "Generating client certificate for $CLIENT_NAME..."
docker run -v $OVPN_DATA_DIR:/etc/openvpn --rm -it $DOCKER_IMAGE easyrsa build-client-full $CLIENT_NAME nopass

# Retrieve the Client Configuration File
echo "Retrieving client configuration..."
docker run -v $OVPN_DATA_DIR:/etc/openvpn --rm $DOCKER_IMAGE ovpn_getclient $CLIENT_NAME > ~/${CLIENT_NAME}.ovpn

# Append custom DNS configuration
echo "Adding custom DNS setting to client configuration..."
echo "dhcp-option DNS 192.168.10.56" >> ~/${CLIENT_NAME}.ovpn
echo "Client config is ready at ~/${CLIENT_NAME}.ovpn"
