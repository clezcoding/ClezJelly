<h1 align="center">🎬 ClezJelly</h1>

<p align="center">
  <strong>Automatisierter Jellyfin Media-Server mit On-Demand Usenet-Streaming</strong><br>
  <em>Keine Downloads. Kein lokaler Speicher. Nur schauen.</em>
</p>

<p align="center">
  <a href="#-features"><img src="https://img.shields.io/badge/stack-jellyfin%20%2B%20altmount-blueviolet"></a>
  <a href="#-security--sicherheit"><img src="https://img.shields.io/badge/credentials-encrypted-success"></a>
  <a href="#-automation"><img src="https://img.shields.io/badge/setup-90%25%20automated-brightgreen"></a>
  <a href="https://www.apple.com/macos/"><img src="https://img.shields.io/badge/platform-macOS-black?logo=apple"></a>
</p>

---

## 📺 Was ist das?

Ein vollständig vorkonfigurierter Media-Server-Stack für ein ungenutztes MacBook, das Serien und Filme **direkt aus dem Usenet streamt**, ohne sie herunterzuladen. Du requestest Content in einer schönen UI → ein paar Sekunden später erscheint er in deiner Jellyfin-Bibliothek → Play drücken, Stream läuft.

> **Zielerlebnis:** Samsung TV an, Jellyfin öffnen, Serie suchen, Play drücken. Fertig.

---

## 🏗️ Architektur

```
┌──────────────────┐       LAN       ┌─────────────────────┐
│  Samsung Tizen   │ ◄─────────────► │  Jellyfin (nativ)   │
│  Jellyfin-App    │                 │  HW-Transcode       │
└──────────────────┘                 │  via VideoToolbox   │
                                     └──────────┬──────────┘
                                                │ liest .strm
         ┌──────────────────────────────────────┤
         │                                      ▼
         │                           ┌─────────────────────┐
         ▼                           │  AltMount           │
┌──────────────────┐                 │  Usenet-WebDAV      │
│  Seerr           │                 │  SABnzbd-API        │
│  Request-UI      │                 │  STRM-Import        │
└────────┬─────────┘                 └──────────┬──────────┘
         │                                      │ NNTP (SSL)
         ▼                                      ▼
┌──────────────────┐                 ┌─────────────────────┐
│  Radarr/Sonarr   │ ────────────►   │  Eweka / Newshost.  │
│  Automation      │                 │  Usenet Backbone    │
└────────┬─────────┘                 └─────────────────────┘
         │
         ▼
┌──────────────────┐
│  Prowlarr        │ ◄──────── NZBGeek, DrunkenSlug, NZB.su …
│  Indexer-Manager │
└──────────────────┘
```

**Flow:**
1. Du **requestest** eine Serie in Seerr
2. Sonarr fragt Prowlarr nach besten NZBs über alle Indexer
3. Sonarr schickt die NZB an AltMount (als wäre es SABnzbd)
4. AltMount erzeugt sofort eine **virtuelle .strm-Datei** — kein Download!
5. Sonarr importiert, Jellyfin scannt, Serie erscheint
6. Beim **Play** zieht AltMount die Usenet-Artikel on-demand von Eweka

---

## ⚡ Quick Start

**Voraussetzung:** macOS, [Homebrew](https://brew.sh), [OrbStack](https://orbstack.dev) (oder Docker Desktop)

### Variante A: One-Liner (neues System)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/clezcoding/ClezJelly/main/scripts/quickstart.sh)
```

Klont das Repo nach `~/Desktop/ClezJelly` und startet den Installer.

### Variante B: Lokal

```bash
git clone https://github.com/clezcoding/ClezJelly.git ~/Desktop/ClezJelly
cd ~/Desktop/ClezJelly
./install.sh
```

---

## 🎛️ Installer-Menü

Beim Start öffnet sich ein Menü:

```
  1) 🚀 Fresh Install           — Erst-Setup, End-to-End
  2) 🔑 Credentials ändern      — Eweka/Indexer-Keys neu, verschlüsselt
  3) 🔗 Services neu verknüpfen — API-Links (Prowlarr→arr, arr→AltMount)
  4) 🇩🇪 TRaSH German-Profile    — Custom Formats für DE-Priorität
  5) 📝 Config-Files regenerieren
  6) 💾 Backup .env.local
  7) ♻️  Restore .env.local
  8) 🩺 Status checken
