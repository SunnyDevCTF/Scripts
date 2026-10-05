#!/bin/bash

set -e

clear

echo "=========================================="
echo "       AUFGABE 4 - VLAN ROUTING"
echo "=========================================="
echo
echo "Dieses Script richtet einen Linux-Router"
echo "für zwei vorhandene VLANs ein."
echo
echo "Nicht festgelegte Werte werden abgefragt."
echo

# ==========================================
# VLANs
# ==========================================

while true; do
    read -rp "VLAN 1 ID: " VLAN1

    if [[ "$VLAN1" =~ ^[0-9]+$ ]] &&
       (( VLAN1 >= 1 && VLAN1 <= 4094 )); then
        break
    fi

    echo "Fehler: Ungültige VLAN-ID."
done

while true; do
    read -rp "VLAN 2 ID: " VLAN2

    if [[ "$VLAN2" =~ ^[0-9]+$ ]] &&
       (( VLAN2 >= 1 && VLAN2 <= 4094 )) &&
       [[ "$VLAN2" != "$VLAN1" ]]; then
        break
    fi

    echo "Fehler: Ungültige VLAN-ID oder VLAN bereits verwendet."
done


# ==========================================
# SWITCH PORTS
# ==========================================

while true; do
    read -rp "Switch-Port für VLAN 1 (z.B. 5): " PORT1

    if [[ "$PORT1" =~ ^[0-9]+$ ]] &&
       (( PORT1 >= 1 && PORT1 <= 48 )); then
        break
    fi

    echo "Fehler: Ungültiger Switch-Port."
done

while true; do
    read -rp "Switch-Port für VLAN 2 (z.B. 10): " PORT2

    if [[ "$PORT2" =~ ^[0-9]+$ ]] &&
       (( PORT2 >= 1 && PORT2 <= 48 )) &&
       [[ "$PORT2" != "$PORT1" ]]; then
        break
    fi

    echo "Fehler: Ungültiger Port oder Port bereits verwendet."
done


# ==========================================
# ROUTER INTERFACES
# ==========================================

echo
echo "Verfügbare Netzwerkinterfaces:"
ip -br link
echo

read -rp "Router-Interface für VLAN 1 [enp2s0]: " IF1
IF1=${IF1:-enp2s0}

if ! ip link show "$IF1" >/dev/null 2>&1; then
    echo "Fehler: Interface '$IF1' existiert nicht."
    exit 1
fi

while true; do
    read -rp "Router-Interface für VLAN 2: " IF2

    if ip link show "$IF2" >/dev/null 2>&1 &&
       [[ "$IF2" != "$IF1" ]]; then
        break
    fi

    echo "Fehler: Interface existiert nicht oder wird bereits für VLAN 1 verwendet."
done


# ==========================================
# NETWORKS
# ==========================================

while true; do
    read -rp "IPv4-Netz VLAN 1 (z.B. 192.168.10.0/24): " NET1

    if [[ "$NET1" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/24$ ]]; then
        break
    fi

    echo "Fehler: Verwende ein /24-Netz."
done

while true; do
    read -rp "IPv4-Netz VLAN 2 (z.B. 192.168.20.0/24): " NET2

    if [[ "$NET2" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/24$ ]] &&
       [[ "$NET2" != "$NET1" ]]; then
        break
    fi

    echo "Fehler: Ungültiges oder bereits verwendetes Netzwerk."
done


# ==========================================
# ROUTER IPs
# ==========================================

echo
echo "Jetzt werden die IP-Adressen des Routers"
echo "in den beiden VLANs festgelegt."
echo

read -rp "Router-IP VLAN 1 (z.B. 192.168.10.1): " ROUTER_IP1
read -rp "Router-IP VLAN 2 (z.B. 192.168.20.1): " ROUTER_IP2


# ==========================================
# HOST IPS
# ==========================================

echo
echo "Beispiel-Host-Adressen für den Test."
echo "Diese werden NICHT automatisch gesetzt."
echo

read -rp "Host-IP VLAN 1 (z.B. 192.168.10.10): " HOST_IP1
read -rp "Host-IP VLAN 2 (z.B. 192.168.20.10): " HOST_IP2


