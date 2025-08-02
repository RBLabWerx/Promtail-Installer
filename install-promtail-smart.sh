# install-promtail-smart.sh
# Public version — safe for sharing
#
# ⚠️ EDIT DEFAULT_LOKI_URL or use CLI args when running
# Usage:
#   sudo ./install-promtail-smart.sh --host <hostname> --job <job> --env <env> --loki-url <url> --journal

#!/bin/bash

set -e

### === Default values === ###
DEFAULT_LOKI_URL="http://your-loki-server:3100"
DEFAULT_JOB="default-job"
DEFAULT_ENV="default-env"
DEFAULT_HOSTNAME=$(hostname)
DEFAULT_USE_JOURNAL="false"

### === Parse args with fallbacks === ###
while [[ $# -gt 0 ]]; do
  case $1 in
    --loki-url)
      LOKI_URL="$2"
      shift 2
      ;;
    --job)
      JOB="$2"
      shift 2
      ;;
    --env)
      ENV="$2"
      shift 2
      ;;
    --host)
      HOSTNAME="$2"
      shift 2
      ;;
    --journal)
      USE_JOURNAL="true"
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--loki-url <url>] [--job <job>] [--env <env>] [--host <name>] [--journal]"
      exit 1
      ;;
  esac
done

### === Prompt for missing values === ###
read -r -p "Enter Loki URL [$DEFAULT_LOKI_URL]: " INPUT
LOKI_URL="${LOKI_URL:-${INPUT:-$DEFAULT_LOKI_URL}}"

read -r -p "Enter host label [$DEFAULT_HOSTNAME]: " INPUT
HOSTNAME="${HOSTNAME:-${INPUT:-$DEFAULT_HOSTNAME}}"

read -r -p "Enter job name [$DEFAULT_JOB]: " INPUT
JOB="${JOB:-${INPUT:-$DEFAULT_JOB}}"

read -r -p "Enter environment label [$DEFAULT_ENV]: " INPUT
ENV="${ENV:-${INPUT:-$DEFAULT_ENV}}"

if [[ -z "$USE_JOURNAL" || "$USE_JOURNAL" == "false" ]]; then
  read -r -p "Enable journal scraping? (y/N): " INPUT
  [[ "$INPUT" =~ ^[Yy]$ ]] && USE_JOURNAL="true" || USE_JOURNAL="false"
fi

### === Install config === ###
INSTALL_DIR="/opt"
PROMTAIL_BIN="$INSTALL_DIR/promtail"
CONFIG_FILE="$INSTALL_DIR/promtail-config.yml"
POSITION_FILE="$INSTALL_DIR/positions.yaml"
SERVICE_FILE="/etc/systemd/system/promtail.service"

echo "[*] Installing Promtail for host: $HOSTNAME, job: $JOB, env: $ENV"

### === Download Promtail === ###
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
curl -sLO https://github.com/grafana/loki/releases/latest/download/promtail-linux-amd64.zip
unzip -o promtail-linux-amd64.zip
mv promtail-linux-amd64 promtail
chmod +x promtail

### === Create config file === ###
cat > "$CONFIG_FILE" <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: $POSITION_FILE

clients:
  - url: $LOKI_URL/loki/api/v1/push

scrape_configs:
  - job_name: $JOB
    static_configs:
      - targets:
          - localhost
        labels:
          job: $JOB
          host: $HOSTNAME
          env: $ENV
          __path__: /var/log/*.log
EOF

if [[ "$USE_JOURNAL" == "true" ]]; then
cat >> "$CONFIG_FILE" <<EOF

  - job_name: journal
    journal:
      max_age: 12h
      path: /var/log/journal
      labels:
        job: journal
        host: $HOSTNAME
        env: $ENV
    relabel_configs:
      - source_labels: ['__journal__systemd_unit']
        target_label: 'unit'
EOF
fi

### === Create systemd service === ###
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Promtail log shipper for Loki
After=network.target

[Service]
ExecStart=$PROMTAIL_BIN -config.file=$CONFIG_FILE
Restart=always

[Install]
WantedBy=multi-user.target
EOF

### === Start service === ###
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable promtail
systemctl restart promtail

echo -e "\n[✓] Promtail is now running."
echo "[→] Logs are being sent to: $LOKI_URL"
echo "[🔖] Labels: job=$JOB, host=$HOSTNAME, env=$ENV"
[[ "$USE_JOURNAL" == "true" ]] && echo "[📘] Systemd journal scraping is ENABLED"
