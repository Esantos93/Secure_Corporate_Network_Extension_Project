DOCKER_IMAGE="kylemanna/openvpn"
OVPN_DATA_DIR="./openvpn-data"

# Check if a client name is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <CLIENT_NAME>"
    exit 1
fi

CLIENT_NAME="$1"


docker run -v $OVPN_DATA_DIR:/etc/openvpn --rm -it $DOCKER_IMAGE easyrsa revoke $CLIENT_NAME

docker run -v $OVPN_DATA_DIR:/etc/openvpn --rm -it $DOCKER_IMAGE easyrsa gen-crl

docker run -v $OVPN_DATA_DIR:/etc/openvpn --rm -it $DOCKER_IMAGE bash -c "cp /etc/openvpn/pki/crl.pem /etc/openvpn/crl.pem"

docker stop $(docker ps -q --filter ancestor=$DOCKER_IMAGE)
docker run -v $OVPN_DATA_DIR:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN $DOCKER_IMAGE
