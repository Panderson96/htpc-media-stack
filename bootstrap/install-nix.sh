#!/bin/bash
set -euo pipefail

# HTPC Media Stack - Nix Installation Script
# Installs Nix package manager with flakes enabled

echo "=== Installing Nix Package Manager ==="

# Check if Nix is already installed
if command -v nix &> /dev/null; then
    echo "Nix is already installed: $(nix --version)"
    exit 0
fi

# Install Nix using the Determinate Systems installer (recommended)
# This installer enables flakes by default and is more user-friendly
echo "Installing Nix via Determinate Systems installer..."
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

echo ""
echo "=== Nix Installation Complete ==="
echo ""
echo "Please restart your shell or run:"
echo "  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
echo ""
echo "Then verify with:"
echo "  nix --version"
echo ""
echo "=== Next Steps ==="
echo ""
echo "1. Enter the dev environment:"
echo "   cd $(pwd) && nix develop"
echo ""
echo "2. Or use direnv for auto-loading:"
echo "   nix profile install nixpkgs#direnv"
echo "   echo 'eval \"\$(direnv hook bash)\"' >> ~/.bashrc"
echo "   direnv allow"
echo ""
