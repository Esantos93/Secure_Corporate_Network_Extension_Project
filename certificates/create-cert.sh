#!/bin/bash

# Check if the script is run with exactly 3 arguments
if [[ "$#" -ne 3 ]]; then 
  echo "Usage: ./create-csr.sh <FreeIPA Admin Password> <Principal> <Service>"
  echo "Principal: the name of the user or FQDN of the host"
  echo "Service: service for the certificate. Leave blank for user certificate"
  exit 1
fi

admin_passphrase="$1"
principal="$2"
service="$3"

# Build the cert principal based on whether a service is provided
if [[ "$service" != "" ]]; then
  cert_principal="$service/$principal@ACME.LOCAL"
else
  cert_principal="$principal@ACME.LOCAL"
fi

echo "Generating private key and CSR for principal: $cert_principal"

# Generate a private key and CSR
openssl req -new -newkey rsa:2048 -nodes -keyout "${principal}.key" -out "${principal}.csr" -subj "/O=ACME.LOCAL/CN=$principal"

# Authenticate as admin to FreeIPA
echo "$admin_passphrase" | kinit admin

# Submit the CSR for signing by the FreeIPA CA
ipa cert-request "${principal}.csr" --principal="$cert_principal" 

# Get the ca certificate from FreeIPA if it's not already available
if [[ ! -f ./ca.crt ]]; then
  ipa cert-show 0 --out=ca.crt
fi

openssl pkcs12 -export -in "${principal}".crt -inkey "${principal}".key -certfile ca.crt -out "${principal}"_PKCS12.pfx

# Optionally, retrieve the issued certificate
# You can uncomment this block to fetch the cert if you know the serial number
# cert_serial=$(ipa cert-find --principal="$cert_principal" --pkey-only | grep "Serial number:" | awk '{print $3}')
# ipa cert-show "$cert_serial" --out="${principal}.crt"

echo "Certificate request for $cert_principal submitted successfully."

# Clean up: destroy the ticket after you're done
kdestroy
