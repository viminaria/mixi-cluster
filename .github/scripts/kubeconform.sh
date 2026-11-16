#!/usr/bin/env bash
set -euo pipefail

kubernetes_dir="${1:-./clusters/main/kubernetes}"

echo "Validating Kubernetes manifests in: ${kubernetes_dir}"

# Use kustomize to process everything (resolves SOPS, substitutions, etc.),
# then validate the built output with kubeconform
kustomize build "${kubernetes_dir}" | kubeconform -strict -summary -ignore-missing-schemas -
