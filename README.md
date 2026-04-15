# Self-Hosted Infrastructure Documentation

## Overview

This document describes my personal self-hosted infrastructure running on a Proxmox hypervisor. The architecture consists of multiple isolated virtual machines: one dedicated to Docker services (documented here), and several others hosting development projects.

---

## Network Architecture and Isolation

### Multi-Layer Isolation Strategy

The infrastructure implements a defense-in-depth approach with isolation at multiple levels:

```
Internet
    |
   NAT
    |
[Proxmox Hypervisor]
    |
    +-- [Docker Services VM] -- Internal Docker Network
    |
    +-- [Dev VM 1] -- Isolated
    +-- [Dev VM 2] -- Isolated
    +-- [Dev VM 3] -- Isolated
    +-- [Dev VM 4] -- Isolated
    +-- [Dev VM 5] -- Isolated
    +-- [Dev VM 6] -- Isolated
```

### VM-Level Isolation

- **NAT networking** : All VMs operate behind NAT, preventing direct external access
- **Separate network segments** : Each VM has its own isolated network space
- **Inter-VM communication** : Controlled through internal DNS resolution only
- **No direct internet exposure** : All external traffic goes through the reverse proxy

### Docker Network Isolation

Within the Docker Services VM, containers are organized into isolated networks:

| Network | Purpose | Access Level |
|---------|---------|--------------|
| `shared-net` | Main service communication | Internal only |
| `monitoring` | Metrics collection stack | Isolated from other services |

Services communicate exclusively through Docker's internal DNS resolution using container names. This means:
- No service is directly exposed to the host network
- Inter-service communication happens on private Docker networks
- Only the reverse proxy has external-facing ports (80/443)

### Internal DNS (CoreDNS)

A local DNS server handles internal name resolution across the infrastructure:
- VM hostname resolution (docker.host, dev1.host, etc.)
- Forward resolution to Cloudflare (1.1.1.1) for external domains
- Enables service discovery without hardcoded IPs

---

## Backup Strategy

All VMs are automatically backed up with a grandfather-father-son rotation scheme:

| Frequency | Retention |
|-----------|-----------|
| Daily | 7 days |
| Weekly | 1 month |
| Monthly | 1 year |
| Yearly | Permanent |

---

## Deployed Services

All services are containerized with Docker Compose and communicate through the internal Docker network.

### Reverse Proxy and Security

| Service | Description |
|---------|-------------|
| **Nginx Proxy Manager** | Reverse proxy with automatic SSL certificate management (Let's Encrypt) |
| **Fail2Ban** | Intrusion prevention system monitoring proxy logs |
| **Vaultwarden** | Self-hosted Bitwarden-compatible password manager |
| **WireGuard Easy** | VPN server with web management interface |

### Monitoring and Observability

| Service | Description |
|---------|-------------|
| **Netdata** | Real-time system and container monitoring |
| **Uptime Kuma** | Service availability monitoring with alerting |
| **Speedtest Tracker** | Network performance tracking (hourly tests) |

### Personal Cloud

| Service | Description |
|---------|-------------|
| **Nextcloud** | Personal cloud storage and collaboration platform |
| **MariaDB** | Database backend for Nextcloud |
| **Linkwarden** | Collaborative bookmark manager |
| **PostgreSQL** | Database backend for Linkwarden |

### Media Center

| Service | Description |
|---------|-------------|
| **Jellyfin** | Media streaming server |
| **Jellyseerr** | Media request management interface |
| **Radarr** | Movie collection manager |
| **Sonarr** | TV series collection manager |
| **Prowlarr** | Indexer manager for Radarr/Sonarr |
| **qBittorrent VPN** | Torrent client with built-in VPN tunnel |

### Management and Administration

| Service | Description |
|---------|-------------|
| **Portainer** | Docker management web interface |
| **Homepage** | Unified dashboard for all services |
| **Watchtower** | Automatic container updates (hourly checks) |
| **CoreDNS** | Internal DNS server |

---

## Storage Architecture

### Mount Points

| Path | Purpose |
|------|---------|
| `/home/docker/` | Container configurations and compose files |
| `/mnt/docker-data/` | Persistent application data |
| `/mnt/media/` | Media library (movies, TV shows) |

### Named Docker Volumes

Stateful services use dedicated Docker volumes for data persistence, ensuring data survives container recreation.

---

## Security Measures

### Network Security

- **NAT isolation** : All VMs are isolated from direct internet access
- **Docker network segmentation** : Services grouped by function on separate networks
- **Single entry point** : Only the reverse proxy accepts external connections
- **VPN access** : WireGuard for secure remote administration

### Application Security

- **Fail2Ban** : Automatic IP banning on repeated failed authentication
- **SSL/TLS** : All public-facing services use Let's Encrypt certificates
- **Vaultwarden** : Centralized credential management

---

## Maintenance

### Automatic Updates

Watchtower monitors all containers and applies updates automatically every hour, with cleanup of unused images.

### Restart Policy

All containers are configured with `restart: unless-stopped` to ensure service continuity after host reboots or container crashes.