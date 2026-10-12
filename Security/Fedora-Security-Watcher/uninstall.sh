#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Bitte ausführen: sudo ./uninstall.sh"
    exit 1
fi

systemctl disable --now security-control.service 2>/dev/null || true

rm -f /etc/systemd/system/security-control.service
systemctl daemon-reload
systemctl reset-failed security-control.service 2>/dev/null || true

rm -rf /opt/security-control

echo "Security Control wurde deinstalliert."
echo "Logs und Fotos bleiben unter /var/log/security-control erhalten."