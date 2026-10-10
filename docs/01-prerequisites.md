# 01 · Prerequisites

[← README](../README.md) · Next: [02 · Installation](02-installation.md)

Everything you need *before* running the installer. It takes about 15 minutes, most of it waiting for sign-up emails.

## Hardware and network

| What | Needed |
|---|---|
| **Mac** | Apple Silicon recommended (M1 or newer), macOS Sonoma or newer |
| **Free disk space** | About 10 GB for container images and configs. Media itself is streamed, not stored. |
| **RAM** | 8 GB works, 16 GB is comfortable |
| **Internet** | 40 Mbit/s or more for 1080p streams |
| **TV or player** | Anything that runs a Jellyfin app (Samsung Tizen, LG, Android TV, Apple TV, …) |

Put the Mac and the TV on the **same network**, and give the Mac a **fixed IP** (DHCP reservation in your router). You never need to open ports to the internet.

## Software

The installer checks all of this and tells you what's missing.

| Software | Check | Install |
|---|---|---|
| **Homebrew** | `brew --version` | [brew.sh](https://brew.sh) |
| **OrbStack** or **Docker Desktop** | `docker --version` | `brew install --cask orbstack` (lighter, recommended) or `brew install --cask docker` |
| **Jellyfin** (native app) | `ls /Applications/Jellyfin.app` | `brew install --cask jellyfin` |
| `openssl`, `curl`, `jq` | `jq --version` | `brew install jq` (the others ship with macOS) |

Why is Jellyfin *not* in Docker? On macOS a native Jellyfin can use Apple's VideoToolbox for hardware transcoding. In a container it can't.

## Accounts

You need two things: a **Usenet provider** (the pipe) and at least one **indexer** (the search engine).

### 1. Usenet provider (required)

[**Eweka**](https://www.eweka.nl/) is what ClezJelly is tuned for. It has a fast EU backbone and very long retention. Any provider works, though.

After signing up, note down:

- Server: `news.eweka.nl` (SSL port `563`)
- Username and password

The installer asks for these. A plan with unlimited traffic is the sensible choice, since every stream is a download.

### 2. Indexer (required)

[**NZBGeek**](https://nzbgeek.info/) is a solid all-rounder and the default in the installer. From your profile, note down:

- Your **API key**

### 3. Second indexer (recommended)

More indexers means more chances of finding a release, especially German ones. The installer lets you enter a second one. Pick whichever you can get into:

| Indexer | Signup | Notes |
|---|---|---|
| DrunkenSlug | Invite only | Very good quality. Check [r/UsenetInvites](https://reddit.com/r/UsenetInvites) |
| NZBPlanet | Often open | Paid |
| NZB.su | Open | Free or donation |
| DogNZB | Invite only, sometimes open | Good quality |
| NinjaCentral | Short open windows on holidays | Cheap |
| NZBFinder | Sometimes open | Paid |

Three indexers is the sweet spot. More adds little and can hit rate limits.

> Indexer availability changes all the time. If one is closed when you read this, any other works. You can add or change indexers later with `./install.sh credentials`.

### 4. Optional: German boards

For rare German releases that no API indexer lists, a board account (Sky of Usenet, Brothers of Usenet, House of Usenet) lets you search by hand and upload the NZB in AltMount's web UI. This is entirely optional.

## Checklist

Before you start the installer:

- [ ] Mac and TV are on the same network
- [ ] Homebrew works (`brew --version`)
- [ ] OrbStack or Docker Desktop is installed and **running**
- [ ] Usenet provider login at hand
- [ ] Indexer API key(s) at hand
- [ ] Jellyfin app installed on your TV

All set? On to [02 · Installation](02-installation.md).
