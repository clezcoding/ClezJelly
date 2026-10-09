# 🎬 ClezJelly

> Jellyfin Media-Server mit automatisiertem Usenet-Streaming — ohne lokalen Speicher.
> Von Clemens, für Clemens.

```
                        _____ _          _      _ _       
                       / ____| |        | |    | | |      
                      | |    | | ___ ___| | ___| | |_   _ 
                      | |    | |/ _ \_  / |/ _ \ | | | | |
                      | |____| |  __// /| |  __/ | | |_| |
                       \_____|_|\___/___|_|\___|_|_|\__, |
                                                     __/ |
                                                    |___/ 
```

---

## Was ist das?

Ein kompletter, selbstgehosteter Media-Server-Stack für dein zweites MacBook M3 Pro. Du requestest Filme/Serien, der Stack lädt sie **nicht** herunter — stattdessen streamt er sie direkt aus dem Usenet auf deinen Samsung Tizen TV, mit einer schönen Jellyfin-Oberfläche.

**Dein Erlebnis am Sonntagabend:**

1. Samsung TV einschalten → Jellyfin öffnen
2. „How I Met Your Mother" oder „Bergdoktor" eintippen
3. In schöner Netflix-ähnlicher Oberfläche gelistet bekommen
4. Play drücken → nach 5–10 Sekunden Buffer streamt es

Keine lokale Platte, kein Festplatten-Management, keine zweistündigen Downloads.

---

## 🧩 Architektur

```
┌─────────────────────┐
│   Samsung Tizen TV  │
│   (Jellyfin App)    │
└──────────┬──────────┘
           │ LAN
           ▼
┌─────────────────────┐       ┌────────────────────┐
│  Jellyfin (nativ)   │◄──────│  Jellyseerr        │
│  Hardware-Transcode │       │  (Request UI)      │
│  via VideoToolbox   │       └─────────┬──────────┘
└──────────┬──────────┘                 │
           │ liest .strm                ▼
           │                   ┌────────────────────┐
           ▼                   │  Radarr + Sonarr   │
┌─────────────────────┐        │  (Automation)      │
│  AltMount           │◄───────┤                    │
│  WebDAV + SABnzbd   │        └────────┬───────────┘
│  Kompatibel-API     │                 │ API-Keys
└──────────┬──────────┘                 ▼
           │ NNTP                ┌──────────────────┐
           ▼                     │  Prowlarr        │
┌─────────────────────┐          │  (Indexer)       │
│  Eweka Usenet       │          └────────┬─────────┘
│  (NL, EU-schnell)   │                   │
└─────────────────────┘                   ▼
                                 ┌────────────────────┐
                                 │  NZBGeek + 2nd Idx │
                                 │  (DE+EN Suche)     │
                                 └────────────────────┘
```

### Datenfluss

1. **Request:** Du suchst HIMYM in Jellyseerr → Request an Sonarr
2. **Suche:** Sonarr fragt Prowlarr → NZBGeek + zweiter Indexer finden den besten deutschen Release
3. **Übergabe:** Sonarr schickt die NZB an AltMount (als SABnzbd-API-Call)
4. **Virtualisierung:** AltMount erzeugt sofort eine `.strm`-Datei in `/media/tv/HIMYM/...` → kein Download!
5. **Import:** Sonarr importiert → benennt um → triggert Jellyfin-Scan
6. **Playback:** Du drückst Play → Jellyfin öffnet die `.strm` → Stream kommt via WebDAV von AltMount → AltMount zieht die Usenet-Artikel on-demand von Eweka → ab zum TV

---

## 💰 Kosten

| Service | Monatlich |
|---|---|
| Eweka Classic (unlimited Usenet) | ~€9 |
| NZBGeek Standard (jährliche Zahlung) | ~€1 |
| Zweiter Indexer (DrunkenSlug / NZBPlanet / NZB.su) | ~€0–1 |
| **Monatlich gesamt** | **~€10–11** |
| **Hardware** | **€0** (MacBook hast du schon) |

Zum Vergleich: Netflix Standard = €13,99/Monat.

---

## 📋 Voraussetzungen

