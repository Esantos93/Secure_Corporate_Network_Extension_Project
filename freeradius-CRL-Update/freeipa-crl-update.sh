#!/bin/bash

# ===== CONFIGURATION =====
IPA_HOST="freeipa.acme.local"
CRL_URL="http://${IPA_HOST}/ipa/crl/MasterCRL.bin"

CERT_DIR="/etc/freeradius/3.0/certs"
IPA_CA_CERT="${CERT_DIR}/ca.crt"
TMP_DIR="/tmp"

CRL_DER="${TMP_DIR}/ipa.crl.der"
CRL_PEM="${TMP_DIR}/ipa.crl.pem"
OUTPUT_FILE="${CERT_DIR}/freeipa.pem"

# ===== FETCH THE CRL (DER FORMAT) =====
wget -q -O ${CRL_DER} ${CRL_URL}
if [[ $? -ne 0 ]]; then
    echo "Failed to fetch the CRL from ${CRL_URL}"
    exit 1
fi

# ===== CONVERT DER TO PEM =====
openssl crl -inform DER -in "${CRL_DER}" -outform PEM -out "${CRL_PEM}"
if [[ $? -ne 0 ]]; then
    echo "Failed to convert the CRL from DER to PEM"
    exit 1
fi

# ===== APPEND THE IPA CA CERTIFICATE TO THE CRL PEM FILE =====
{
    sed -e '$a\' "${IPA_CA_CERT}"
    cat "${CRL_PEM}"
} > "${OUTPUT_FILE}"
if [[ $? -ne 0 ]]; then
    echo "Failed to append the IPA CA certificate to the CRL PEM file"
    exit 1
fi

# ===== SET PERMISSIONS =====
chown freerad:freerad "${OUTPUT_FILE}"
chmod 640 "${OUTPUT_FILE}"

systemctl restart freeradius

echo "CRL updated successfully"
exit 0
