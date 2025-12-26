#!/bin/bash
set -euo pipefail

# HTPC Media Stack - k3s Installation Script
# This script installs k3s with settings optimized for a single-node media server

echo "=== Installing k3s ==="

# Install k3s with:
# --disable servicelb: We'll use Traefik's built-in load balancer
# --disable traefik: We'll install Traefik separately for more control (optional)
# For now, keep Traefik enabled as it comes configured

curl -sfL https://get.k3s.io | sh -s - \
    --disable servicelb \
    --write-kubeconfig-mode 644

echo "=== Waiting for k3s to be ready ==="
sleep 10

# Wait for node to be ready
kubectl wait --for=condition=ready node --all --timeout=120s

echo "=== k3s installed successfully ==="
echo ""
echo "Node status:"
kubectl get nodes -o wide
echo ""
echo "System pods:"
kubectl get pods -n kube-system
echo ""
echo "=== Next Steps ==="
echo "1. Install FluxCD CLI: curl -s https://fluxcd.io/install.sh | sudo bash"
echo "2. Create a GitHub repo for your manifests"
echo "3. Run ./bootstrap/flux-bootstrap.sh"