```

Alle Aktionen auch per CLI:
```bash
./install.sh install       # Fresh Install
./install.sh status        # Status aller Services
./install.sh backup        # .env.local sichern
./install.sh relink        # Nur API-Links neu
```

---

## 🤖 Automation

Was der Installer **automatisch** macht:

| Service | Vorkonfiguriert |
|---|---|
| **AltMount** | Provider (Eweka), SABnzbd-API, Categories, STRM-Import, ARR-Integration |
| **Prowlarr** | API-Key, Auth, Indexer (NZBGeek + optional), Radarr/Sonarr als Apps |
| **Radarr** | API-Key, Root Folder, AltMount als Download-Client, Custom Formats |
| **Sonarr** | API-Key, Root Folder, AltMount als Download-Client, Custom Formats |
| **Bazarr** | OpenSubtitles.com, DE+EN Sprach-Profile, Radarr/Sonarr-Links |
| **Seerr** | API-Key, Region AT, Original-Sprache DE |

**Manuell bleibt** (gesamt ~5 Minuten):

| Service | Was | Warum |
|---|---|---|
| **Jellyfin** | Admin-User + Libraries anlegen | Setup-Wizard ohne Headless-Mode |
| **Seerr** | Einmal mit Jellyfin einloggen | OAuth-Flow |
| **TV** | Mac-IP eingeben | nur ein Mal |

---

## 🔐 Security & Sicherheit

### Credentials-Verschlüsselung

Alle Secrets (Eweka-Passwort, Indexer-API-Keys, interne API-Keys) werden in **`.env.local`** mit **AES-256-CBC + PBKDF2 (200k Iterationen)** verschlüsselt. Die Passphrase wird nur im Memory während des Setups gehalten.

```
.env.local        → verschlüsselt (git-ignored)
config/*          → aus .env.local generiert, git-ignored
data/             → komplett git-ignored
```

### Was NICHT ins Repo kommt (via `.gitignore`)

- `.env`, `.env.local*` — alle Credentials
- `config/` — generierte Service-Configs (enthalten API-Keys)
- `data/` — Media-Library und STRM-Files
- Alle `*.db`, `*.sqlite*`, `*.bak`

### Netzwerk-Hygiene

- **Keine Portfreigaben** nach außen nötig
- Alle Services lauschen auf `localhost` (nicht `0.0.0.0`)
- Usenet-Verbindung immer über **TLS/SSL Port 563**
- Remote-Zugriff: **Tailscale** oder **WireGuard**, kein Reverse Proxy

### Backup-Strategie

```bash
./install.sh backup
# → ~/clezjelly.env.local.2026-10-10-023500.bak (verschlüsselt)
```

Dieses Backup auf externes Medium (nicht in Cloud mit Klarnamen-Account) sichern. Reicht aus, um auf einem neuen Gerät mit `./install.sh restore` → `./install.sh install` identisch neu aufzusetzen.

### Nicht enthalten (bewusst)

- Keine Login-Pages ins Internet gestellt
- Kein Benutzer-System in Jellyfin aus Public-DNS
- Keine Credentials in Git-History (gitignored von Anfang an)

---

## 📁 Repository-Struktur

```
ClezJelly/
├── README.md                    # Dieses Dokument
├── install.sh                   # Haupt-Installer mit Menü
├── docker-compose.yml           # 6-Service-Stack
├── .env.example                 # Vorlage (keine Secrets)
├── .gitignore                   # Was nie committet wird
├── docs/                        # Detaillierte Anleitungen
│   ├── 01-prerequisites.md
│   ├── 02-installation.md
│   ├── 03-configuration.md
│   ├── 04-german-content.md
│   ├── 05-samsung-tv.md
│   └── 06-troubleshooting.md
├── config-templates/            # Templates für envsubst
│   ├── altmount.config.yaml
│   ├── prowlarr.config.xml
│   ├── radarr.config.xml
│   └── sonarr.config.xml
└── scripts/
    ├── quickstart.sh            # Curl|Bash One-Liner-Target
    ├── start-stack.sh           # docker compose up
    ├── stop-stack.sh            # docker compose down
    ├── update-stack.sh          # pull + up + prune
    ├── health-check.sh          # Service-Status
    ├── push-to-github.sh        # Repo-Erstellung
    ├── lib/
    │   ├── common.sh            # Logging, Farben, Prompts
    │   ├── crypto.sh            # openssl AES-256-CBC
    │   └── api.sh               # curl + wait_for_url
    └── bootstrap/
        ├── 01-preflight.sh      # macOS, Brew, Docker, Jellyfin
        ├── 02-credentials.sh    # Prompts + .env.local
        ├── 03-generate-configs.sh
        ├── 04-start-containers.sh
        ├── 05-link-services.sh  # API-Verknüpfungen
        └── 06-trash-profiles.sh # DE Custom Formats
```

---

## 💰 Kosten (laufend)

| Service | Monatlich |
|---|---|
| **Eweka Classic** (unlimited Usenet, NL-Backbone) | ~€9 |
| **NZBGeek Standard** (Indexer) | ~€1 |
| Zweiter Indexer (optional) | ~€0–1 |
| **Gesamt** | **~€10–11** |

Hardware: **€0** — läuft auf dem vorhandenen MacBook.

> Vergleich: Ein einziges Netflix-Premium-Abo = €18/Monat.

---

## 🖥️ Service-Übersicht

| Service | URL | Funktion |
|---|---|---|
| **Jellyfin** (nativ) | <http://localhost:8096> | Media-Server, UI für TV |
| **AltMount** | <http://localhost:8080> | Usenet-Streaming via WebDAV |
| **Prowlarr** | <http://localhost:9696> | Indexer-Manager |
| **Radarr** | <http://localhost:7878> | Film-Automation |
| **Sonarr** | <http://localhost:8989> | Serien-Automation |
| **Seerr** | <http://localhost:5055> | Request-UI |
| **Bazarr** | <http://localhost:6767> | Untertitel |

---

## 🚦 Täglicher Betrieb

```bash
./scripts/start-stack.sh   # Container + Jellyfin.app starten
./scripts/stop-stack.sh    # Container stoppen
./scripts/update-stack.sh  # Images aktualisieren + prune
./scripts/health-check.sh  # Service-Status prüfen
```

Oder via Installer-Menü:
```bash
./install.sh status
```

---

## 🧰 Troubleshooting

Siehe [`docs/06-troubleshooting.md`](docs/06-troubleshooting.md). Kurzübersicht:

| Symptom | Lösung |
|---|---|
| Container down | `docker compose ps`, dann `docker compose logs <name>` |
| Keine deutschen Treffer | `./install.sh trash` + Quality-Profile-Scores anpassen |
| STRM-Datei spielt nicht | Prüfe `mount_path` in AltMount — muss von Jellyfin aus auflösbar sein |
| Credentials vergessen | `./install.sh restore` aus Backup |
| Alles kaputt | `./install.sh install` (nutzt bestehende `.env.local`) |

---

## 🧭 Workflow

**Serie requesten:**
1. **Seerr öffnen** auf Handy/Laptop: <http://localhost:5055> (oder via Tailscale von unterwegs)
2. **Suchen & Request** (Staffel, Season)
3. **Automatik läuft** — Sonarr findet, AltMount erzeugt STRM, Jellyfin scant
4. **Nach wenigen Sekunden** in Jellyfin verfügbar → vom TV abspielen

Siehe [`docs/03-configuration.md`](docs/03-configuration.md) für den vollständigen Konfigurationsguide.

---

## ⚖️ Legal

Dieses Projekt stellt **nur die Infrastruktur** bereit — es enthält keine urheberrechtlich geschützten Inhalte und ermutigt nicht dazu, diese zu verletzen. Nutze es ausschließlich für Inhalte, zu deren Nutzung du berechtigt bist (eigene Rips, Public Domain, Creative Commons etc.). In Österreich: §§ 42, 91 UrhG beachten.

Verantwortung liegt beim Betreiber.

---

## 🤝 Mitwirken

Issues und PRs willkommen. Für Änderungen bitte lokal testen:

```bash
./install.sh status            # vor dem Change
# ... Änderung ...
shellcheck install.sh scripts/**/*.sh
./install.sh status            # nach dem Change
```

---

## 📜 Lizenz

MIT — siehe [LICENSE](LICENSE).

---

<p align="center">
  <sub>Built by <a href="https://github.com/clezcoding">@clezcoding</a> · in Austria 🇦🇹</sub>
</p>
