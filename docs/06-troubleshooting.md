# 06 · Troubleshooting

[← 05 · Samsung TV](05-samsung-tv.md) · [README](../README.md)

## First aid

```bash
./install.sh status                 # every service, healthy or not
docker compose logs -f altmount     # live logs (also: radarr, sonarr, prowlarr, seerr, bazarr)
docker compose ps                   # what's running
tail -n 80 logs/clezjelly.log       # what the installer did
./install.sh relink                 # repair the connections (safe to repeat)
./install.sh down && ./install.sh up
```

Rule of thumb: **if one service can't see another, run Re-link first.** It re-checks every connection and fixes what's wrong.

---

## Installer

### "Docker isn't running"
Start OrbStack or Docker Desktop and wait until it says it's running, then run the installer again.

### A port is already in use
The preflight names the port and the program. Free it or stop that program. For example `lsof -i :8080`.

### "Wrong passphrase"
Passphrases are case-sensitive, and there's no reset. If it's truly gone, run `./install.sh credentials` and enter your logins again. The installer creates a new `.env.local`.

### A wiring step failed
The installer continues with the other steps and tells you which failed. Check `logs/clezjelly.log`, fix the cause (a typo in a key, a service still starting) and choose **Re-link**.

### "Legacy credentials file"
`.env.local` from an older ClezJelly version lacks newer keys. Run `./install.sh credentials` once to rewrite it.

---

## AltMount

### Provider authentication failed
- Username and password correct? Your plan still active?
- Max connections must not exceed your plan's limit (Eweka: 20).

### Many "too many connections" or 480 errors
Lower the max connections to about 10, and make sure nothing else is using your provider account.

### No `.strm` files appear in `data/strm/`
- AltMount web UI → *Configuration → Import*: import dir is `/data/strm`, strategy `STRM`.
- Check the logs: `docker compose logs altmount`.
- Permissions: the folder must be writable by your user.

### Streams buffer constantly
- Test directly: open `http://localhost:8080/` and play a file from the browser. If that's slow too, it's your line or provider.
- Lower the client's max bitrate ([05](05-samsung-tv.md)).
- In AltMount's provider settings, try fewer simultaneous connections.

---

## Prowlarr, Radarr, Sonarr

### Indexer test fails
- API key copied without spaces?
- Some indexers need `/api` at the end of the URL, some don't. Prowlarr has the right one built in. Choose the indexer from its list instead of "Generic Newznab".
- A VPN on the Mac can block indexers.

### "No download client available" or the download client test fails
- Host must be `altmount`, port `8080`. **Never `localhost`**: inside a container that's the container itself.
- API key must match AltMount's. Run **Re-link** to resync.
- Category: `movies` in Radarr and `tv` in Sonarr.

### Radarr/Sonarr find releases but nothing is grabbed
Check *Activity → Queue* and the logs. Common causes: wrong download client category, quality not allowed in the profile, or a release blocked by a custom format score below the profile's *minimum*.

### Prowlarr can't reach Radarr/Sonarr
Use `http://radarr:7878` and `http://sonarr:8989`, never `localhost`. Run **Re-link**.

---

## Jellyfin

### New titles don't show up
- *Dashboard → Scheduled tasks → Scan media library*, or the library's *Scan*.
- Check the Jellyfin library points to `~/Desktop/ClezJelly/data/library/movies` and `…/tv`.
- Look in Radarr/Sonarr that the title was actually imported (*Movies → the title → files*).

### STRM files don't play
A `.strm` file is a text file containing a URL. Look at one:

```bash
cat ~/Desktop/ClezJelly/data/library/movies/*/*.strm | head -n 3
```

Open that URL in your Mac's browser. It should start streaming or download bytes.

- **URL works on the Mac, but the TV doesn't play it:** the client opens the link itself. Turn on **AltMount on LAN** in `./install.sh components`. New `.strm` files then contain your Mac's IP. Titles imported earlier keep the old address; re-import them (Radarr/Sonarr → the title → *Rename* or delete and re-add) or edit the files.
- **URL doesn't work at all:** AltMount isn't running or can't reach your provider. See AltMount above.
- **URL contains `altmount`:** the host in AltMount's config is wrong. Run **Rebuild configs**.

### Hardware transcoding doesn't work
*Dashboard → Playback → Transcoding* → Hardware acceleration: **Apple VideoToolbox**. Then check *Dashboard → Logs* during playback. Update the app with `brew upgrade --cask jellyfin`.

### Server unreachable from the TV
See [05 · Samsung TV → Troubleshooting](05-samsung-tv.md#troubleshooting).

---

## Seerr

### Sign-in with Jellyfin fails
The Jellyfin URL in Seerr must be `http://jellyfin:8096`. If it still fails: is Jellyfin running on the Mac? Open `http://localhost:8096` to check, and make sure the macOS firewall isn't blocking Jellyfin.

### Requests don't reach Radarr/Sonarr
*Settings → Services*: host `radarr` / `sonarr`, port `7878` / `8989`, no SSL, correct API key, and a default profile plus root folder. If the pre-seeded settings were not picked up, add both once through the UI. Then use **Test**.

---

## Docker and macOS

### A container keeps restarting
```bash
docker compose logs --tail 80 <service>
```
Usual causes: a port conflict, a volume that can't be written, or too little memory (OrbStack/Docker → *Resources*).

### `docker compose pull` fails
Restart OrbStack/Docker. For rate limits, `docker login`.

### Slow file access
On Docker Desktop enable **VirtioFS** (*Settings → General*). OrbStack does this by default.

### I'm on an Intel Mac
Set `ALTMOUNT_IMAGE=ghcr.io/javi11/altmount:latest` in `.env`, then `./install.sh up`.

---

## Start over

This deletes your service databases and settings (not your Jellyfin app, not your secrets):

```bash
cd ~/Desktop/ClezJelly
./install.sh backup       # optional, but cheap insurance
./install.sh down
docker compose down
```

Then delete `config/` and `data/` in Finder (or with `rm -rf`, if you're sure), and run `./install.sh` again. Your encrypted `.env.local` can stay, so you only re-enter your passphrase.

---

## Getting help

- ClezJelly issues: <https://github.com/clezcoding/ClezJelly/issues> (attach the last lines of `logs/clezjelly.log`, **never your `.env*` files**)
- AltMount: <https://github.com/javi11/altmount>
- [Jellyfin forum](https://forum.jellyfin.org/) · [TRaSH Guides](https://trash-guides.info/) · r/jellyfin, r/radarr, r/sonarr, r/usenet
