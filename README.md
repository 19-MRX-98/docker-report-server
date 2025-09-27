# Static Mountpoint Viewer

Ein einfaches Tool zur Anzeige und Verwaltung von statischen Mountpoints.

## Features

- Übersichtliche Darstellung von Mountpoints
- Ausgabe der Informationen in einer Datei
- Unterstützung verschiedener Dateisysteme

## Installation

```bash
cd /var
git clone https://github.com/dein-benutzer/static-mountpoint-viewer.git
cd static-mountpoint-viewer
docker compose up -d
```

## Nutzung

Der Container startet sich automatisch und kann via Port 8080 erreicht werden. Dieser Port kann auch für die Integration in andere Projekte benutzt werden.
Zusätzlich wird die Ausgabe wird in einer Datei gespeichert unter /outputs.

## Nutzung in meinem Wetterstationsprojekt
Dieser Container wird für die Überwachung der Hosts in meinem Wetterstationsprojekt die Aufgaben der Systemüberwachung übernehmen

## Konfiguration

- Keine Konfiguration nötig

## Mitwirken

Pull Requests und Issues sind willkommen!

## Lizenz

Dieses Projekt steht unter der MIT-Lizenz.