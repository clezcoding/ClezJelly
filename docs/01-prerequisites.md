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

### 3. nzb.cat — Indexer für deutsche Inhalte (sehr empfohlen)

- **URL:** https://nzb.cat/
- **Tarif:** Lifetime ~$10 einmalig
- **Fokus:** Besonders gute Deutsch/Multi-Language-Abdeckung

Nach dem Signup findest du im Profil:
- API-URL: `https://nzb.cat`
- API-Key

### 4. Optional — altHUB

- **URL:** https://althub.co.za/
- **Tarif:** Free Tier ok, Donate für mehr
- **Fokus:** Deutsche Scene-Releases

## Vor-Setup-Checkliste

Bevor du `./install.sh` startest, hake ab:

- [ ] MacBook im Netzwerk, Samsung TV ebenso
- [ ] Jellyfin-App auf dem TV installiert
- [ ] Homebrew installiert und funktioniert (`brew --version`)
- [ ] Docker Desktop installiert und läuft (Icon in Menüleiste sichtbar)
- [ ] Eweka-Account aktiv, Credentials notiert
- [ ] NZBGeek-API-Key notiert
- [ ] nzb.cat-API-Key notiert
- [ ] Dieser Ordner (`ClezJelly`) existiert auf dem Desktop

Wenn alles check ist → weiter zu [`02-installation.md`](02-installation.md).
