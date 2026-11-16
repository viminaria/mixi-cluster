#!/usr/bin/env bash
set -euo pipefail

kubernetes_dir="${1:-./clusters/main/kubernetes}"

echo "Validating Kubernetes manifests in: ${kubernetes_dir}"

# Filter out SOPS-encrypted files before passing to kubeconform
# (SOPS adds 'sops:' field which isn't valid K8s schema)
files=$(find "${kubernetes_dir}" -name '*.yaml' \
  ! -path '*secret*.yaml' | while IFS= read -r f; do
    if ! grep -q 'sops:' "$f" 2>/dev/null; then
      printf '%s\n' "$f"
    fi
  done)

if [ -z "$files" ]; then
  echo "No non-SOPS files to validate"
  exit 0
fi

echo "$files" | xargs -d '\n' kubeconform -strict -summary -ignore-missing-schemas
