#!/usr/bin/env bash
set -euo pipefail

kubernetes_dir="${1:-./clusters/main/kubernetes}"

echo "Validating Kubernetes manifests in: ${kubernetes_dir}"

kubeconform \
  -strict \
  -summary \
  -all-comments-enabled \
  -ignore-missing-schemas \
  "${kubernetes_dir}"
