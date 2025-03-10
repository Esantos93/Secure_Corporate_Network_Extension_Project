#!/bin/sh
set -e

# Update CA certificates before Authelia starts
update-ca-certificates --fresh

# Start Authelia
exec /init