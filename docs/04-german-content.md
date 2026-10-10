# 04 · German content

[← 03 · Configuration](03-configuration.md) · [README](../README.md) · Next: [05 · Samsung TV](05-samsung-tv.md)

How ClezJelly finds German-language releases, and how to make the most of them. If you don't need German, switch **German formats** off in *Components* and skip this page.

## The reality check

There is no dedicated German API indexer any more. The old ones (nzb.cat, SceneNZBs, Newz Complex) are gone. German releases still exist. They sit in general indexers, just without a "German" flag.

So the strategy is:

1. **Several general indexers in parallel.** NZBGeek plus one or two others. Prowlarr searches them all at once.
2. **Scoring by release name.** German releases carry tags like `GERMAN`, `GER` or `ML` (multi-language) in their names. Custom formats recognise these and boost the release.
3. **A fallback.** If no German release exists, you still get the English one, and Bazarr adds German subtitles.

## What the installer sets up

With **German formats** enabled, the wiring phase adds three custom formats to Radarr and Sonarr and scores them on your `HD-1080p` profile:

| Custom format | Matches | Score |
|---|---|---|
| **German DL** | German + English audio (Dual Language) | **+500** |
| **German Only** | German audio only | **+400** |
| **English** | English audio | **+100** |

A release that matches nothing scores 0 for language. In practice Radarr and Sonarr rank candidates like this:

> German DL (best) → German only → English → anything else

Dual-language releases win because you get both: German by default, English when you want the original.

You can see and edit all of it in *Settings → Custom Formats* and *Settings → Profiles → HD-1080p*. For a deeper setup, the [TRaSH Guides](https://trash-guides.info/) have German-specific profiles: <https://trash-guides.info/Radarr/radarr-setup-quality-profiles-german-en/> and the Sonarr equivalent.

Re-apply the formats any time with `./install.sh german`. It's safe to repeat.

## German metadata in Jellyfin

Titles, plots and posters come from the metadata language of each library:

*Dashboard → Libraries → (library) → Manage library → Metadata*

- Preferred language: **German**
- Country/region: **Austria** or **Germany**
- Save, then *Scan library* (use *Replace all metadata* once to refresh existing items)

In **Seerr**: *Settings → General →* **Display Language** and **Discover Region**. This changes what shows up in search.

## Subtitles with Bazarr

Open Bazarr (`http://localhost:6767`) and:

1. *Settings → Languages* → add **German** (and English if you like) to a language profile.
2. *Settings → Providers* → enable a few, such as OpenSubtitles.com (free account) and Subscene alternatives.
3. Assign the profile as default for series and movies.

Now every title gets German subtitles when no German audio exists.

## What's realistic

| Content | Chance of a German release |
|---|---|
| Big international series and films | Almost always, often Dual Language |
| German mainstream TV and crime series | Usually, better with 2–3 indexers |
| Netflix / Amazon originals | Often, sometimes delayed |
| Niche German productions | Hit and miss |
| 4K / UHD in German | Rare, and too heavy for a 40 Mbit/s line anyway |
| Live TV | Not covered. That's a different setup (TVHeadend) |

## Public broadcasters

ARD, ZDF and ORF media libraries have no clean Jellyfin integration. If you want them next to your library, [MediathekView](https://mediathekview.de/) can save shows from the public broadcasters into a folder. Point a third Jellyfin library at it. The broadcasters themselves offer these downloads, so this is a legitimate addition.
