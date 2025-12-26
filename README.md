# HTPC Media Stack - k3s + FluxCD GitOps

A production-grade, GitOps-managed home theater media server running on k3s.

## Stack Components

| Service | Port | Purpose |
|---------|------|---------|
| **Jellyfin** | 8096 | Media streaming server |
| **Sonarr** | 8989 | TV show automation |
| **Radarr** | 7878 | Movie automation |
| **Prowlarr** | 9696 | Indexer management |
| **qBittorrent** | 8080 | Torrent client (via VPN) |
| **Jellyseerr** | 5055 | Request management UI |
| **Gluetun** | - | ProtonVPN container |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        k3s Cluster                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │  Jellyfin   │  │  Jellyseerr │  │ Prowlarr            │  │
│  │  (streaming)│  │  (requests) │  │ (indexers)          │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
│         │                │                    │             │
│         ▼                ▼                    ▼             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Sonarr    │  │   Radarr    │  │ Gluetun + qBit      │  │
│  │   (TV)      │  │  (Movies)   │  │ (VPN + Downloads)   │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
│         │                │                    │             │
│         └────────────────┴────────────────────┘             │
│                          │                                  │
│                    ┌─────▼─────┐                            │
│                    │  /data/   │                            │
│                    │  media/   │                            │
│                    └───────────┘                            │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Ubuntu 22.04+ (or similar Linux)
- 4GB+ RAM (8GB recommended)
- GitHub account (for GitOps)
- ProtonVPN account (for VPN)

## Quick Start

### Option A: Automated Setup (Recommended)

```bash
cd htpc-media-stack
./bootstrap/setup.sh
```

This handles Nix installation, environment setup, and guides you through the rest.

### Option B: Manual Setup

#### 1. Install Nix (Package Manager)

```bash
./bootstrap/install-nix.sh
# Restart your shell, then:
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

#### 2. Enter Development Environment

```bash
# Using Nix flakes (recommended)
nix develop

# Or with direnv (auto-loads on cd)
nix profile install nixpkgs#direnv
echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
source ~/.bashrc
direnv allow
```

This gives you: `kubectl`, `flux`, `helm`, `kustomize`, `k9s`, `sops`, `age`, and more.

#### 3. Install k3s

```bash
./bootstrap/install-k3s.sh
```

#### 4. Create Data Directories

```bash
sudo mkdir -p /data/media/{config,downloads,library/{movies,tv}}
sudo chown -R 1000:1000 /data/media
```

#### 5. Update VPN Credentials

Edit `kubernetes/apps/downloads/gluetun/secret.yaml` with your ProtonVPN OpenVPN credentials.

> Get credentials from: https://account.protonvpn.com/account (OpenVPN/IKEv2 section)

#### 6. Push to GitHub

```bash
git init
git add .
git commit -m "Initial HTPC media stack"
git remote add origin git@github.com:YOUR_USERNAME/htpc-media-stack.git
git push -u origin main
```

#### 7. Bootstrap FluxCD

```bash
export GITHUB_USER="your-username"
./bootstrap/flux-bootstrap.sh
```

### Configure Local DNS

Add to `/etc/hosts` on machines accessing the services:

```
192.168.x.x  jellyfin.local sonarr.local radarr.local prowlarr.local qbit.local requests.local
```

Replace `192.168.x.x` with your Beelink's IP address.

## Accessing Services

| Service | URL |
|---------|-----|
| Jellyfin | http://jellyfin.local:80 |
| Sonarr | http://sonarr.local:80 |
| Radarr | http://radarr.local:80 |
| Prowlarr | http://prowlarr.local:80 |
| qBittorrent | http://qbit.local:80 |
| Jellyseerr | http://requests.local:80 |

**Or via IP (NodePort):**
- Jellyfin: `http://<IP>:8096`
- etc.

## Initial Configuration

### 1. qBittorrent
- Default login: `admin` / check container logs for password
- Settings → Downloads → Default Save Path: `/downloads`
- Settings → Downloads → Keep incomplete in: `/downloads/incomplete`

### 2. Prowlarr
- Add indexers (1337x, RARBG, etc.)
- Settings → Apps → Add Sonarr/Radarr

