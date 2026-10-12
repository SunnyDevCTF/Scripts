#!/usr/bin/env bash
set -euo pipefail

APP="security-control"
SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/$APP"
LOG_DIR="/var/log/$APP"
SERVICE="security-control.service"

if [[ $EUID -ne 0 ]]; then
    echo "Bitte ausführen: sudo ./install.sh"
    exit 1
fi

if [[ ! -f "$SOURCE_DIR/src/security_watcher.py" ]]; then
    echo "Fehler: src/security_watcher.py wurde nicht gefunden."
    exit 1
fi

echo "Fedora Security Control"
echo "Überwacht fehlgeschlagene Authentifizierungen."
echo "Verwende das Programm nur auf autorisierten Geräten."
read -r -p "Installation fortsetzen? [j/N] " answer

if [[ ! "$answer" =~ ^[jJyY]$ ]]; then
    echo "Installation abgebrochen."
    exit 0
fi

dnf install -y fswebcam

install -d -m 0750 "$INSTALL_DIR"
install -d -m 0700 "$LOG_DIR/images"

install -m 0750 \
    "$SOURCE_DIR/src/security_watcher.py" \
    "$INSTALL_DIR/security_watcher.py"

cat > "/etc/systemd/system/$SERVICE" <<EOF
[Unit]
Description=Security Control Authentication Monitor
After=systemd-journald.service

[Service]
Type=simple
User=root
UMask=0077
ExecStart=/usr/bin/python3 $INSTALL_DIR/security_watcher.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now "$SERVICE"

echo
echo "Installation abgeschlossen."
echo
echo "Status:"
echo "  sudo systemctl status $SERVICE"
echo
echo "Live-Logs:"
echo "  sudo journalctl -u $SERVICE -f"
echo
echo "Gespeicherte Ereignisse:"
echo "  sudo cat $LOG_DIR/events.log"
echo
echo "Kamerabilder:"
echo "  sudo ls -lah $LOG_DIR/images/"