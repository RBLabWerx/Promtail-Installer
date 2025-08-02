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
sudo bash ./install-promtail-smart.sh
```

### With arguments (no prompts):

```bash
sudo bash ./install-promtail-smart.sh --host **your-hostname** --job **your-job-name** --env **your-environment** --loki-url http://**your-loki-ip**:3100 --journal

```

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

## License

[MIT](LICENSE)
