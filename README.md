# Promtail Smart Installer

This is a shell-based Promtail installer for shipping logs to a remote Grafana Loki instance. Designed for quick use in Proxmox hosts, VMs, LXCs, and other Linux environments.

## Features
- Installs Promtail in `/opt`
- Prompts for or accepts:
  - Loki endpoint URL
  - Host label
  - Job name
  - Environment label
  - Optionally enables `journalctl` scraping
- Sets up Promtail as a systemd service

## Usage

### Basic (prompts interactively):
```bash
sudo ./install-promtail-smart.sh
```

### With arguments (no prompts):

```bash
sudo ./install-promtail-smart.sh \
  --host [Host Name] \
  --job [Job Name] \
  --env [Enviroment Name] \
  --loki-url http://[your-loki-server]:3100 \
  --journal
```
