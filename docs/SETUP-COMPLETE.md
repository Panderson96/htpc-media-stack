# HTPC Media Stack - Setup Complete

This document contains all the configuration details for your running media stack.

## Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| k3s Cluster | Running | Node: `gort` |
| FluxCD | Syncing | GitOps from GitHub |
| Gluetun VPN | Connected | ProtonVPN (Netherlands) |
| Transmission | Running | Torrent client via VPN |
| Prowlarr | Configured | 3 indexers + FlareSolverr |
| Sonarr | Configured | TV automation |
| Radarr | Configured | Movie automation |
| Jellyfin | Running | Media streaming |
| Jellyseerr | Running | Request management |
| FlareSolverr | Running | Cloudflare bypass |

---

## Access URLs (Port Forwarding)

For testing, run port-forwards:
```bash
cd /home/swig/workspace/htpc-media-stack
nix develop --command bash -c '
kubectl port-forward -n media svc/jellyfin 8096:8096 --address 0.0.0.0 &
kubectl port-forward -n media svc/sonarr 8989:8989 --address 0.0.0.0 &
kubectl port-forward -n media svc/radarr 7878:7878 --address 0.0.0.0 &
kubectl port-forward -n media svc/prowlarr 9696:9696 --address 0.0.0.0 &
kubectl port-forward -n media svc/jellyseerr 5055:5055 --address 0.0.0.0 &
kubectl port-forward -n downloads svc/transmission 9091:9091 --address 0.0.0.0 &
wait
'
```

| Service | URL |
|---------|-----|
| Jellyfin | http://localhost:8096 |
| Sonarr | http://localhost:8989 |
| Radarr | http://localhost:7878 |
| Prowlarr | http://localhost:9696 |
| Jellyseerr | http://localhost:5055 |
| Transmission | http://localhost:9091 |

---

## API Keys

| Service | API Key |
|---------|---------|
| Prowlarr | `b19d0bd1806b45eab740ba5829c119e0` |
| Sonarr | `90a00b9e090b4f0f803fd3fb1298faa0` |
| Radarr | `6a16b3b4b8da4dcaa522d49b27fd2f16` |

---

## Service Configuration

### Prowlarr (Indexer Manager)
- **Indexers Configured:**
  - 1337x (with FlareSolverr)
  - The Pirate Bay
  - YTS
- **Apps Connected:**
  - Sonarr
  - Radarr
- **FlareSolverr URL:** `http://flaresolverr.media.svc.cluster.local:8191`

### Sonarr (TV Shows)
- **Root Folder:** `/tv`
- **Download Client:** Transmission
  - Host: `transmission.downloads.svc.cluster.local`
  - Port: `9091`
  - Category: `tv-sonarr`
- **Indexers:** Synced from Prowlarr

### Radarr (Movies)
- **Root Folder:** `/movies`
- **Download Client:** Transmission
  - Host: `transmission.downloads.svc.cluster.local`
  - Port: `9091`
  - Category: `movies-radarr`
- **Indexers:** Synced from Prowlarr

### Transmission (Torrent Client)
- **Runs through VPN** (Gluetun/ProtonVPN)
- **Web UI:** Port 9091
- **Download Path:** `/downloads`

### Jellyfin (Media Server)
- **Server ID:** `a8404cef895c4c56959264136d768aaa`
- **Libraries:**
  - Movies: `/data/movies`
  - TV Shows: `/data/tv`

### Jellyseerr (Request Management)
**Manual Configuration Required via Web UI (http://localhost:5055):**

1. Go to **Settings > Services**
2. Add **Radarr:**
   - Hostname: `radarr.media.svc.cluster.local`
   - Port: `7878`
   - API Key: `6a16b3b4b8da4dcaa522d49b27fd2f16`
   - Quality Profile: Select your preference
   - Root Folder: `/movies`
3. Add **Sonarr:**
   - Hostname: `sonarr.media.svc.cluster.local`
   - Port: `8989`
   - API Key: `90a00b9e090b4f0f803fd3fb1298faa0`
   - Quality Profile: Select your preference
   - Root Folder: `/tv`

---

## VPN Configuration

- **Provider:** ProtonVPN
- **Protocol:** OpenVPN
- **Server Country:** Netherlands
- **Credentials stored in:** `kubernetes/apps/downloads/gluetun/secret.yaml`

### Verify VPN Connection
```bash
kubectl logs -n downloads -l app=gluetun-transmission -c gluetun --tail=20 | grep -E "Initialization|Connected"
```

---

## Storage Paths

| Purpose | Host Path | Container Path |
|---------|-----------|----------------|
| App Configs | `/data/media/config/<app>` | `/config` |
| Downloads | `/data/media/downloads` | `/downloads` |
| Movies | `/data/media/library/movies` | `/movies` |
| TV Shows | `/data/media/library/tv` | `/tv` |

---

## Kubernetes Services (Internal DNS)

| Service | Internal DNS | Port |
|---------|--------------|------|
| Jellyfin | `jellyfin.media.svc.cluster.local` | 8096 |
| Sonarr | `sonarr.media.svc.cluster.local` | 8989 |
| Radarr | `radarr.media.svc.cluster.local` | 7878 |
| Prowlarr | `prowlarr.media.svc.cluster.local` | 9696 |
| Jellyseerr | `jellyseerr.media.svc.cluster.local` | 5055 |
| Transmission | `transmission.downloads.svc.cluster.local` | 9091 |
| FlareSolverr | `flaresolverr.media.svc.cluster.local` | 8191 |

---

## Ingress FQDNs (for future TLS setup)

| Service | FQDN |
|---------|------|
| Jellyfin | `jellyfin.media.local` |
| Sonarr | `sonarr.media.local` |
| Radarr | `radarr.media.local` |
| Prowlarr | `prowlarr.media.local` |
| Jellyseerr | `jellyseerr.media.local` |
| Transmission | `transmission.media.local` |

---

## Useful Commands

```bash
# Enter dev environment
cd /home/swig/workspace/htpc-media-stack
nix develop

# Check all pods
kubectl get pods -A

# Check Flux status
flux get all

# Force Flux sync
flux reconcile source git flux-system
flux reconcile kustomization flux-system

# Check VPN logs
kubectl logs -n downloads -l app=gluetun-transmission -c gluetun --tail=50

# Check specific app logs
kubectl logs -n media -l app=sonarr --tail=50

# Restart a deployment
kubectl rollout restart -n media deployment/jellyfin

# Port forward a single service
kubectl port-forward -n media svc/jellyfin 8096:8096
```

---

## TODO / Future Improvements

- [ ] Set up proper TLS with cert-manager + Let's Encrypt
- [ ] Configure local DNS (Pi-hole or similar)
- [ ] Add more indexers to Prowlarr
- [ ] Set up Tailscale for remote access
- [ ] Add Bazarr for subtitles
- [ ] Set up Prometheus/Grafana monitoring
- [ ] Configure automated backups

---

## Troubleshooting

### VPN Not Connecting
```bash
kubectl logs -n downloads -l app=gluetun-transmission -c gluetun --tail=100
```
Check credentials in `kubernetes/apps/downloads/gluetun/secret.yaml`

### Indexers Blocked by Cloudflare
FlareSolverr should handle this. Check logs:
```bash
kubectl logs -n media -l app=flaresolverr --tail=50
```

### Downloads Not Starting
1. Check Transmission is accessible
2. Verify VPN is connected
3. Check Sonarr/Radarr logs for errors

### Permissions Issues
```bash
sudo chown -R 1000:1000 /data/media
```