# ==========================================
# NAT
# ==========================================

echo
read -rp "Soll NAT aktiviert werden? [J/n]: " NAT

if [[ "$NAT" =~ ^[Nn]$ ]]; then
    NAT_ENABLED="Nein"
else
    NAT_ENABLED="Ja"
fi


# ==========================================
# CONFIGURATION SUMMARY
# ==========================================

clear

echo "=========================================="
echo "          KONFIGURATION"
echo "=========================================="
echo
echo "VLAN 1:"
echo "  VLAN-ID:       $VLAN1"
echo "  Switch-Port:   Fa0/$PORT1"
echo "  Interface:     $IF1"
echo "  Netzwerk:      $NET1"
echo "  Router-IP:     $ROUTER_IP1"
echo "  Host-Test-IP:  $HOST_IP1"
echo
echo "VLAN 2:"
echo "  VLAN-ID:       $VLAN2"
echo "  Switch-Port:   Fa0/$PORT2"
echo "  Interface:     $IF2"
echo "  Netzwerk:      $NET2"
echo "  Router-IP:     $ROUTER_IP2"
echo "  Host-Test-IP:  $HOST_IP2"
echo
echo "NAT:             $NAT_ENABLED"
echo

read -rp "Ist diese Konfiguration korrekt? [j/N]: " CONFIRM

if [[ ! "$CONFIRM" =~ ^[JjYy]$ ]]; then
    echo
    echo "Abgebrochen."
    exit 0
fi


# ==========================================
# CISCO CONFIG
# ==========================================

echo
echo "=========================================="
echo "        CISCO-KONFIGURATION"
echo "=========================================="
echo

cat <<EOF

enable
configure terminal

interface fastEthernet 0/$PORT1
 switchport mode access
 switchport access vlan $VLAN1
exit

interface fastEthernet 0/$PORT2
 switchport mode access
 switchport access vlan $VLAN2
exit

end
copy running-config startup-config

show vlan brief

EOF


# ==========================================
# LINUX ROUTER
# ==========================================

echo
echo "=========================================="
echo "        LINUX ROUTER"
echo "=========================================="
echo

echo "Setze IP-Adressen..."

sudo ip addr add "$ROUTER_IP1/24" dev "$IF1"
sudo ip addr add "$ROUTER_IP2/24" dev "$IF2"

sudo ip link set "$IF1" up
sudo ip link set "$IF2" up

echo
echo "Aktiviere IP-Forwarding..."

sudo sysctl -w net.ipv4.ip_forward=1


# ==========================================
# NAT
# ==========================================

if [[ "$NAT_ENABLED" == "Ja" ]]; then

    echo
    echo "=========================================="
    echo "             NAT"
    echo "=========================================="
    echo

    echo "Aktiviere NAT zwischen den VLANs..."

    sudo iptables -t nat -A POSTROUTING \
        -s "$NET1" \
        -d "$NET2" \
        -j MASQUERADE

    sudo iptables -t nat -A POSTROUTING \
        -s "$NET2" \
        -d "$NET1" \
        -j MASQUERADE

fi


# ==========================================
# ROUTES
# ==========================================

echo
echo "=========================================="
echo "             ROUTING"
echo "=========================================="
echo

echo "Routing-Tabelle:"
ip route


# ==========================================
# RESULT
# ==========================================

echo
echo "=========================================="
echo "              FERTIG"
echo "=========================================="
echo

echo "Router:"
echo "  $IF1 -> $ROUTER_IP1"
echo "  $IF2 -> $ROUTER_IP2"
echo

echo "IP-Forwarding:"
echo "  aktiviert"
echo

echo "Jetzt müssen die Hosts konfiguriert werden:"
echo
echo "VLAN 1:"
echo "  IP:       $HOST_IP1"
echo "  Gateway:  $ROUTER_IP1"
echo
echo "VLAN 2:"
echo "  IP:       $HOST_IP2"
echo "  Gateway:  $ROUTER_IP2"
echo

echo "Test:"
echo "  VLAN 1 -> ping $HOST_IP2"
echo "  VLAN 2 -> ping $HOST_IP1"
echo
