{
  description = "HTPC Media Stack - k3s + FluxCD GitOps";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          name = "htpc-media-stack";

          buildInputs = with pkgs; [
            # Kubernetes tools
            kubectl          # Kubernetes CLI
            kubernetes-helm  # Helm package manager
            kustomize        # Kubernetes manifest customization
            k9s              # Kubernetes TUI dashboard
            stern            # Multi-pod log tailing
            kubectx          # Context/namespace switcher

            # GitOps
            fluxcd           # FluxCD CLI

            # Container tools
            docker-client    # Docker CLI (if needed)

            # Utilities
            jq               # JSON processor
            yq-go            # YAML processor
            age              # Encryption for SOPS
            sops             # Secrets management

            # Development
            git
            gh               # GitHub CLI
            curl
            wget
          ];

          shellHook = ''
            echo "🎬 HTPC Media Stack Development Environment"
            echo ""
            echo "Available tools:"
            echo "  kubectl     - Kubernetes CLI"
            echo "  flux        - FluxCD CLI"
            echo "  helm        - Helm package manager"
            echo "  kustomize   - Manifest customization"
            echo "  k9s         - Kubernetes TUI"
            echo "  stern       - Multi-pod log tailing"
            echo "  sops/age    - Secrets encryption"
            echo ""

            # Set KUBECONFIG if k3s is installed
            if [ -f /etc/rancher/k3s/k3s.yaml ]; then
              export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
              echo "✓ KUBECONFIG set to k3s"
            fi

            echo "Quick commands:"
            echo "  k9s                    - Open Kubernetes dashboard"
            echo "  flux get all           - Check FluxCD status"
            echo "  kubectl get pods -A    - List all pods"
            echo ""
          '';
        };

        # For systems without flakes, provide a package set
        packages.default = pkgs.buildEnv {
          name = "htpc-media-stack-tools";
          paths = with pkgs; [
            kubectl
            kubernetes-helm
            kustomize
            k9s
            fluxcd
            jq
            yq-go
          ];
        };
      }
    );
}
