#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="argocd"
OUT_DIR="out"
CONFIG="config.json"

PROJECT_YAML="$OUT_DIR/project.yaml"
REPO_YAML="$OUT_DIR/repo.yaml"
ACCOUNT_YAML="$OUT_DIR/account.yaml"
APPLICATION_YAML="$OUT_DIR/application.yaml"
VALUES_FILE="helm-values.yaml"

DOMAIN=$(jq -r '.host' "$CONFIG")

echo "🔍 Checking required files in '$OUT_DIR'..."

for file in "$PROJECT_YAML" "$REPO_YAML" "$ACCOUNT_YAML" "$APPLICATION_YAML" "$VALUES_FILE"; do
    if [[ ! -f "$file" ]]; then
        echo "❌ File '$file' not found! Please generate it before running this script."
        exit 1
    fi
done
echo "✅ All required files found."

# 1️⃣ Install Argo CD Helm chart
echo "1️⃣ Installing Argo CD Helm chart..."
helm install argo-cd argo/argo-cd \
    --namespace "$NAMESPACE" \
    --create-namespace \
    -f "$VALUES_FILE" \
    --set global.domain="$DOMAIN" \
    || echo "⚠️ Argo CD may already be installed, continuing..."

echo "⏳ Waiting for Argo CD server to be ready..."
kubectl rollout status deployment/argo-cd-argocd-server \
    --namespace "$NAMESPACE" \
    --timeout=120s

# 2️⃣ Apply project.yaml
echo "2️⃣ Applying project.yaml..."
kubectl apply -f "$PROJECT_YAML"
echo "✅ project.yaml applied."

# 3️⃣ Apply repo.yaml
echo "3️⃣ Applying repo.yaml..."
kubectl apply -f "$REPO_YAML"
echo "✅ repo.yaml applied."

# 4️⃣ Apply account.yaml
echo "4️⃣ Applying account.yaml..."
kubectl apply -f "$ACCOUNT_YAML"
echo "✅ account.yaml applied."

# 5️⃣ Apply application.yaml
echo "5️⃣ Applying application.yaml..."
kubectl apply -f "$APPLICATION_YAML"
echo "✅ application.yaml applied."

echo "⏳ Waiting for Argo CD server to become ready at $DOMAIN..."

sleep 120

until curl -sk "https://$DOMAIN"; do
    echo "🔄 Still waiting for $DOMAIN to respond..."
    sleep 30
done
echo "✅ Argo CD server is now accessible at $DOMAIN."

# 6️⃣ Reset all user passwords to default
echo "6️⃣ Reset for all users passwords"
usernames=$(jq -r '.accounts[].name' "$CONFIG")
for user in $usernames; do
    echo "🔄 Resetting password for user: $user"
    ./reset-password.sh <<<"$user"
    echo "✅ Password reset completed for user: $user"
    echo
done
echo "✅ All passwords are resetted to default password"

echo "🎉 All resources deployed successfully! 🚀"