- **MacBook M3 Pro** mit macOS Sonoma oder neuer (hast du)
- **Samsung Tizen TV** mit installierter Jellyfin-App (hast du)
- **Mindestens 40 Mbit/s Internet** (hast du)
- **~5 GB freier Speicher** auf dem Mac (für Docker-Images und Config)
- **Homebrew** installiert (`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`)
- **Usenet-Provider-Account** → [Eweka](https://www.eweka.nl/) (NL, €9/Monat Classic)
- **NZBGeek-Account** → [nzbgeek.info](https://nzbgeek.info/) ($12/Jahr)
- **Zweiter Indexer** (empfohlen für DE-Content) → siehe [`docs/01-prerequisites.md`](docs/01-prerequisites.md). Es gibt keinen dedizierten DE-API-Indexer mehr; mehrere Allgemein-Indexer parallel ist die aktuelle Lösung.

---

## 🚀 Installation

### Schnellstart (automatisches Script)

```bash
cd ~/Desktop/ClezJelly
./install.sh
```

Das Script führt dich durch alle Schritte interaktiv.

### Manuelle Installation

Siehe die Guides im `docs/`-Ordner:

1. [`docs/01-prerequisites.md`](docs/01-prerequisites.md) — Was du vorher brauchst
2. [`docs/02-installation.md`](docs/02-installation.md) — Schritt-für-Schritt Installation
3. [`docs/03-configuration.md`](docs/03-configuration.md) — Alle Services konfigurieren
4. [`docs/04-german-content.md`](docs/04-german-content.md) — Deutsche Inhalte maximieren
5. [`docs/05-samsung-tv.md`](docs/05-samsung-tv.md) — Jellyfin auf dem TV einrichten
6. [`docs/06-troubleshooting.md`](docs/06-troubleshooting.md) — Wenn was schiefläuft

---

## 📂 Projektstruktur

```
ClezJelly/
├── README.md                    # Dieses Dokument
├── install.sh                   # Hauptinstallations-Skript (interaktiv)
├── docker-compose.yml           # Der komplette Service-Stack
├── .env.example                 # Vorlage für Credentials
├── .gitignore                   # Was NICHT in Git kommt
├── docs/                        # Detaillierte Anleitungen
├── scripts/                     # Hilfs-Skripte (start/stop/update)
└── config/                      # Service-Konfigurationen
    └── altmount/
        └── config.sample.yaml   # AltMount-Beispiel-Config
```

---

## 🔧 Service-Übersicht

| Service | Port | Zweck | Web-UI |
|---|---|---|---|
| **Jellyfin** (nativ) | 8096 | Media-Server, UI für TV | http://localhost:8096 |
| **AltMount** | 8080 | Usenet-Streaming via WebDAV | http://localhost:8080 |
| **Prowlarr** | 9696 | Indexer-Manager | http://localhost:9696 |
| **Radarr** | 7878 | Film-Automation | http://localhost:7878 |
| **Sonarr** | 8989 | Serien-Automation | http://localhost:8989 |
| **Jellyseerr** | 5055 | Request-UI | http://localhost:5055 |
| **Bazarr** | 6767 | Untertitel-Automation | http://localhost:6767 |

---

## ⚡ Quick Commands

```bash
# Stack starten
./scripts/start-stack.sh

# Stack stoppen
./scripts/stop-stack.sh

# Alle Container-Logs sehen
docker compose logs -f

# Nur AltMount-Logs
docker compose logs -f altmount

# Stack updaten (neueste Images)
./scripts/update-stack.sh

# Container-Status
docker compose ps
```

---

## 🛡️ Sicherheit & Legal

**Was dieses Setup macht:**
- Streamt Usenet-Inhalte über verschlüsselte TLS/SSL-NNTP-Verbindung (Port 563)
- Keine Peer-to-Peer-Verbindungen (anders als Torrents) → deine IP erscheint in keinem Swarm
- Alle Verbindungen gehen zu deinem Usenet-Provider, der die SSL-Entschlüsselung macht

**Rechtlicher Hinweis:**
In Österreich fällt das Streamen oder Herunterladen urheberrechtlich geschützter Werke ohne Lizenz unter § 42 UrhG. Dieses Setup ist technisch neutral — nutze es ausschließlich für Inhalte, zu deren Nutzung du berechtigt bist (eigene Rips, Public-Domain, Creative-Commons etc.). Die Projektmaintainer übernehmen keine Verantwortung für Fehlgebrauch.

**Praktische Sicherheits-Checks:**
- ✅ Jellyfin **nicht öffentlich ins Internet** stellen — nutze Tailscale für Remote-Zugriff
- ✅ Starke Passwörter für Jellyfin, Jellyseerr und AltMount
- ✅ TLS/SSL beim Usenet-Provider zwingend aktivieren
- ✅ MacBook mit FileVault verschlüsselt halten
- ❌ Keine Portfreigaben im Router für diese Services

---

## 🧪 Status Dashboard

Nach dem Setup kannst du den Zustand des Stacks überprüfen:

```bash
./scripts/health-check.sh
```

Zeigt an:
- ✅ / ❌ für jeden Container
- Jellyfin erreichbar?
- AltMount verbunden mit Eweka?
- Prowlarr Indexer online?
- Letztes erfolgreich importiertes Media

---

## 📖 Weiterführende Links

- [AltMount Doku](https://altmount.kipsilabs.top/)
- [Jellyfin Doku](https://jellyfin.org/docs/)
- [TRaSH-Guides](https://trash-guides.info/) — Qualitätsprofile für Radarr/Sonarr
- [Eweka](https://www.eweka.nl/)
- [NZBGeek](https://nzbgeek.info/)

---

## 👨‍💻 Autor

**Clemens Einetter** — [@clezcoding](https://github.com/clezcoding)

Lizenz: MIT
