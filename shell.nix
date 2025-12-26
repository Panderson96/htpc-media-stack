# Fallback for users without flakes enabled
# Usage: nix-shell
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "htpc-media-stack";

  buildInputs = with pkgs; [
    # Kubernetes tools
    kubectl
    kubernetes-helm
    kustomize
    k9s
    stern
    kubectx

    # GitOps
    fluxcd

    # Utilities
    jq
    yq-go
    age
    sops
    git
    curl
  ];

  shellHook = ''
    echo "🎬 HTPC Media Stack Development Environment"
    echo ""

    if [ -f /etc/rancher/k3s/k3s.yaml ]; then
      export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
      echo "✓ KUBECONFIG set to k3s"
    fi

    echo "Run 'k9s' for a Kubernetes dashboard"
    echo ""
  '';
}
