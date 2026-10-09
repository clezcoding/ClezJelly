# 🇩🇪 04 — Deutsche Inhalte maximieren

Dieser Guide sorgt dafür, dass du Bergdoktor, Tatort, HIMYM-DE etc. findest.

## Strategie

Deutsche Releases kommen aus mehreren Quellen:
1. **nzb.cat** → bester allgemeiner Indexer für DE
2. **NZBGeek** → auch DE drin, nur schwächer
3. **altHUB** → spezifische DE-Scene-Releases
4. **TRaSH-Custom-Formats** → priorisiert DE-Tonspuren bei der Auswahl

## 1. Alle Indexer in Prowlarr

Siehe [`03-configuration.md § 2.2`](03-configuration.md).

Zusätzlich zu NZBGeek + nzb.cat kannst du einrichten:
- **altHUB** (Free Tier reicht)
- **DOGnzb** (Invite only — falls du einen Invite auftreibst)
- **Drunken Slug** (open signups manchmal)

Je mehr Indexer, desto höher die Chance auf gute DE-Treffer.

## 2. TRaSH-Custom-Formats für Deutsch

Die wichtigste Konfiguration für DE-Priorität.

### Für Radarr

Öffne https://trash-guides.info/Radarr/Radarr-setup-quality-profiles-german-en/ und folge:

1. **Settings → Custom Formats → Import:**
   - `German` (TRaSH-ID: ...)
   - `GERMAN DL (DL = Dual Language, meist DE+EN)`
   - `GERMAN ONLY`
   - `English` (als Fallback)
2. **Settings → Profiles → HD-1080p → Custom Formats:**
   - `German DL`: **+500** Score
   - `GERMAN ONLY`: **+400** Score (nur wenn du kein EN brauchst)
   - `English`: **+100** Score (Fallback)
   - Alle anderen: 0

So priorisiert Radarr automatisch deutsche Dual-Audio-Releases > nur-Deutsch > nur-Englisch.

### Für Sonarr

Analog nach https://trash-guides.info/Sonarr/sonarr-setup-quality-profiles-german-en/

## 3. Sprach-Fallback

Falls kein DE-Release gefunden wird, bekommst du trotzdem EN (mit DE-Untertiteln von Bazarr).

**Radarr → Settings → Profiles → Language Profile:**
- Primary Language: **German**
- Fallback: **English**

**Sonarr → Settings → Language:**
- Analog

## 4. Metadaten auf Deutsch

**Jellyfin → Dashboard → Bibliotheken → Filme → Bearbeiten → Metadaten:**
- Metadata-Downloader-Sprache: **Deutsch**
- Länder-Code: **AT** (oder DE)
- The Movie Database (deutsch) ✓
- Save → **Scan Library**

Danach kommen Film-Titel, Beschreibungen, Poster auf Deutsch.

## 5. Legale Ergänzungen (optional)

Für ARD/ZDF/ORF-Mediathek-Inhalte gibt es **keine saubere Jellyfin-Integration**. Zwei Optionen:

### A) Separater Browser auf dem TV

Samsung Tizen kann Mediatheken-Seiten direkt im Browser → nicht in Jellyfin, aber eine Alternative.

### B) MediathekView-Tool nebenbei

[MediathekView](https://mediathekview.de/) kannst du auf dem MacBook installieren und automatisch deutsche Public-Broadcast-Inhalte in `data/media/tv/Mediathek/` ablegen lassen. Jellyfin scant das dann als lokale Library mit.

Dies ist komplett legal, da ARD/ZDF/ORF selbst zum Download anbieten.

## 6. Erwartungshaltung

| Content | Realistisch findbar |
|---|---|
| Große US-Serien (HIMYM, Breaking Bad, Game of Thrones) auf DE | ✅ fast immer, Dual-Audio |
| Deutsche Mainstream-Serien (Tatort, Bergdoktor) | ✅ meist, über nzb.cat |
| Deutsche Netflix/Amazon Originals | 🟡 oft, aber manchmal verzögert |
| Nischige deutsche Produktionen | 🟡 teils schwer |
| 4K/UHD auf DE | 🔴 selten, auch bandbreitentechnisch für dich nicht sinnvoll |
| Live-TV | ❌ anderes Setup nötig (TVHeadend) |

## 7. Tipp: Jellyseerr-Suche auf DE umstellen

**Jellyseerr → Settings → General:**
- Preferred Language: **Deutsch**
- Origin Country: **Österreich**

Dann zeigt Jellyseerr Titel und Beschreibungen auf Deutsch an und findet eher regional relevante Inhalte.
