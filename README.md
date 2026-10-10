<h1 align="center">ClezJelly</h1>

<p align="center">
  <b>Your own streaming service on a Mac.</b><br>
  Jellyfin + Usenet + automatic library. Nothing is downloaded. Everything is streamed.
</p>

<p align="center">
  <a href="README.de.md">Deutsch</a> ·
  <a href="docs/01-prerequisites.md">Prerequisites</a> ·
  <a href="docs/02-installation.md">Install</a> ·
  <a href="docs/03-configuration.md">Configuration</a> ·
  <a href="docs/06-troubleshooting.md">Troubleshooting</a>
</p>

<p align="center">
  <img alt="macOS" src="https://img.shields.io/badge/macOS-Apple%20Silicon-a78bfa">
  <img alt="Shell" src="https://img.shields.io/badge/shell-bash%203.2-f472b6">
  <img alt="Docker" src="https://img.shields.io/badge/docker-compose-5fd787">
  <img alt="License" src="https://img.shields.io/badge/license-MIT-lightgrey">
</p>

---

## What is this?

ClezJelly turns a spare Mac into a private streaming service. You ask for a movie or a show, and a few seconds later it's in Jellyfin, playable on your TV. No downloads fill your disk, because the library is made of tiny `.strm` pointer files and the video is streamed straight from Usenet when you press play.

One installer sets up **six services**, connects all of them to each other, and fills in every API key, folder and quality rule. You answer a few questions. That's it.

<p align="center">
  <img src="docs/assets/installer-menu.png" alt="The ClezJelly installer menu" width="520">
</p>

### What you get

| Service | Job | Address |
|---|---|---|
| **Jellyfin** | Media server and apps for your TV (native macOS app) | `localhost:8096` |
| **AltMount** | Reads Usenet, writes `.strm` files, plays like a download client | `localhost:8080` |
| **Radarr** | Finds and organizes movies | `localhost:7878` |
| **Sonarr** | Finds and organizes series | `localhost:8989` |
| **Prowlarr** | Manages your indexers once, shares them with Radarr and Sonarr | `localhost:9696` |
| **Seerr** *(optional)* | "Netflix-style" request page for you and your household | `localhost:5055` |
| **Bazarr** *(optional)* | Subtitles | `localhost:6767` |

---

## How it works

<p align="center">
  <img src="docs/assets/flow.svg" alt="How a request becomes a stream" width="900">
</p>

1. You pick a title in **Seerr** (or directly in Radarr / Sonarr).
2. **Radarr** or **Sonarr** asks **Prowlarr** to search your indexers.
3. The best release, by your quality rules, goes to **AltMount** as if it were a download client.
4. AltMount checks the files on **Usenet** (via your provider) but doesn't download them.
5. It writes a tiny `.strm` file into the library. Radarr / Sonarr rename and import it.
6. **Jellyfin** sees the new title. You press play, and the video streams from Usenet on demand.

Your disk only holds `.strm` files and config. A whole season is a few kilobytes.

---

## Quick start

You need a Mac with Homebrew, a container runtime, a Usenet provider and one indexer. The [prerequisites guide](docs/01-prerequisites.md) walks through all of it.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/clezcoding/ClezJelly/main/scripts/quickstart.sh)
```

That clones the project to **`~/Desktop/ClezJelly`** and opens the installer. Prefer to look first?

```bash
git clone https://github.com/clezcoding/ClezJelly.git ~/Desktop/ClezJelly
cd ~/Desktop/ClezJelly
./install.sh
```

The installer is a menu. Choose **1 · Install** and it runs five phases:

| Phase | What happens |
|---|---|
| **1 · Preflight** | Checks macOS, Homebrew, Docker/OrbStack, Jellyfin, free ports |
| **2 · Setup** | You pick the components (Seerr, Bazarr, German formats, LAN access) and enter provider and indexer logins, stored encrypted |
| **3 · Folders & configs** | Creates `data/` and `config/`, writes a fresh config for every service |
| **4 · Containers** | Starts everything and waits until it's healthy |
| **5 · Wiring** | Connects all services with each other through their APIs |

<p align="center">
  <img src="docs/assets/installer-wiring.png" alt="The wiring phase of the installer" width="560">
</p>

When it finishes you get a "ticket" with every address. Open Jellyfin, create your user, add the two libraries (the installer tells you the folders), and you're done. See the [installation guide](docs/02-installation.md) for the click-by-click.

---

## One network, one data folder

Every container joins a private network called `clezjelly`. They reach each other by plain names, so there are no IP addresses to remember: `http://radarr:7878`, `http://altmount:8080`, `http://prowlarr:9696`.

Jellyfin runs natively on macOS for hardware transcoding, so containers reach it by the name `jellyfin` as well.

<p align="center">
  <img src="docs/assets/network.svg" alt="Network and volumes" width="900">
</p>

All containers that touch media see the **same folder at the same path**. That's why Radarr, Sonarr, AltMount and Bazarr never get confused about where a file lives.

```
data/
├─ strm/            AltMount drops .strm files here
└─ library/
   ├─ movies/       Radarr root folder  →  Jellyfin "Movies"
   └─ tv/           Sonarr root folder  →  Jellyfin "Shows"
config/<service>/   one private config folder per service
```

