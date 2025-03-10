#!/bin/bash

# Check if at least one username was provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <username1> [username2] [username3] ..."
    echo "Example: $0 admin user1 user2"
    exit 1
fi

# Create a directory for QR codes if it doesn't exist
QRDIR="totp_qrcodes"
mkdir -p "$QRDIR"

# Process each username
for USERNAME in "$@"; do
    echo "======================================================="
    echo "Setting up TOTP for user: $USERNAME"
    echo "======================================================="
    
    # Generate a random base32 secret (32 characters - required by Authelia)
    # Using only A-Z and 2-7 which are valid base32 characters
    SECRET=$(cat /dev/urandom | LC_ALL=C tr -dc 'A-Z2-7' | fold -w 32 | head -n 1)
    
    echo "Generated TOTP secret for $USERNAME: $SECRET"
    
    # Create the otpauth URI - compatible with all major authenticator apps
    # This format works with Google Authenticator, Microsoft Authenticator, Authy, etc.
    URI="otpauth://totp/Authelia:$USERNAME?secret=$SECRET&issuer=Authelia&digits=6&period=30"
    
    echo "TOTP URI: $URI"
    echo ""
    
    # Save QR code as PNG
    PNG_FILE="$QRDIR/${USERNAME}_totp.png"
    qrencode -o "$PNG_FILE" "$URI"
    echo "QR code saved to $PNG_FILE"
    
    echo ""
    echo "Adding TOTP configuration to Authelia's database..."
    
    # Add the TOTP configuration to Authelia's database
    RESULT=$(docker compose exec -T authelia authelia storage user totp generate "$USERNAME" --force --secret "$SECRET" --algorithm SHA1 --digits 6 --period 30 2>&1)
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]; then
        echo "✅ Successfully added TOTP configuration for user '$USERNAME' to Authelia's database!"
    else
        echo "❌ Failed to add TOTP configuration for user '$USERNAME' to Authelia's database:"
        echo "$RESULT"
    fi
    
    echo ""
done

echo "======================================================="
echo "TOTP Setup Complete"
echo "======================================================="
echo "All QR codes have been saved to the '$QRDIR' directory."
echo "You can distribute these QR codes to the respective users."
echo ""
echo "Compatible with: Google Authenticator, Microsoft Authenticator, Authy, and most other TOTP apps."
echo ""
echo "To view all QR codes at once, run:"
echo "open $QRDIR  # On macOS"
echo "# OR"
echo "xdg-open $QRDIR  # On Linux"