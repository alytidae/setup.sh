#!/bin/bash
set -e

# ========================
# 👤 Create a new user
# ========================

# You must have these variables set in config.sh or beforehand
: "${SETUP_USER_NAME:?SETUP_USER_NAME is not set}"
: "${SETUP_USER_PASSWORD:?SETUP_USER_PASSWORD is not set}"

USERNAME="$SETUP_USER_NAME"
PASSWORD="$SETUP_USER_PASSWORD"

# Check if user already exists
if id "$USERNAME" &>/dev/null; then
  echo "ℹ️ User '$USERNAME' already exists. Skipping creation."
else
  echo "🧑 Creating user '$USERNAME'..."

  # Create the user with home directory and bash shell
  useradd -m -s /bin/bash "$USERNAME"

  # Set the password (using chpasswd for automation)
  echo "$USERNAME:$PASSWORD" | chpasswd

  echo "✅ User '$USERNAME' created."
fi
