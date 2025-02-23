#!/bin/bash

# Set Variables
DOCKER_IMAGE="nginx_web_server"
CONTAINER_NAME="webserver"

# Build the Docker image
docker build -t $DOCKER_IMAGE .

# Stop and remove any existing container
docker stop $CONTAINER_NAME 2>/dev/null
docker rm $CONTAINER_NAME 2>/dev/null

# Run the new container with host networking
docker run -d --name $CONTAINER_NAME --network host $DOCKER_IMAGE

echo "Nginx server deployed successfully!"

# Detect the local IP of the machine within 192.168.10.0/24
LOCAL_IP=$(ip -4 addr show | grep -oP '192\.168\.10\.\d+' | head -n 1)

# Ensure an IP was found
if [[ -z "$LOCAL_IP" ]]; then
    echo "Error: Could not detect a valid IP in 192.168.10.0/24"
    exit 1
fi

# Generate inventory.ini
cat > inventory.ini <<EOF
[webserver]
$LOCAL_IP

[router]
192.168.10.1 ansible_user=root ansible_ssh_private_key_file=~/.ssh/bnss
EOF

echo "created inventory file"

ansible-playbook -i inventory.ini forwarding_rules.yaml -e "webserver_ip=$LOCAL_IP"
echo "forwarding rules enforced"