---

## Everyday use

```bash
./install.sh            # the menu
./install.sh status     # health of every service
./install.sh up         # start (also launches Jellyfin)
./install.sh down       # stop
./install.sh update     # pull newer images, recreate changed containers
./install.sh backup     # secrets only, or a full snapshot
```

<details>
<summary><b>All commands</b></summary>

| Command | Does |
|---|---|
| `install` | Guided first-time setup |
| `components` | Turn Seerr, Bazarr, German formats, LAN access on or off |
| `credentials` | Change provider or indexer logins |
| `relink` | Repair the connections between services (safe to repeat) |
| `german` | (Re)apply the German quality formats |
| `rebuild` | Re-seed config files from templates (your files are backed up first) |
| `status` | Check every service |
| `up` / `down` / `update` | Control the stack |
| `backup` / `restore` | Secrets or full snapshot, stored in `~/ClezJelly-backups` |
| `help` | Show this list |

The scripts in `scripts/` (`start-stack.sh`, `stop-stack.sh`, `update-stack.sh`, `health-check.sh`) are thin wrappers around the same commands.

</details>

---

## Choose what's included

The menu has a **Components** screen. Everything is optional except the core four.

| Component | Default | Notes |
|---|---|---|
| Seerr | on | Request page for your household |
| Bazarr | on | Subtitles |
| German formats | on | Scores German releases higher ([details](docs/04-german-content.md)) |
| Seerr on LAN | on | Reachable by phones and tablets in your home |
| AltMount on LAN | **off** | Only needed if a Jellyfin client can't play `.strm` links, see [troubleshooting](docs/06-troubleshooting.md) |
| Open Jellyfin when done | on | Launches the app after install |

Your choices are saved in `.clezjelly.conf` and can be changed any time. Turning something off removes its container but keeps its config.

---

## Security

ClezJelly is built so that you can put the repo on GitHub without leaking anything.

- **Secrets are encrypted.** Provider and indexer logins live in `.env.local`, encrypted with AES-256 (PBKDF2, 200,000 iterations) and your passphrase. Nothing is stored in plain text.
- **Nothing personal is committed.** `.env`, `.env.local`, `.clezjelly.conf`, `config/` and `data/` are all in `.gitignore`.
- **Local by default.** Ports bind to `127.0.0.1`. Only Seerr is opened to your home network, and only if you leave that option on.
- **Fresh keys per install.** Every service API key and the AltMount login secret are generated randomly on your Mac.
- **Files are private.** Generated files are `chmod 600`, the backup folder `700`.
- **No cloud, no tracking.** The installer talks to your own services and to Homebrew and Docker registries. Nothing else.

> Don't expose these ports to the internet. For remote viewing use [Tailscale](docs/05-samsung-tv.md#remote-access-with-tailscale).

Back up `.env.local` **and** remember your passphrase. Without it the file can't be recovered.

---

## Honest notes

- ClezJelly drives the real APIs of Radarr, Sonarr, Prowlarr and AltMount. Those projects change over time. If a wiring step fails after an update, **Re-link** is safe to run again and the log at `logs/clezjelly.log` says what went wrong.
- The Seerr and Bazarr pre-configuration writes their config files directly. Both are best-effort. If one doesn't pick up the settings, its web UI walks you through the same steps in a minute.
- The default AltMount image is the Apple Silicon build. On Intel set `ALTMOUNT_IMAGE=ghcr.io/javi11/altmount:latest` in `.env`.
- You are responsible for what you stream and for following the law where you live. Use this with content you have the right to access.

---

## Project layout

```
ClezJelly/
├─ install.sh                 menu and CLI
├─ docker-compose.yml         the six services, one network
├─ config-templates/          seed configs (AltMount, Prowlarr, Radarr, Sonarr, Bazarr)
├─ scripts/
│  ├─ quickstart.sh           one-line install
│  ├─ bootstrap/              the five installer phases, one file each
│  └─ lib/                    UI, prompts, crypto, API helpers
└─ docs/                      guides and diagrams
```

## Guides

| | |
|---|---|
| [01 · Prerequisites](docs/01-prerequisites.md) | Accounts and software you need first |
| [02 · Installation](docs/02-installation.md) | The installer, step by step |
| [03 · Configuration](docs/03-configuration.md) | What was set up, and how to tune it |
| [04 · German content](docs/04-german-content.md) | Getting German releases and metadata |
| [05 · Samsung TV](docs/05-samsung-tv.md) | Tizen app, bitrate, remote access |
| [06 · Troubleshooting](docs/06-troubleshooting.md) | When something doesn't work |

## Credits

Built on the work of [Jellyfin](https://jellyfin.org/), [AltMount](https://github.com/javi11/altmount), [Radarr](https://radarr.video/), [Sonarr](https://sonarr.tv/), [Prowlarr](https://prowlarr.com/), [Seerr](https://github.com/seerr-team/seerr), [Bazarr](https://www.bazarr.media/), and the [TRaSH Guides](https://trash-guides.info/).

## License

[MIT](LICENSE)
