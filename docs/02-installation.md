# 02 · Installation

[← 01 · Prerequisites](01-prerequisites.md) · [README](../README.md) · Next: [03 · Configuration](03-configuration.md)

## Run the installer

One line:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/clezcoding/ClezJelly/main/scripts/quickstart.sh)
```

This clones ClezJelly to `~/Desktop/ClezJelly` and starts the menu. If the folder already exists it's updated instead. To use another location set `CLEZJELLY_TARGET_DIR` before the command.

Or do it by hand:

```bash
git clone https://github.com/clezcoding/ClezJelly.git ~/Desktop/ClezJelly
cd ~/Desktop/ClezJelly
./install.sh
```

![Installer menu](assets/installer-menu.png)

Choose **1 · Install**.

## What the installer asks

**Components.** Which optional services should be included? Defaults are sensible. See [Components](../README.md#choose-whats-included) for what each does. You can change all of it later.

**Credentials.** Provider login, indexer API key(s), and a **passphrase**. The passphrase encrypts your logins into `.env.local`. It is never stored. You'll be asked for it again whenever the installer needs your logins (relink, credential changes, rebuild).

> **Write the passphrase down.** There is no way to recover it. If you lose it you can still re-enter your logins with `./install.sh credentials`, but the old file is unreadable.

## What the installer does

| Phase | |
|---|---|
| **1 · Preflight** | Checks your Mac and tools. Offers to install missing pieces through Homebrew. |
| **2 · Setup** | Components and credentials, as above. |
| **3 · Folders & configs** | Creates `data/` and `config/`, writes fresh configs from `config-templates/`, generates API keys. |
| **4 · Containers** | Writes `.env`, starts the stack, waits for every service to report healthy. |
| **5 · Wiring** | Uses each service's API to connect them. See below. |

### The wiring phase

![Wiring phase](assets/installer-wiring.png)

In order:

1. **Prowlarr** gets your indexers, and Radarr and Sonarr are added as its apps, so indexers are pushed to them automatically.
2. **Radarr** gets the root folder `/data/library/movies` and AltMount as its download client (category `movies`).
3. **Sonarr** gets `/data/library/tv` and AltMount (category `tv`).
4. **AltMount** registers its import webhooks with Radarr and Sonarr.
5. **German formats** (if enabled) are added and scored on your 1080p profile.
6. **Seerr** (if enabled) is told about Radarr and Sonarr, with profile and folder.

Every step is **idempotent**: running it again never creates duplicates. If a step fails, the others still run, and the installer tells you which one. Fix the cause and choose **4 · Re-link**.

## The finish screen

When the installer is done, a ticket lists everything that's left for **you**, because only you can create your Jellyfin user:

1. **Jellyfin** (`http://localhost:8096`): finish the setup wizard and add two libraries:
   - Movies → `~/Desktop/ClezJelly/data/library/movies`
   - Shows → `~/Desktop/ClezJelly/data/library/tv`

   Then *Dashboard → Playback → Transcoding* → pick **Apple VideoToolbox**.
2. **Seerr** (`http://localhost:5055`): sign in with your Jellyfin account. The Jellyfin URL is `http://jellyfin:8096`. Radarr and Sonarr are already connected.
3. **TV**: install the Jellyfin app, server `http://<your-mac-ip>:8096`. See [05 · Samsung TV](05-samsung-tv.md).
4. *Optional:* **Bazarr** (`http://localhost:6767`): choose your subtitle languages and providers.

## Your first stream

1. Open Seerr, search for a movie, press **Request**.
2. Watch Radarr's *Activity* tab, or AltMount's dashboard. Within a minute the title is grabbed and a `.strm` file appears.
3. Jellyfin picks it up after Radarr's import notification (or run *Scan library*).
4. Press play.

## Day-to-day

```bash
./install.sh status   # is everything healthy?
./install.sh down     # stop the stack
./install.sh up       # start it again
./install.sh update   # newer images
```

After a Mac restart, run `./install.sh up`. It starts the containers and opens Jellyfin. For anything else, see [06 · Troubleshooting](06-troubleshooting.md).

## Uninstall

```bash
cd ~/Desktop/ClezJelly
./install.sh down
docker compose down            # removes containers and the network
```

Then delete the `ClezJelly` folder when you're sure you don't need `config/` (it holds your databases and settings) and take a [backup](#backup) first if in doubt. Jellyfin itself is a normal app: `brew uninstall --cask jellyfin`.

## Backup

`./install.sh backup` offers two choices:

- **Secrets only**: `.env.local` and `.clezjelly.conf`, copied to `~/ClezJelly-backups/secrets-<timestamp>`. Tiny, safe to keep in a password manager's attachments.
- **Full snapshot**: configs, library and secrets as one `.tar.gz`. Use this before big changes.

`./install.sh restore` brings the latest secrets backup back.