### 3. Radarr
- Settings → Media Management → Root Folder: `/movies`
- Settings → Download Clients → Add qBittorrent (host: `qbittorrent.downloads.svc.cluster.local`)
- Settings → Indexers → Add from Prowlarr

### 4. Sonarr
- Settings → Media Management → Root Folder: `/tv`
- Settings → Download Clients → Add qBittorrent
- Settings → Indexers → Add from Prowlarr

### 5. Jellyfin
- Add library → Movies → `/data/movies`
- Add library → TV Shows → `/data/tv`

### 6. Jellyseerr
- Connect to Jellyfin
- Connect to Sonarr/Radarr

## GitOps Workflow

All changes are made via Git:

```bash
# Make changes to manifests
vim kubernetes/apps/media/jellyfin/deployment.yaml

# Commit and push
git add .
git commit -m "Update Jellyfin resources"
git push

# FluxCD automatically applies changes
flux reconcile source git flux-system
```

## Useful Commands

```bash
# View all pods
kubectl get pods -A

# Check Flux status
flux get all

# Force reconciliation
flux reconcile source git flux-system

# View logs
kubectl logs -n media deployment/jellyfin -f

# Check VPN connection
kubectl exec -n downloads deployment/gluetun-qbittorrent -c gluetun -- wget -qO- https://ipinfo.io

# Restart a deployment
kubectl rollout restart -n media deployment/jellyfin
```

## Storage Configuration

Default paths (update in manifests when mounting external drive):

| Type | Path |
|------|------|
| App Configs | `/data/media/config/<app>` |
| Downloads | `/data/media/downloads` |
| Movies | `/data/media/library/movies` |
| TV Shows | `/data/media/library/tv` |

To use external drive, update `hostPath` in all deployment manifests from `/data/media` to your mount point (e.g., `/mnt/media`).

## Troubleshooting

### VPN Not Connecting
```bash
kubectl logs -n downloads deployment/gluetun-qbittorrent -c gluetun
```

### Services Not Accessible
```bash
# Check ingress
kubectl get ingress -A

# Check Traefik
kubectl logs -n kube-system deployment/traefik
```

### Pods Not Starting
```bash
kubectl describe pod -n media <pod-name>
kubectl get events -n media --sort-by='.lastTimestamp'
```

## Future Enhancements

- [ ] Add Tailscale for remote access
- [ ] Add SOPS/sealed-secrets for encrypted credentials
- [ ] Add Renovate for automated image updates
- [ ] Add Prometheus/Grafana for monitoring
- [ ] Add Bazarr for subtitles
- [ ] Mount 8TB external SSD

## Directory Structure

```
htpc-media-stack/
├── flake.nix              # Nix flake (dev dependencies)
├── shell.nix              # Fallback for non-flake Nix
├── .envrc                 # direnv auto-load config
├── .gitignore
├── README.md
├── bootstrap/
│   ├── install-nix.sh     # Nix package manager install
│   ├── install-k3s.sh     # k3s installation
│   ├── flux-bootstrap.sh  # FluxCD setup
│   └── setup.sh           # All-in-one setup script
├── kubernetes/
│   ├── kustomization.yaml
│   ├── flux-system/
│   ├── infrastructure/
│   │   ├── kustomization.yaml
│   │   └── storage/local-path/
│   └── apps/
│       ├── kustomization.yaml
│       ├── downloads/
│       │   ├── gluetun/
│       │   └── qbittorrent/
│       └── media/
│           ├── jellyfin/
│           ├── sonarr/
│           ├── radarr/
│           ├── prowlarr/
│           └── jellyseerr/
└── scripts/
```

## Nix Development Environment

The flake provides all required tools:

| Tool | Purpose |
|------|---------|
| `kubectl` | Kubernetes CLI |
| `flux` | FluxCD CLI |
| `helm` | Helm package manager |
| `kustomize` | Manifest customization |
| `k9s` | Kubernetes TUI dashboard |
| `stern` | Multi-pod log tailing |
| `sops` + `age` | Secrets encryption |

Enter the environment with:
```bash
nix develop    # or just cd into the folder with direnv
```

## License

MIT
