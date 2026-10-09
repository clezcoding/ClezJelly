# 📋 01 — Voraussetzungen

Bevor du mit der Installation beginnst, brauchst du folgendes.

## Hardware

| Was | Spezifikation |
|---|---|
| **MacBook M3 Pro** | Dein zweites, nicht genutztes Gerät |
| **macOS** | Sonoma oder neuer |
| **Freier Speicher** | ~10 GB für Docker-Images, Config, Metadata |
| **RAM** | 8 GB reichen, 16 GB empfohlen |
| **Internet** | Mindestens 40 Mbit/s Downstream (hast du) |
| **Samsung Tizen TV** | Mit installierter Jellyfin-App |

## Netzwerk-Setup

- MacBook und Samsung TV im **gleichen WLAN/LAN**
- Router sollte dem MacBook eine **feste IP** zuweisen (DHCP-Reservation)
- Keine Port-Freigaben nach außen nötig

## Software (wird vom Install-Script geprüft)

| Software | Prüf-Befehl | Installation |
|---|---|---|
| **Homebrew** | `brew --version` | `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |
| **Docker Desktop** | `docker --version` | `brew install --cask docker` |
| **Jellyfin** (nativ) | `ls /Applications/Jellyfin.app` | `brew install --cask jellyfin` |

Das `install.sh` kümmert sich darum. Du musst nur Homebrew selbst installieren, falls noch nicht vorhanden.

## Online-Accounts (müssen VOR dem Setup existieren)

### 1. Eweka — Usenet Provider (Pflicht)

- **URL:** https://www.eweka.nl/
- **Tarif:** Classic (unlimited, ~€9/Monat) — oder jährlich für günstiger
- **Warum Eweka:** NL-Backbone = EU-schnell, super Retention (5000+ Tage), kein Logging
- **Alternative:** [Newshosting](https://www.newshosting.com/) (US-Backbone, Tochter von Highwinds) oder [Frugalusenet](https://frugalusenet.com/) (bundelt mehrere Backbones)

Nach dem Signup brauchst du:
- Server-Hostname: `ssl-eu.eweka.nl` (siehe Eweka Dashboard)
- Port: `563` (SSL)
- Username & Passwort

### 2. NZBGeek — Indexer (Pflicht)

- **URL:** https://nzbgeek.info/
- **Tarif:** Standard (~$12/Jahr)
- **Fokus:** Allgemein stark bei englischen Releases, aber alles dabei

Nach dem Signup findest du im Profil:
- API-URL: `https://api.nzbgeek.info`
- API-Key

### 3. Zweiter Indexer für Redundanz & deutsche Inhalte (empfohlen)

> **Wichtig:** Die früher empfohlenen dedizierten DE-Indexer (nzb.cat, SceneNZBs, Newz Complex) sind alle offline. Es gibt heute **keinen** reinen DE-API-Indexer mehr. Lösung: mehrere Allgemein-Indexer parallel in Prowlarr → sie tragen die DE-Scene-Releases mit, nur ohne „German"-Flag — die TRaSH-Custom-Formats fischen sie dann über Scene-Tags (`.GERMAN.`, `.GER.`, `.ML.`) raus.

Nimm **einen oder zwei** der folgenden zusätzlich zu NZBGeek:

| Indexer | Signup | Preis | DE-Qualität |
|---|---|---|---|
| **DrunkenSlug** | Invite-only (r/UsenetInvites) | $15/Jahr | ⭐⭐⭐⭐ |
| **NZBPlanet** | Oft open | €15/Jahr | ⭐⭐⭐ |
| **NZB.su** | Open Signup | kostenlos/Donate | ⭐⭐⭐ |
| **DogNZB** | Invite-only, zeitweise offen | donate | ⭐⭐⭐⭐ |
| **NinjaCentral** | Open ~24h an Feiertagen (Black Friday, 4. Mai) | $5-10 | ⭐⭐⭐ |
| **NZBFinder** | Zeitweise open | ~€10/Jahr | ⭐⭐⭐ |

**Praktischer Pfad:**
1. NZBGeek als Basis (schon oben)
2. [r/UsenetInvites](https://reddit.com/r/UsenetInvites) checken — oft Invites für DrunkenSlug / DogNZB
3. Falls kein Invite erreichbar: [r/usenet](https://reddit.com/r/usenet) im Auge behalten für Open-Signup-Fenster

Nach dem Signup findest du im Profil des jeweiligen Indexers:
- API-URL
- API-Key

### 4. Optional — Boards für Deep-Catalog (manuell, kein API)

Für obskure deutsche Releases, die kein API-Indexer kennt, kannst du zusätzlich einen deutschen Board-Account anlegen. Boards haben kein API, du suchst manuell im Browser:

- **Sky of Usenet** — meist open Signup, solider DE-Content
- **Brothers of Usenet (BoU)** — vergleichsweise offene Community, breit
- **House of Usenet (HoU)** — closed/invite, aber tiefster DE-Katalog

Workflow: NZB manuell runterladen → direkt in AltMount hochladen (Upload-Button in der Web-UI).

## Vor-Setup-Checkliste

Bevor du `./install.sh` startest, hake ab:

- [ ] MacBook im Netzwerk, Samsung TV ebenso
- [ ] Jellyfin-App auf dem TV installiert
- [ ] Homebrew installiert und funktioniert (`brew --version`)
- [ ] OrbStack installiert und läuft (oder Docker Desktop)
- [ ] Eweka-Account aktiv, Credentials notiert
- [ ] NZBGeek-API-Key notiert
- [ ] Mindestens ein zweiter Indexer-API-Key notiert (siehe Tabelle oben)
- [ ] Dieser Ordner (`ClezJelly`) existiert auf dem Desktop

Wenn alles check ist → weiter zu [`02-installation.md`](02-installation.md).
