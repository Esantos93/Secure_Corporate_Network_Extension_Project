#!/bin/bash

# Get SSID and password from command-line arguments
NEW_SSID="$1"
NEW_PASS="$2"

if [ -z "$NEW_SSID" ] || [ -z "$NEW_PASS" ]; then
    echo "Usage: sh set_wifi.sh <SSID> <PASSWORD>"
    exit 1
fi

# Apply settings
nvram set wl0_ssid="$NEW_SSID"
nvram set wl0_security_mode="psk2"
nvram set wl0_crypto="aes"
nvram set wl0_wpa_psk="$NEW_PASS"

# Save settings and reboot
nvram commit
echo "Wi-Fi settings updated. Rebooting..."
reboot
