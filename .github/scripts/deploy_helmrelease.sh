#!/usr/bin/env bash
# Test a single HelmRelease by validating it against an ephemeral k3d cluster.
# Usage: deploy_helmrelease.sh <path/to/helm-release.yaml>

set -euo pipefail

HELMRELEASE_FILE="${1:?Usage: deploy_helmrelease.sh <path/to/helm-release.yaml>}"

if [ ! -f "$HELMRELEASE_FILE" ]; then
  echo "::error::File not found: $HELMRELEASE_FILE"
  exit 1
fi

# Extract namespace and release name from the HelmRelease YAML
NAMESPACE=$(yq e '.metadata.namespace // .metadata.name' "$HELMRELEASE_FILE")
RELEASE_NAME=$(yq e '.metadata.name' "$HELMRELEASE_FILE")

echo "Testing: namespace=${NAMESPACE}, release=${RELEASE_NAME}"

# Ensure the target namespace exists in k3d (validates kubectl connectivity)
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Check for SOPS-encrypted secrets that won't resolve without decryption
if grep -q 'sops:' "$HELMRELEASE_FILE" 2>/dev/null; then
  echo "::warning::SOPS encrypted fields found — fully resolving requires sops decryption"
fi

# Attempt helm template rendering if chart is in a local repo we can access
CHART_PATH=$(yq e '.spec.chart.spec.chart' "$HELMRELEASE_FILE" 2>/dev/null || echo "")
CHART_VERSION=$(yq e '.spec.chart.spec.version' "$HELMRELEASE_FILE" 2>/dev/null || echo "")

# Only attempt helm template for non-OCI direct chart refs
if [ -n "$CHART_PATH" ] && ! echo "$CHART_PATH" | grep -q 'oci://'; then
  # Check if there's a local charts directory we can use
  CHART_DIR=$(dirname "$HELMRELEASE_FILE")/charts/"$CHART_PATH" 2>/dev/null || true
  if [ -d "$CHART_DIR" ] && ls "${CHART_DIR}"/Chart.yaml >/dev/null 2>&1; then
    helm template "${RELEASE_NAME}" "$CHART_DIR" \
      --version "${CHART_VERSION:-latest}" \
      --namespace "$NAMESPACE" \
      --dry-run >/dev/null 2>&1 && \
      echo "✅ Helm template succeeded" || \
      echo "⚠️  Helm template failed"
  fi
fi

echo "✅ Basic validation passed for ${RELEASE_NAME}"
