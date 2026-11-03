#!/bin/bash

# Abbruch bei Fehlern
set -e

# Prüfen, ob das Skript als Root ausgeführt wird
if [ "$EUID" -ne 0 ]; then
  echo "Bitte als Root ausführen (sudo)."
  exit 1
fi

# --- KONFIGURATION ---
INTERFACE="enp1s0"
SERVER_IP="10.0.0.10"
NETMASK="255.255.255.0"
SUBNET="10.0.0.0"
ROUTER_IP="10.0.0.1"
DNS_SERVER="1.1.1.1, 8.8.8.8"

# DHCP-Bereich (Pool für deine 13 Rechner)
RANGE_START="10.0.0.100"
RANGE_END="10.0.0.150"
# ---------------------

echo "[1/5] Aktualisiere Paketquellen und installiere isc-dhcp-server..."
apt-get update
apt-get install -y isc-dhcp-server

echo "[2/5] Konfiguriere die Netzwerkschnittstelle ($INTERFACE)..."
sed -i "s/^INTERFACESv4=.*/INTERFACESv4=\"$INTERFACE\"/" /etc/default/isc-dhcp-server

echo "[3/5] Schreibe die DHCP-Konfigurationsdatei (/etc/dhcp/dhcpd.conf)..."
cat <<EOF > /etc/dhcp/dhcpd.conf
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet $SUBNET netmask $NETMASK {
  range $RANGE_START $RANGE_END;
  option routers $ROUTER_IP;
  option domain-name-servers $DNS_SERVER;
}
EOF

echo "[4/5] Setze die statische IP ($SERVER_IP) für die Schnittstelle $INTERFACE..."
if ! grep -q "iface $INTERFACE" /etc/network/interfaces; then
cat <<EOF >> /etc/network/interfaces

auto $INTERFACE
iface $INTERFACE inet static
    address $SERVER_IP
    netmask $NETMASK
EOF
    ip addr add $SERVER_IP/24 dev $INTERFACE || true
    ip link set dev $INTERFACE up || true
fi

echo "[5/5] Starte und aktiviere den DHCP-Dienst..."
systemctl restart isc-dhcp-server
systemctl enable isc-dhcp-server

echo "Fertig! Der DHCP-Server läuft auf $INTERFACE im 10er-Netz."
echo "Prüfe den Status mit: systemctl status isc-dhcp-server"
