#!/bin/bash

# Check if a username was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <username>"
    echo "Example: $0 admin"
    exit 1
fi

USERNAME=$1

# Generate a random base32 secret (32 characters - required by Authelia)
# Using only A-Z and 2-7 which are valid base32 characters
SECRET=$(cat /dev/urandom | LC_ALL=C tr -dc 'A-Z2-7' | fold -w 32 | head -n 1)

echo "Generated TOTP secret for $USERNAME: $SECRET"

# Create the otpauth URI - compatible with all major authenticator apps
# This format works with Google Authenticator, Microsoft Authenticator, Authy, etc.
URI="otpauth://totp/Authelia:$USERNAME?secret=$SECRET&issuer=Authelia&digits=6&period=30"

echo "TOTP URI: $URI"
echo ""

# Generate QR code in terminal
echo "Scan this QR code with your authenticator app:"
qrencode -t ANSI "$URI"

# Also save as PNG
PNG_FILE="${USERNAME}_totp.png"
qrencode -o "$PNG_FILE" "$URI"
echo ""
echo "QR code also saved to $PNG_FILE"

# Try to open the PNG file with the default image viewer
if [ "$(uname)" == "Darwin" ]; then
    open "$PNG_FILE"
    elif [ "$(uname)" == "Linux" ]; then
    xdg-open "$PNG_FILE" &> /dev/null || echo "Please open $PNG_FILE with your image viewer."
else
    echo "Please open $PNG_FILE with your image viewer."
fi

echo ""
echo "Adding TOTP configuration to Authelia's database..."

# Add the TOTP configuration to Authelia's database using the correct command format
RESULT=$(docker compose exec -T authelia authelia storage user totp generate "$USERNAME" --force --secret "$SECRET" --algorithm SHA1 --digits 6 --period 30 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ Successfully added TOTP configuration for user '$USERNAME' to Authelia's database!"
    echo ""
    echo "You can now use the code from your authenticator app for 2FA login."
    echo "Compatible with: Google Authenticator, Microsoft Authenticator, Authy, and most other TOTP apps."
    echo "The QR code has been saved to $PNG_FILE for future reference."
else
    echo "❌ Failed to add TOTP configuration to Authelia's database:"
    echo "$RESULT"
    echo ""
    echo "You may need to run the following command manually:"
    echo "docker compose exec authelia authelia storage user totp generate $USERNAME --force --secret $SECRET --algorithm SHA1 --digits 6 --period 30"
fi