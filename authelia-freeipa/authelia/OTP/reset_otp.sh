# Access the Authelia container
docker-compose exec authelia sh

# Install SQLite if needed
apk add sqlite

# Access the database
sqlite3 /config/db.sqlite3

# View users with OTP configured
SELECT username FROM totp_configurations;

# Delete a specific user's OTP configuration
DELETE FROM totp_configurations WHERE username='username_to_reset';

# Exit SQLite and the container
.exit
exit

# NEED TO INSTALL QRENCODE

# List all TOTP configurations
docker compose exec authelia authelia storage user totp list

# Delete a specific user's TOTP configuration
docker compose exec authelia authelia storage user totp delete username_to_reset

# Delete all TOTP configurations
docker compose exec authelia authelia storage user totp delete all