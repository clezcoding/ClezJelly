#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# Seerr pre-wiring
#
# Seerr's first-run wizard asks for Jellyfin credentials, which only you
# have. Everything else can be prepared: this adds Radarr and Sonarr
# (hostname, API key, quality profile, root folder) to Seerr's settings so
# the wizard just shows them as already connected.
#
# Seerr is stopped while its settings.json is edited, then started again.
# ──────────────────────────────────────────────────────────────────

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
[[ -z "${CLEZJELLY_API_LOADED:-}" ]]    && source "$(dirname "${BASH_SOURCE[0]}")/../lib/api.sh"

# _profile <base_url> <api_key> <wanted_name>  → prints "id<TAB>name"
_pick_profile() {
  local base="$1" key="$2" wanted="$3" profiles
  profiles="$(arr_request GET "$base/api/v3/qualityprofile" "$key")" || return 1
  jq -r --arg n "$wanted" '((first(.[] | select(.name == $n))) // .[0]) | "\(.id)\t\(.name)"' <<<"$profiles"
}

seerr_prewire() {
  log_step "Seerr"
  local wanted line rid rname sid sname settings tmp
  settings="$CLEZJELLY_ROOT/config/seerr/settings.json"

  case "${QUALITY_PROFILE:-1080p-webdl}" in
    2160p-webdl) wanted="Ultra-HD" ;;
    720p-webdl)  wanted="HD-720p" ;;
    *)           wanted="HD-1080p" ;;
  esac

  line="$(_pick_profile "$RADARR_URL" "$RADARR_API_KEY" "$wanted")" || { log_warn "Radarr profiles unavailable — add Radarr in Seerr's wizard"; return 0; }
  rid="${line%%$'\t'*}"; rname="${line#*$'\t'}"
  line="$(_pick_profile "$SONARR_URL" "$SONARR_API_KEY" "$wanted")" || { log_warn "Sonarr profiles unavailable — add Sonarr in Seerr's wizard"; return 0; }
  sid="${line%%$'\t'*}"; sname="${line#*$'\t'}"

  # Make sure Seerr has written its default settings.json at least once
  local waited=0
  while [[ ! -f "$settings" && "$waited" -lt 30 ]]; do sleep 1; waited=$((waited + 1)); done
  if [[ ! -f "$settings" ]]; then echo '{}' > "$settings"; fi

  docker compose stop seerr >>"$UI_LOG" 2>&1 || true

  tmp="$(mktemp)"
  if jq \
      --arg rkey "$RADARR_API_KEY" --argjson rid "$rid" --arg rname "$rname" \
      --arg skey "$SONARR_API_KEY" --argjson sid "$sid" --arg sname "$sname" '
      .main.applicationTitle = "ClezJelly"
      | .radarr = [{
          id: 0, name: "Radarr", hostname: "radarr", port: 7878, apiKey: $rkey,
          useSsl: false, baseUrl: "", activeProfileId: $rid, activeProfileName: $rname,
          activeDirectory: "/data/library/movies", is4k: false, minimumAvailability: "released",
          tags: [], isDefault: true, syncEnabled: false, preventSearch: false }]
      | .sonarr = [{
          id: 0, name: "Sonarr", hostname: "sonarr", port: 8989, apiKey: $skey,
          useSsl: false, baseUrl: "", activeProfileId: $sid, activeProfileName: $sname,
          activeDirectory: "/data/library/tv", is4k: false, enableSeasonFolders: true,
          seriesType: "standard", animeSeriesType: "anime",
          tags: [], animeTags: [], isDefault: true, syncEnabled: false, preventSearch: false }]
      ' "$settings" > "$tmp" 2>>"$UI_LOG"; then
    cat "$tmp" > "$settings"
    log_ok "Radarr → radarr:7878 · profile \"$rname\" · /data/library/movies"
    log_ok "Sonarr → sonarr:8989 · profile \"$sname\" · /data/library/tv"
  else
    log_warn "Couldn't edit Seerr's settings — add Radarr/Sonarr in its wizard (hosts: radarr, sonarr)"
  fi
  rm -f "$tmp"

  docker compose start seerr >>"$UI_LOG" 2>&1 || log_warn "Seerr didn't restart — run: docker compose up -d"
}
