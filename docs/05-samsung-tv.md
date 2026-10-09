# 📺 05 — Samsung Tizen TV einrichten

## Jellyfin-App installieren (falls nicht vorhanden)

1. TV einschalten
2. Smart Hub → Apps → Suche nach **Jellyfin**
3. Installieren
4. Öffnen

## MacBook-IP finden

Am MacBook im Terminal:
```bash
ipconfig getifaddr en0
# oder bei WLAN:
ipconfig getifaddr en1
```

Ergebnis z.B. `192.168.1.42`. Notieren.

**Besser:** Eine DHCP-Reservation im Router einrichten, damit die IP sich nie ändert.

## Server im TV hinzufügen

Jellyfin-App auf dem TV:
- **Server-URL manuell eingeben**
- Adresse: `http://192.168.1.42:8096` (deine MacBook-IP)
- Verbinden
- Mit deinem Jellyfin-User einloggen

## Playback-Settings für dein Internet

Jellyfin-App auf dem TV → User → Einstellungen → Wiedergabe:
- **Max. Streaming-Bitrate:** `25 Mbit/s` (passt zu deinen 40 Mbit/s mit Reserve)
- **Max. Chromecast-Bitrate:** gleich
- **Automatische Qualität:** ✓

## Direct Play prüfen

Beim ersten Playback oben rechts das kleine „i" oder bei einer Episode die Transcoding-Info öffnen:
- **Play Method: Direct Play** ✓ (perfekt — kein Transcoding nötig)
- **Play Method: Direct Stream** (ok — nur Container-Umverpackung)
- **Play Method: Transcode** (❌ beim MacBook sollte VideoToolbox das aber flott machen)

## Remote-Zugriff mit Tailscale (optional)

Damit du von unterwegs auch Jellyfin erreichst:

```bash
brew install --cask tailscale
```

- Tailscale starten, Account anlegen (Free)
- Auf dem Handy ebenfalls Tailscale-App installieren
- Auf dem Handy Jellyfin-App → `http://<tailscale-ip-vom-mac>:8096`

Kein Portforwarding am Router nötig, keine öffentliche Domain, verschlüsselt.

## Troubleshooting

### TV findet den Server nicht
- Beide im gleichen Netz?
- Ping vom Mac zum TV testen: `ping <TV-IP>`
- Firewall auf dem Mac deaktiviert (System → Netzwerk → Firewall)

### Buffering
- Max-Bitrate im TV runtersetzen auf 15 Mbit/s
- Qualitätsprofile in Radarr/Sonarr auf WEB-DL 1080p begrenzen
- Prüfen ob andere Downloads im Haushalt laufen

### App stürzt ab
- Jellyfin-App am TV löschen und neu installieren
- Firmware-Update am TV
- Alternative: **Jellyfin Media Player** installieren (etwas älterer Tizen-Build, aber stabiler)

### 4K-Content ruckelt
- 4K via Internet-Stream geht bei 40 Mbit/s nicht sauber
- In Radarr/Sonarr Quality-Profiles auf max. 1080p einschränken
