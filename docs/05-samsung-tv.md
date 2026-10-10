# 05 · Samsung TV

[← 04 · German content](04-german-content.md) · [README](../README.md) · Next: [06 · Troubleshooting](06-troubleshooting.md)

Getting Jellyfin onto a Samsung Tizen TV. Other TV apps work the same way: install the Jellyfin app, enter the server address.

## 1. Install the app

1. Smart Hub → **Apps** → search **Jellyfin**
2. Install and open it

If it isn't listed for your model, see [Alternatives](#alternatives).

## 2. Find the Mac's address

```bash
ipconfig getifaddr en0     # Ethernet or Wi-Fi on most Macs
ipconfig getifaddr en1     # try this if en0 prints nothing
```

You'll get something like `192.168.1.42`. The installer's finish screen shows it too.

> Reserve this address for the Mac in your router (DHCP reservation). Otherwise it may change and your TV loses the server.

## 3. Connect

In the TV app, add the server manually:

```
http://192.168.1.42:8096
```

Sign in with the Jellyfin user you created. Done.

## 4. Playback settings

For a 40 Mbit/s line:

- **Maximum streaming bitrate:** 25 Mbit/s. That leaves room for everything else at home.
- **Auto quality:** on.

Streams run on demand from Usenet, so a stable line matters more than a high bitrate. If you see buffering, drop to 15 Mbit/s.

## 5. Check Direct Play

While a video plays, open the playback info (the "i" or *Playback info* menu):

| Play method | Meaning |
|---|---|
| **Direct Play** | Best. The TV plays the file as is. |
| **Direct Stream** | Fine. Only the container is repackaged. |
| **Transcode** | Works, but uses the Mac. Make sure *Apple VideoToolbox* is enabled in Jellyfin's playback settings. |

Capping quality at 1080p in Radarr/Sonarr keeps most titles at Direct Play on modern TVs.

## Remote access with Tailscale

Want to watch away from home without opening any port on your router? [Tailscale](https://tailscale.com/) builds a private encrypted network between your devices. The free plan is enough.

```bash
brew install --cask tailscale
```

1. Start Tailscale on the Mac and sign in.
2. Install Tailscale on your phone, sign in with the same account.
3. In the phone's Jellyfin app, use the Mac's Tailscale address: `http://<mac-tailscale-ip>:8096`.

No public domain, no port forwarding, nothing exposed. Don't put Jellyfin or any of the other services on the open internet.

## Troubleshooting

**The TV can't find the server**

- Same network? Many routers have a separate guest Wi-Fi that isolates devices.
- Try the address in a phone's browser on the same Wi-Fi: `http://<mac-ip>:8096`.
- macOS firewall: *System Settings → Network → Firewall*. Allow incoming connections for Jellyfin, or turn it off to test.
- The Mac may have gone to sleep. *System Settings → Battery/Energy* → prevent automatic sleep when the display is off.

**The app crashes or freezes**

- Delete and reinstall the app, then update the TV's firmware.
- Try the other client from [Alternatives](#alternatives).

**4K stutters**

Streaming 4K over a 40 Mbit/s line won't work smoothly. Limit your Radarr/Sonarr profiles to 1080p ([03](03-configuration.md)).

**A video won't play but others do**

Check [06 · Troubleshooting → STRM files](06-troubleshooting.md#jellyfin).

## Alternatives

- **Jellyfin on Samsung via Tizen sideload.** Newer builds sometimes land on GitHub before the store. Needs developer mode on the TV.
- **A streaming stick or box** (Apple TV, Fire TV, Android TV, Nvidia Shield). The Jellyfin apps there are generally more polished than on Tizen and support more codecs for Direct Play.
