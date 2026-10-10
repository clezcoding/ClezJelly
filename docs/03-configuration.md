# 03 · Configuration

[← 02 · Installation](02-installation.md) · [README](../README.md) · Next: [04 · German content](04-german-content.md)

The installer configures everything. This page explains *what* it set up so you can tune it, and what to touch with care.

## Service names and addresses

Inside Docker, use the **service name**. From your Mac's browser, use `localhost`.

| Service | Inside the network | From your Mac | Published to |
|---|---|---|---|
| AltMount | `http://altmount:8080` | `http://localhost:8080` | `127.0.0.1` (LAN if you opt in) |
| Prowlarr | `http://prowlarr:9696` | `http://localhost:9696` | `127.0.0.1` |
| Radarr | `http://radarr:7878` | `http://localhost:7878` | `127.0.0.1` |
| Sonarr | `http://sonarr:8989` | `http://localhost:8989` | `127.0.0.1` |
| Seerr | `http://seerr:5055` | `http://localhost:5055` | LAN by default |
| Bazarr | `http://bazarr:6767` | `http://localhost:6767` | `127.0.0.1` |
| Jellyfin | `http://jellyfin:8096` | `http://localhost:8096` | native app |

The name `jellyfin` points from every container to the Mac itself (Docker's `host-gateway`). So Seerr can talk to your native Jellyfin with no IP address.

When you enter a URL in any web UI, always use the **inside** form: `http://radarr:7878`, never `http://localhost:7878`. `localhost` inside a container means the container itself.

## Folders and volumes

```
ClezJelly/
├─ config/<service>/      mounted at /config   (Seerr: /app/config)
└─ data/                  mounted at /data in altmount, radarr, sonarr, bazarr
   ├─ strm/               AltMount's staging folder for new .strm files
   └─ library/
      ├─ movies/          Radarr root folder, Jellyfin "Movies" library
      └─ tv/              Sonarr root folder, Jellyfin "Shows" library
```

Because every container mounts the same `data/` at the same `/data`, a path like `/data/library/movies/Heat (1995)/Heat (1995).strm` means the same file to all of them. This is the single rule that prevents most "file not found" problems in this kind of stack.

Jellyfin runs natively, so it sees the same files at their real path: `~/Desktop/ClezJelly/data/library/movies`.

## What was set up where

### AltMount

Seeded from `config-templates/altmount.config.yaml`.

| Setting | Value | Why |
|---|---|---|
| Import strategy | `STRM` | Writes `.strm` pointer files, no mounted filesystem needed on macOS |
| Import dir | `/data/strm` | Staging area, Radarr/Sonarr move results into the library |
| SABnzbd API | enabled, key = `ALTMOUNT_API_KEY` | Radarr and Sonarr treat AltMount as a download client |
| Categories | `movies` (Radarr), `tv` (Sonarr) | Lets AltMount know who asked |
| Provider | from your credentials | Your Usenet account |

AltMount's web UI (`localhost:8080`) edits the same config file. Changes made there are kept. The installer only rewrites the file when you run **Credentials**, **Components** or **Rebuild**, and always backs up first to `config/.backups/`.

**Streams go through the host name in the `.strm` file.** By default it's `localhost`, which works for Jellyfin on the Mac. If a TV client can't play `.strm` links (some clients open the URL themselves instead of letting the server do it), enable **AltMount on LAN** in *Components*. That makes AltMount listen on your network and writes your Mac's IP into new `.strm` files.

> **AltMount on LAN has no login.** Anyone on your network could open it. Only enable it on a network you trust.

### Prowlarr

- Your indexers (NZBGeek and your second one) are added with their API keys.
- Radarr and Sonarr are registered as **apps** with full sync, so every indexer you add later is pushed to both.
- Add more indexers in Prowlarr's UI at any time. You never need to add them in Radarr or Sonarr.

### Radarr and Sonarr

- Root folders: `/data/library/movies` and `/data/library/tv`.
- Download client: **AltMount**, implementation *Sabnzbd*, host `altmount`, port `8080`, category `movies` or `tv`. The installer lets AltMount register itself once (so it picks the right API path), then sets the host to `altmount` and fills in the key and category.
- Quality profile: your 1080p profile (`HD-1080p`) is used by Seerr. With German formats on, custom-format scores are added to it ([04](04-german-content.md)).
- Naming: Radarr/Sonarr defaults. Change in *Settings → Media Management*.

**Cap quality at 1080p.** 4K remuxes are large, and a stream is only as fast as your line. On 40 Mbit/s, 1080p WEB-DL is the sweet spot. Edit the profile's allowed qualities if you want to exclude 2160p.

### Seerr

Seerr's config is pre-seeded with Radarr and Sonarr (host, API key, profile, root folder). You still sign in through the web UI with your Jellyfin account, which is the one step that needs *you*. Use `http://jellyfin:8096` as the Jellyfin URL.

### Bazarr

Pre-pointed at Radarr and Sonarr. Choose subtitle languages and providers in its UI, which is the part that's personal.

## Files the installer owns

| File | Contents | Secret? |
|---|---|---|
| `.env.local` | Provider and indexer logins, API keys | Yes, AES-256 encrypted |
| `.clezjelly.conf` | Which optional components you picked | No |
| `.env` | Compose variables (time zone, UID/GID, JWT secret, bind addresses) | Yes (mode 600, regenerated on each run) |
| `config/<service>/` | Each service's settings and database | Contains API keys |
| `logs/clezjelly.log` | Installer log | No secrets |

All of them are in `.gitignore`. Never edit `.env` by hand, because `./install.sh` rewrites it. To change a bind address or toggle a service, use **Components**.

## Tuning tips

- **Connections.** In AltMount's provider settings, keep *max connections* at or below what your plan allows (Eweka: 20). Too many causes `too many connections` errors.
- **Buffering.** If streams stutter, lower Jellyfin's client bitrate (see [05](05-samsung-tv.md)) before touching AltMount.
- **Update safely.** `./install.sh update` pulls new images. If something breaks afterwards, run **Re-link**. If that doesn't help, check the changelog of the service that updated.
- **Pin versions.** The compose file uses `:latest`. If you prefer pinned versions, replace the tags in `docker-compose.yml`. The installer doesn't overwrite that file.

## Resetting

| I want to… | Do |
|---|---|
| Repair connections | `./install.sh relink` |
| Re-seed all config files | `./install.sh rebuild` (backs up first, keeps databases and history) |
| Change provider/indexer | `./install.sh credentials` |
| Start completely over | See [06 · Troubleshooting](06-troubleshooting.md#start-over) |
