#/bin/bash


# Check if the script is run as root
if [[ "$#" -ne 2 ]];
  then echo "Usage: ./create-csr.sh <Principal> <Passphrase>"
  exit 1
fi

$principal = $1
$passphrase = $2


# Create openssl key and csr
echo $passphrase | openssl req -new -newkey rsa:2048 -nodes -keyout $principal.key -out $principal.csr -subj "/O=ACME.LOCAL/CN=$principal"
sleep 5



