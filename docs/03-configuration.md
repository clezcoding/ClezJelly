# ⚙️ 03 — Konfiguration

> **Reihenfolge einhalten!** Jeder Schritt baut auf dem vorherigen auf. Insgesamt ~30 Minuten.

## Übersicht der Schritte

1. [AltMount](#1-altmount) — Usenet-Streaming einrichten
2. [Prowlarr](#2-prowlarr) — Indexer verwalten
3. [Radarr](#3-radarr) — Film-Automation
4. [Sonarr](#4-sonarr) — Serien-Automation
5. [Prowlarr-Sync](#5-prowlarr-sync) — Apps verbinden
6. [AltMount als Download-Client](#6-altmount-als-download-client)
7. [Jellyfin](#7-jellyfin)
8. [Jellyseerr](#8-jellyseerr)
9. [Bazarr](#9-bazarr) — Untertitel
10. [Jellyfin ↔ Radarr/Sonarr](#10-jellyfin--radarrsonarr)

---

## 1. AltMount

**URL:** http://localhost:8080

### 1.1 Admin-Account anlegen

Beim ersten Aufruf siehst du den Registrierungsscreen. Lege einen Admin an:
- Username: `admin` (oder nach Wahl)
- Starkes Passwort

### 1.2 NNTP Provider hinzufügen

Navigiere zu **Configuration → Providers → Add Provider**:

| Feld | Wert |
|---|---|
| Host | `ssl-eu.eweka.nl` |
| Port | `563` |
| Username | *dein Eweka-Username* |
| Password | *dein Eweka-Passwort* |
| Max Connections | `20` |
| Use TLS/SSL | ✓ |
| Skip TLS verification | ✗ |
| Inflight Requests | `10` |
| Enabled | ✓ |

**Save** → der grüne Status-Indikator sollte innerhalb von Sekunden erscheinen.

### 1.3 Import-Strategie: STRM

Navigiere zu **Configuration → Import**:
- Import Strategy: **STRM**
- Import Dir: `/strm`
- Save

Navigiere zu **Configuration → General** (oben):
- Mount Path: `http://altmount:8080` (ohne Trailing Slash)
- Save

### 1.4 Mount Type: None

Da wir STRM nutzen, brauchen wir keinen FUSE-Mount.

Navigiere zu **Configuration → Mount**:
- Mount Type: **None**
- Save

### 1.5 SABnzbd-Kompatibilität aktivieren

Navigiere zu **Configuration → SABnzbd**:
- Enabled: ✓
- Categories (Add Category):
  - Name: `movies`, Type: `radarr`
  - Name: `tv`, Type: `sonarr`
- Save

### 1.6 API-Key notieren

Navigiere zu **Settings → API** (oder Dashboard).
Den API-Key kopieren — brauchen wir gleich für Radarr/Sonarr.

---

## 2. Prowlarr

**URL:** http://localhost:9696

### 2.1 Erst-Setup

- Authentication: **Forms (Login Page)** → User + Passwort anlegen → **Save**
- Settings → General → **Show Advanced** aktivieren

### 2.2 Indexer hinzufügen

Links **Indexers → Add Indexer**.

**NZBGeek:**
- Suche nach `nzbgeek`
- Add
- API Key: *aus NZBGeek-Account*
- Save

**Zweiter Indexer** (einen davon einrichten — welchen du hast):

**DrunkenSlug:**
- Suche `drunkenslug`
- API URL: `https://drunkenslug.com`
- API Key eintragen → Save

**NZBPlanet:**
- Suche `nzbplanet`
- API URL: `https://nzbplanet.net`
- API Key eintragen → Save

**NZB.su:**
- Suche `nzb.su`
- API URL: `https://api.nzb.su`
- API Key eintragen → Save

**DogNZB** (falls du einen Account hast):
- Suche `dognzb`
- API URL: `https://api.dognzb.cr`
- API Key eintragen → Save

> **Tipp:** Je mehr Indexer, desto bessere DE-Treffer. 2-3 ist der Sweet-Spot.

Alle Indexer sollten grüne Status-Punkte zeigen.

### 2.3 API-Key notieren

**Settings → General → Security → API Key** kopieren.

---

## 3. Radarr

**URL:** http://localhost:7878

### 3.1 Erst-Setup

- Authentication: Forms → User anlegen → Save
- Settings → General → **Show Advanced**

### 3.2 Root Folder

**Settings → Media Management → Root Folders → Add Root Folder:**
- Path: `/movies`
- Save

### 3.3 Media Management Settings

Settings → Media Management:
- Rename Movies: ✓
- Standard Movie Format (TRaSH-Guide empfohlen):
  ```
  {Movie CleanTitle} {(Release Year)} [imdbid-{ImdbId}]{[Edition-{Edition Tags}]}{[Custom Formats]}{[Quality Full]}{[MediaInfo 3D]}{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ Mediainfo AudioChannels]}[{Mediainfo VideoCodec}]{-Release Group}
  ```
- Movie Folder Format:
  ```
  {Movie CleanTitle} ({Release Year}) [imdbid-{ImdbId}]
  ```
- Use Hardlinks: ✓ (greift bei STRM nicht, aber good practice)
- Permissions → chmod Folder: `755`, chmod File: `644`

### 3.4 Quality Profile für deine Bandbreite

**Settings → Profiles → Quality Profiles → `HD-1080p`** bearbeiten:
- Qualities: nur **WEBDL-1080p**, **WEBRip-1080p**, **HDTV-1080p** aktivieren
- 4K ❌ ausschalten (zu wenig Bandbreite bei dir)

### 3.5 API-Key notieren

Settings → General → Security → API Key.

---

## 4. Sonarr

**URL:** http://localhost:8989

Analog zu Radarr:
- Authentication: Forms → User
- Root Folder: `/tv`
- Rename Series: ✓
- Standard Episode Format (TRaSH):
  ```
  {Series TitleYear} - S{season:00}E{episode:00} - {Episode CleanTitle} [{Preferred Words }{Quality Full}]{[MediaInfo VideoDynamicRangeType]}[{MediaInfo VideoBitDepth}bit]{[MediaInfo VideoCodec]}[{Mediainfo AudioCodec} { Mediainfo AudioChannels}]{[MediaInfo AudioLanguages]}{[MediaInfo SubtitleLanguages]}{-Release Group}
  ```
- Quality Profile HD-1080p → nur **WEBDL-1080p**, **WEBRip-1080p**, **HDTV-1080p**
- API-Key notieren

---

## 5. Prowlarr-Sync

Zurück zu **Prowlarr → Settings → Apps → Add Application**.

### 5.1 Radarr

- Prowlarr Server: `http://prowlarr:9696`
- Radarr Server: `http://radarr:7878`
- API Key: *dein Radarr-API-Key*
- Test → sollte grün werden
- Save

### 5.2 Sonarr

- Prowlarr Server: `http://prowlarr:9696`
- Sonarr Server: `http://sonarr:8989`
- API Key: *dein Sonarr-API-Key*
- Test → grün
- Save

### 5.3 Indexer syncen

**Prowlarr → Indexers → Sync App Indexers** (oben).

Prüfen: In Radarr → Settings → Indexers sollten jetzt **alle Indexer** auftauchen, die du in Prowlarr konfiguriert hast. Dasselbe in Sonarr.

---

## 6. AltMount als Download-Client

In **Radarr → Settings → Download Clients → + → SABnzbd:**

| Feld | Wert |
|---|---|
| Name | `AltMount` |
| Enable | ✓ |
| Host | `altmount` |
| Port | `8080` |
| URL Base | *leer* |
| API Key | *dein AltMount-API-Key* |
| Category | `movies` |
| Recent Priority | Default |
| Older Priority | Default |
| Use SSL | ✗ |

**Test** → grün → **Save**

Dasselbe in **Sonarr**:
- Name: `AltMount`
- Host: `altmount`, Port: `8080`, API Key wie oben
- **Category: `tv`**

---

## 7. Jellyfin

**URL:** http://localhost:8096

### 7.1 Erst-Setup Wizard

- Sprache: Deutsch
- Admin-User anlegen

### 7.2 Libraries

**Dashboard → Bibliotheken → + Hinzufügen:**

**Filme:**
- Inhaltstyp: Filme
- Anzeigename: `Filme`
- Ordner: Durchsuchen → `/Users/puzzless/Desktop/ClezJelly/data/strm/movies`
- Sprache: Deutsch
- Metadaten-Downloader: TheMovieDb aktivieren
- Fanart.tv aktivieren
- Speichern

**Serien:**
- Inhaltstyp: Fernsehserien
- Anzeigename: `Serien`
- Ordner: `/Users/puzzless/Desktop/ClezJelly/data/strm/tv`
- Rest analog

### 7.3 Hardware-Transcoding

**Dashboard → Playback → Transkodierung:**
- Hardware-Beschleunigung: **VideoToolbox**
- Erlaube Encoding in HEVC-Format: ✓
- Save

### 7.4 API-Key für Jellyseerr & Radarr/Sonarr Connect

**Dashboard → API-Keys → + Neuer API-Key:**
- Name: `ClezJelly-Integration`
- Kopieren und notieren

---

## 8. Jellyseerr

**URL:** http://localhost:5055

### 8.1 Mit Jellyfin verbinden

- „Sign in with Jellyfin"
- Jellyfin URL: `http://host.docker.internal:8096`
- Dein Jellyfin-Admin-Account
- Login

### 8.2 Services → Radarr

**Add Radarr Server:**
- Default Server: ✓
- 4K Server: ✗
- Server Name: `Radarr`
- Hostname: `radarr`
- Port: `7878`
- API Key: *dein Radarr-API-Key*
- URL Base: *leer*
- SSL: ✗
- Quality Profile: `HD-1080p`
- Root Folder: `/movies`
- Enable Scan: ✓
- Enable Automatic Search: ✓
- Test → grün → Save

### 8.3 Services → Sonarr

- Default Server: ✓
- Server Name: `Sonarr`
- Hostname: `sonarr`, Port: `8989`
- API Key: *dein Sonarr-API-Key*
- Quality Profile: `HD-1080p`
- Root Folder: `/tv`
- Language Profile: Default
- Rest analog
- Test → grün → Save

---

## 9. Bazarr

**URL:** http://localhost:6767

### 9.1 Erst-Setup

- Settings → General → Authentication: Form → User anlegen

### 9.2 Providers

**Settings → Providers → + Add:**
- **OpenSubtitles.com** (empfohlen, free account)
- **Subscene**
- **Addic7ed** (gut für Serien)
- Save

### 9.3 Languages

Settings → Languages:
- Enabled Languages: **Deutsch**, **English**
- Default-Profil anlegen:
  - Name: `DE+EN`
  - Add Language: Deutsch (preferred), English (fallback)
- Save

### 9.4 Radarr/Sonarr verbinden

**Settings → Radarr:**
- Enabled: ✓
- Address: `radarr`, Port: `7878`
- API Key: *dein Radarr-API-Key*
- Default-Profil: `DE+EN`
- Test → Save

**Settings → Sonarr:**
- Analog, `sonarr`:`8989`

---

## 10. Jellyfin ↔ Radarr/Sonarr

Damit Jellyfin automatisch gescannt wird, wenn Radarr/Sonarr importieren.

**Radarr → Settings → Connect → + → Jellyfin:**
- Name: `Jellyfin`
- Host: `host.docker.internal`
- Port: `8096`
- API Key: *dein Jellyfin-API-Key*
- Notification: **On Import** ✓, **On Upgrade** ✓
- Test → Save

**Sonarr → Settings → Connect** → analog.

---

## ✅ Fertig!

Alles ist jetzt verdrahtet. Jetzt der große Test:

1. Öffne Jellyseerr → Suche „How I Met Your Mother"
2. Request „alle Staffeln"
3. In Sonarr → Activity → Queue sollte die NZB auftauchen
4. In AltMount → Queue siehst du den Import
5. Sekunden später: STRM-Files erscheinen in `data/strm/tv/How I Met Your Mother/`
6. Sonarr importiert → Jellyfin bekommt Push → Serie erscheint
7. Jellyfin → Serie öffnen → Play drücken
8. Nach 5–10 Sekunden Buffer: läuft!

Siehe [`04-german-content.md`](04-german-content.md) für maximale deutsche Content-Deckung und [`05-samsung-tv.md`](05-samsung-tv.md) für die TV-Anbindung.
