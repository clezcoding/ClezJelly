# 🚀 02 — Installation

## Option A: Automatisch (empfohlen)

```bash
cd ~/Desktop/ClezJelly
chmod +x install.sh scripts/*.sh
./install.sh
```

Das Script macht:

1. **Preflight-Checks** — macOS, Homebrew, Docker, Jellyfin, openssl
2. **.env generieren** — mit automatisch erzeugtem JWT-Secret, deiner User-ID
3. **Ordnerstruktur anlegen** — `config/`, `data/media/`, `data/strm/`
4. **Docker-Images pullen** — alle Services in neuester Version
5. **Stack starten** — alle Container `up -d`
6. **Jellyfin.app starten** — damit du gleich loskonfigurieren kannst

Nach ~2 Minuten läuft alles. Siehe die URLs im Terminal-Output.

Danach weiter zu [`03-configuration.md`](03-configuration.md).

---

## Option B: Manuell

Falls du Schritt für Schritt gehen willst:

### 1. Repository klonen oder diesen Ordner nehmen

```bash
cd ~/Desktop/ClezJelly
```

### 2. Berechtigungen setzen

```bash
chmod +x install.sh scripts/*.sh
```

### 3. .env erstellen

```bash
cp .env.example .env
```

Datei öffnen und anpassen:

```bash
nano .env
```

- `TZ=Europe/Vienna` ✓
- `PUID=$(id -u)` → eintragen (meist `501`)
- `PGID=$(id -g)` → eintragen (meist `20`)
- `ALTMOUNT_JWT_SECRET=` → generiere mit:
  ```bash
  openssl rand -hex 32
  ```
  Den Output komplett einfügen.

### 4. Ordnerstruktur

```bash
mkdir -p config/{altmount,prowlarr,radarr,sonarr,jellyseerr,bazarr}
mkdir -p data/media/{movies,tv}
mkdir -p data/strm/{movies,tv}
mkdir -p data/metadata
```

### 5. Docker Images pullen

```bash
docker compose pull
```

Dauert einige Minuten. ~2-3 GB Download.

### 6. Stack starten

```bash
docker compose up -d
```

### 7. Status checken

```bash
docker compose ps
```

Alle Container sollten `Up` zeigen.

### 8. Jellyfin starten (nativ)

```bash
open -a Jellyfin
```

Oder manuell über das Applications-Verzeichnis.

### 9. Jellyfin in den Autostart

System-Einstellungen → Allgemein → Anmeldeobjekte → `+` → Jellyfin.app auswählen.

### 10. Docker Desktop in den Autostart

Docker Desktop → Settings → General → „Start Docker Desktop when you sign in" ✓

---

## Energieoptionen auf dem MacBook (wichtig!)

Damit der Server zuverlässig läuft:

**System-Einstellungen → Batterie → Netzteil:**
- Mac automatisch einschlafen lassen, wenn Display aus: **AUS**
- Nach einem Stromausfall automatisch starten: **AN**
- „Energie" → Weckruf für Netzwerkzugriff: **AN**

**Mit externem Monitor/Netzteil kannst du den Deckel zu lassen (Clamshell-Mode).** Für den ersten Setup aber Deckel offen.

---

## Verifizieren

```bash
./scripts/health-check.sh
```

Alle 7 Services sollten grüne ✓ zeigen.

Weiter zu [`03-configuration.md`](03-configuration.md).
