#!/usr/bin/env bash
set -euo pipefail

# Load config.json
CONFIG_FILE="config.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "❌ Config file $CONFIG_FILE not found!"
    exit 1
fi

# Extract values from config.json using jq
HOST=$(jq -r '.host' "$CONFIG_FILE")
DEFAULT_PW=$(jq -r '.default_password' "$CONFIG_FILE")

# Prompt for target username
read -p "Enter the Argo CD username to reset: " TARGET_USER

# Get initial admin password from Kubernetes secret
ADMIN_PW=$(kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" | base64 --decode)

# Login to Argo CD using admin credentials
argocd login "$HOST" \
    --username admin \
    --password "$ADMIN_PW" \
    --insecure --grpc-web >/dev/null

# Update the target user's password
argocd account update-password \
    --account "$TARGET_USER" \
    --current-password "$ADMIN_PW" \
    --new-password "$DEFAULT_PW" \
    --grpc-web

echo "✅ Password for user '$TARGET_USER' has been reset to: $DEFAULT_PW"
echo "   You can now log in at: https://$HOST"
