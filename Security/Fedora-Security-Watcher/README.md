# Fedora Security Control

Ein Python-Projekt zur Überwachung ausgewählter fehlgeschlagener
Authentifizierungsereignisse unter Fedora Linux.

## Features

- Überwachung des systemd-Journals mit journalctl
- Erkennung bestimmter Authentifizierungsfehler
- Optionale Kamerafotos mit fswebcam
- Lokale Ereignisprotokollierung
- Automatischer Start über systemd
- Installer und Uninstaller für Fedora

## Installation

```bash
chmod +x install.sh uninstall.sh
sudo ./install.sh
```

Status überprüfen
```bash
sudo systemctl status security-control.service
```

Live-Logs
```bash
sudo journalctl -u security-control.service -f
```

Deinstallation
```bash
sudo ./uninstall.sh
```

> Hinweise
Die Erkennung hängt von den tatsächlich protokollierten
Journal-Meldungen ab. Nicht jeder fehlgeschlagene Login wird
zwingend erkannt.
Das Projekt ist ein Lernprototyp und keine vollständige
Intrusion-Detection-Lösung.
Nur auf eigenen oder ausdrücklich autorisierten Geräten verwenden.
Kamerafotos und Protokolle können personenbezogene Daten enthalten.

## 6. Installer ausführbar machen und testen

```bash
chmod +x install.sh uninstall.sh
```


Prüfe vor der Installation, ob dein Python-Skript vorhanden ist:
```bash
ls -l src/security_watcher.py
```

Dann installiere:
```bash
sudo ./install.sh
```