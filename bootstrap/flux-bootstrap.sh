#!/bin/bash
set -euo pipefail

# HTPC Media Stack - FluxCD Bootstrap Script
# This script bootstraps FluxCD to manage your cluster via GitOps

# Configuration - UPDATE THESE VALUES
GITHUB_USER="${GITHUB_USER:-your-github-username}"
GITHUB_REPO="${GITHUB_REPO:-htpc-media-stack}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"

echo "=== FluxCD Bootstrap ==="
echo "GitHub User: $GITHUB_USER"
echo "GitHub Repo: $GITHUB_REPO"
echo "Branch: $GITHUB_BRANCH"
echo ""

# Check if flux CLI is installed
if ! command -v flux &> /dev/null; then
    echo "FluxCD CLI not found. Installing..."
    curl -s https://fluxcd.io/install.sh | sudo bash
fi

# Check flux prerequisites
echo "=== Checking prerequisites ==="
flux check --pre

# Prompt for GitHub token if not set
if [ -z "${GITHUB_TOKEN:-}" ]; then
    echo ""
    echo "Please enter your GitHub Personal Access Token (PAT):"
    echo "(Needs 'repo' scope for private repos, or 'public_repo' for public)"
    read -s GITHUB_TOKEN
    export GITHUB_TOKEN
fi

echo ""
echo "=== Bootstrapping FluxCD ==="

# Bootstrap Flux
flux bootstrap github \
    --owner="$GITHUB_USER" \
    --repository="$GITHUB_REPO" \
    --branch="$GITHUB_BRANCH" \
    --path=kubernetes \
    --personal

echo ""
echo "=== FluxCD Bootstrap Complete ==="
echo ""
echo "Flux will now watch the 'kubernetes/' directory in your repo."
echo "Any changes pushed to Git will be automatically applied to the cluster."
echo ""
echo "Useful commands:"
echo "  flux get all                    # View all Flux resources"
echo "  flux logs                       # View Flux logs"
echo "  flux reconcile source git flux-system  # Force sync from Git"
echo "  kubectl get pods -A             # View all pods"
