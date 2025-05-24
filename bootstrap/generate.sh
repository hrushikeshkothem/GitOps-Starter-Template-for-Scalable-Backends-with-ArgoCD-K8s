#!/usr/bin/env bash
set -euo pipefail

CONFIG="./config.json"
OUT_DIR="./out"
NAMESPACE="argocd"

mkdir -p "$OUT_DIR"

# 1️⃣ Generate AppProject manifest
cat >"$OUT_DIR/project.yaml" <<EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: projectName                                           # Modify Project name
  namespace: $NAMESPACE
spec:
  sourceRepos:
    - "git@github.com:user/repo.git"                          # Modify repo url
  sourceNamespaces: []
  destinations:
    - namespace: "*"
      server: "https://kubernetes.default.svc"
  clusterResourceWhitelist:
    - group: '*'
      kind: '*'
  roles:
EOF

jq -c '.roles[]' "$CONFIG" | while read -r role; do
    name=$(echo "$role" | jq -r '.name')
    description=$(echo "$role" | jq -r '.description')
    echo "    - name: $name"
    echo "      description: \"$description\""

    echo "      policies:"
    echo "$role" | jq -r '.policies[]' | sed 's/^/        - /'

    echo "      groups:"
    echo "$role" | jq -r '.groups[]' | sed 's/^/        - /'
done >>"$OUT_DIR/project.yaml"

echo "→ Generated $OUT_DIR/project.yaml"

# 2️⃣ Get SSH key path from config.json
KEY_PATH=$(jq -r '.sshPath' "$CONFIG")

if [[ ! -f "$KEY_PATH" ]]; then
    echo "Error: SSH key file not found at $KEY_PATH" >&2
    exit 1
fi
if ! grep -q '^-----BEGIN OPENSSH PRIVATE KEY-----' "$KEY_PATH"; then
    echo "Error: file at $KEY_PATH does not look like a valid OpenSSH private key" >&2
    exit 1
fi

# Indent ssh key content for YAML
SSH_KEY_CONTENT=$(sed 's/^/    /' "$KEY_PATH")

# 3️⃣ Generate Secret manifest with SSH key
cat >"$OUT_DIR/repo.yaml" <<EOF
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: argocd-git-ssh-key
  namespace: $NAMESPACE
  annotations:
    managed-by: argocd.argoproj.io
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  name:    "secret"                                    
  project: "projectName"                                  # Modify Project name
  url:     "git@github.com:user/repo.git"                 # Modify repo url
  sshPrivateKey: |
${SSH_KEY_CONTENT}
  insecure: "true"
  enableLfs: "true"
EOF

echo "→ Generated $OUT_DIR/repo.yaml"

# 4️⃣ Generate accounts + RBAC ConfigMaps
(
    echo "apiVersion: v1"
    echo "kind: ConfigMap"
    echo "metadata:"
    echo "  name: argocd-cm"
    echo "  namespace: $NAMESPACE"
    echo "  labels:"
    echo "    app.kubernetes.io/name: argocd-cm"
    echo "    app.kubernetes.io/part-of: argocd"
    echo "data:"
    jq -r '
    .accounts[]
    | "  accounts.\(.name): \(.access)"
  ' "$CONFIG"

    echo "---"

    echo "apiVersion: v1"
    echo "kind: ConfigMap"
    echo "metadata:"
    echo "  name: argocd-rbac-cm"
    echo "  namespace: $NAMESPACE"
    echo "  labels:"
    echo "    app.kubernetes.io/name: argocd-rbac-cm"
    echo "    app.kubernetes.io/part-of: argocd"
    echo "data:"
    echo "  policy.csv: |"
    jq -r '
    .accounts[]
    | "    g, \(.name), \(.group)"
  ' "$CONFIG"
) >"$OUT_DIR/account.yaml"

echo "→ Generated $OUT_DIR/account.yaml"

cat >"$OUT_DIR/application.yaml" <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-application
  namespace: argocd
spec:
  project: projectName                                            # Modify project name
  source:
    repoURL: git@github.com:user/repo.git                         # Modify repo url
    targetRevision: main                                          # Modify branch name
    path: clusters
    directory:
      recurse: true
      jsonnet: {}
      exclude: '{**/apps/**,**/argo-apps/**}'
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

echo "→ Generated $OUT_DIR/application.yaml"

echo "✅ All POC files written into $OUT_DIR/ — you can compare them with your existing files."
echo "✅ Verify the generated files and execute setup.sh"
