#!/bin/bash

set -e

clear

echo "=========================================="
echo "       Cisco VLAN + Debian DHCP"
echo "=========================================="
echo

# -----------------------------
# Eingaben
# wichtig, den dhcp server rechner, auf dem das skript gestartet werden soll, muss eine statische ip von anfang an haben
# -----------------------------

while true; do
    read -rp "VLAN-ID (z.B. 110): " VLAN_ID

    if [[ "$VLAN_ID" =~ ^[0-9]+$ ]] && (( VLAN_ID >= 2 && VLAN_ID <= 4094 )); then
        break
    fi

    echo "Fehler: VLAN-ID muss zwischen 2 und 4094 liegen."
done

while true; do
    read -rp "Erster Switch-Port (z.B. 5): " PORT1

    if [[ "$PORT1" =~ ^[0-9]+$ ]] && (( PORT1 >= 1 && PORT1 <= 48 )); then
        break
    fi

    echo "Fehler: Ungültiger Port."
done

while true; do
    read -rp "Zweiter Switch-Port (z.B. 8): " PORT2

    if [[ "$PORT2" =~ ^[0-9]+$ ]] && (( PORT2 >= 1 && PORT2 <= 48 )); then
        if [[ "$PORT1" != "$PORT2" ]]; then
            break
        fi
    fi

    echo "Fehler: Der zweite Port muss sich vom ersten unterscheiden."
done

while true; do
    read -rp "IPv4-Netzwerk (z.B. 192.168.110.0/24): " NETWORK

    if [[ "$NETWORK" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/([0-9]|[1-2][0-9]|3[0-2])$ ]]; then
        break
    fi

    echo "Fehler: Bitte CIDR-Format verwenden, z.B. 192.168.110.0/24"
done

read -rp "DHCP-Server-Interface (z.B. eth0): " INTERFACE

while true; do
    read -rp "DHCP-Startadresse (z.B. 192.168.110.100): " DHCP_START

    if [[ "$DHCP_START" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        break
    fi

    echo "Fehler: Ungültige IPv4-Adresse."
done

while true; do
    read -rp "DHCP-Endadresse (z.B. 192.168.110.200): " DHCP_END

    if [[ "$DHCP_END" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        break
    fi

    echo "Fehler: Ungültige IPv4-Adresse."
done

# -----------------------------
# Zusammenfassung
# -----------------------------

echo
echo "=========================================="
echo "             KONFIGURATION"
echo "=========================================="
echo
echo "VLAN-ID:        $VLAN_ID"
echo "Switch-Port 1:  $PORT1"
echo "Switch-Port 2:  $PORT2"
echo "IPv4-Netz:      $NETWORK"
echo "DHCP-Interface: $INTERFACE"
echo "DHCP-Bereich:   $DHCP_START - $DHCP_END"
echo

read -rp "Konfiguration erzeugen? [j/N]: " CONFIRM

if [[ ! "$CONFIRM" =~ ^[JjYy]$ ]]; then
    echo "Abgebrochen."
    exit 0
fi

# -----------------------------
# Cisco-Konfiguration
# -----------------------------

echo
echo "=========================================="
echo "          CISCO-KONFIGURATION"
echo "=========================================="
echo

cat <<EOF

enable
configure terminal

vlan $VLAN_ID
 name VLAN$VLAN_ID
exit

interface fastEthernet 0/$PORT1
 switchport mode access
 switchport access vlan $VLAN_ID
exit

interface fastEthernet 0/$PORT2
 switchport mode access
 switchport access vlan $VLAN_ID
exit

end
copy running-config startup-config

show vlan brief

EOF

# -----------------------------
# DHCP-Konfiguration
# -----------------------------

echo
echo "=========================================="
echo "          DHCP-KONFIGURATION"
echo "=========================================="
echo

cat <<EOF
sudo apt update
sudo apt install isc-dhcp-server
EOF

echo
echo "Datei: /etc/default/isc-dhcp-server"
echo
echo "INTERFACESv4=\"$INTERFACE\""
echo

echo "Datei: /etc/dhcp/dhcpd.conf"
echo

cat <<EOF
authoritative;

subnet ${NETWORK%/*} netmask 255.255.255.0 {
    range $DHCP_START $DHCP_END;
}
EOF

echo
echo "=========================================="
echo "             FERTIG"
echo "=========================================="
echo
echo "Cisco:"
echo "  VLAN $VLAN_ID wurde für Ports $PORT1 und $PORT2 vorbereitet."
echo
echo "Debian:"
echo "  DHCP-Interface: $INTERFACE"
echo "  DHCP-Bereich:   $DHCP_START - $DHCP_END"
echo
echo "Nach der DHCP-Konfiguration:"
echo
echo "  sudo systemctl restart isc-dhcp-server"
echo "  sudo systemctl status isc-dhcp-server"
echo
