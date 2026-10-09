# 🔧 06 — Troubleshooting

## Allgemein — Erste Hilfe

```bash
# Status aller Container
./scripts/health-check.sh

# Live-Logs eines Services
docker compose logs -f altmount
docker compose logs -f radarr
docker compose logs -f sonarr

# Container neustarten
docker compose restart altmount

# Kompletter Neustart
./scripts/stop-stack.sh
./scripts/start-stack.sh
```

---

## AltMount

### „Provider authentication failed"
- Username/Passwort beim Eweka richtig?
- Rate-Limit: Max Connections nicht höher setzen als dein Eweka-Tarif erlaubt (20 ist safe)
- Account noch aktiv (abgelaufen?)

### „480 errors" oder viele „too many connections"
- Max Connections runter auf z.B. 10
- Prüfen ob noch andere Clients mit deinem Eweka-Account laufen

### Keine STRM-Files erscheinen in `data/strm/`
- Prüfen: AltMount → Configuration → Import → Import Dir = `/strm`
- Volume-Mapping in docker-compose: `./data/strm:/strm` ✓
- Berechtigungen: `chmod 755 data/strm`

### Streams buffern dauerhaft
- NNTP-Pipelining ausprobieren: AltMount → Provider → Inflight Requests auf `1` setzen
- Alternativ auf `20` wenn der Provider mitmacht
- Check: Direkt in Browser `http://localhost:8080/webdav/` die File öffnen — spielt sie dort?

---

## Prowlarr / Radarr / Sonarr

### Indexer-Test schlägt fehl
- API-Key kopiert ohne Leerzeichen?
- URL stimmt (manche Indexer brauchen `/api` am Ende, andere nicht)
- VPN auf dem Mac aktiv? Könnte den NZB-Indexer blockieren

### Prowlarr findet Apps nicht
- Interne Docker-Hostnamen nutzen: `http://radarr:7878`, nicht `http://localhost:7878`
- Beide Container im selben Network (`clezjelly`) — in unserem compose ist das so

### „No download client available"
- AltMount-Container läuft? `docker compose ps`
- In Radarr/Sonarr: Settings → Download Clients → **Test**
- Host muss `altmount` sein (interner Docker-DNS), nicht `localhost`

### Radarr findet Releases, aber grabbed nicht
- AltMount API-Key in Radarr korrekt?
- SABnzbd-Kompatibilität in AltMount aktiviert?
- Category `movies` in beiden Seiten identisch?

---

## Jellyfin

### Library zeigt keine neuen Imports
- Dashboard → Scheduled Tasks → **Scan Library** manuell triggern
- Prüfen: Connect-Hook in Radarr/Sonarr korrekt? (siehe § 10 im Config-Guide)
- Pfad richtig? Jellyfin muss `data/strm/movies` und `data/strm/tv` sehen (nativer Mac-Pfad!)

### STRM-Files spielen nicht ab
- Jellyfin kann vom Container nicht auf `http://altmount:8080` zugreifen (läuft ja nativ)
- Lösung: AltMount sollte unter `http://localhost:8080` erreichbar sein für Jellyfin
- Teste manuell: Öffne eine `.strm`-Datei mit `cat` → URL kopieren → im Browser aufrufen
- Falls URL `http://altmount:8080` enthält → in AltMount die `mount_path` ändern auf `http://localhost:8080`

### Hardware-Transcoding geht nicht
- Jellyfin → Dashboard → Playback → Transcoding Logs checken
- VideoToolbox-Fehler? Jellyfin-Version aktualisieren: `brew upgrade --cask jellyfin`
- macOS zu alt? Mindestens Monterey, besser Sonoma

### „Server nicht erreichbar" von Samsung TV
- Mac-Firewall deaktivieren (zumindest zum Testen)
- Mac-IP geändert? → `ipconfig getifaddr en0` neu abfragen
- Jellyfin-App am TV: Server-Adresse neu eingeben

---

## Jellyseerr

### Login mit Jellyfin schlägt fehl
- URL richtig: `http://host.docker.internal:8096` (nicht `localhost:8096`)
- `host.docker.internal` ist der Docker-DNS-Name für den Mac-Host

### Request landet nicht in Radarr/Sonarr
- Service in Jellyseerr richtig verbunden?
- API-Key stimmt?
- In Jellyseerr → Settings → Jobs → „sync_requests" manuell triggern

---

## Netzwerk / Docker

### Container stirbt immer wieder
```bash
docker compose logs <servicename>
```

Oft:
- Volume-Mount fehlgeschlagen → Berechtigungen
- Port bereits belegt → `lsof -i :8080` prüfen
- RAM-Limit → Docker Desktop → Settings → Resources

### `docker compose pull` schlägt fehl
- Docker Desktop neustarten
- Login nötig? `docker login`

### macOS-spezifisch: Mounts langsam
- Docker Desktop → Settings → General → **Use VirtioFS** aktivieren (viel schneller als osxfs/gRPC-FUSE)

---

## Komplette Neuinstallation

Nuklear-Option:

```bash
cd ~/Desktop/ClezJelly
./scripts/stop-stack.sh
docker compose down -v   # löscht auch Volumes
rm -rf config/*/
rm -rf data/
rm .env
./install.sh             # von vorn
```

**Achtung:** Alle Konfigurationen gehen verloren. API-Keys musst du neu generieren.

---

## Hilfe holen

- AltMount Discord: https://discord.gg/vCWwuvm3F3
- Jellyfin Forum: https://forum.jellyfin.org/
- r/Jellyfin, r/Sonarr, r/Radarr
- TRaSH-Guides: https://trash-guides.info/
