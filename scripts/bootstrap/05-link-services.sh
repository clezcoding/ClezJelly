#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# Phase 5 · Wiring
#
# Connects the services through their REST APIs. New objects are cloned from
# the service's own /schema endpoint and only the relevant fields are filled
# in, so the payloads keep matching as the apps evolve. Existing objects are
# updated in place — running this twice never creates duplicates, and it
# repairs links after a key or credential change.
#
#   Prowlarr ← NZBGeek (+ 2nd indexer)       Radarr ← AltMount (SABnzbd API)
#   Prowlarr → Radarr, Sonarr (apps)         Sonarr ← AltMount (SABnzbd API)
#   Radarr / Sonarr: root folders            AltMount → import webhooks
# ──────────────────────────────────────────────────────────────────

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
[[ -z "${CLEZJELLY_API_LOADED:-}" ]]    && source "$(dirname "${BASH_SOURCE[0]}")/../lib/api.sh"

PROWLARR_URL="http://localhost:9696"
RADARR_URL="http://localhost:7878"
SONARR_URL="http://localhost:8989"
ALTMOUNT_URL="http://localhost:8080"

API_UPDATED=11

# _report <label> <rc>
_report() {
  case "$2" in
    0)  log_ok "$1" ;;
    10) log_info "$1 — already there" ;;
    11) log_ok "$1 — synced" ;;
    *)  log_warn "$1 — failed (details in $UI_LOG)" ;;
  esac
}

# _upsert <collection_url> <schema_url> <api_key> <name> <implementation>
# Caller sets JQ_ARGS (array of jq --arg/--argjson pairs) and JQ_FILTER first.
#   exists  → PUT the transformed item      (returns 11)
#   missing → clone from schema, then POST  (returns 0)
_upsert() {
  local coll="$1" schema_url="$2" key="$3" name="$4" impl="$5"
  local existing id item schema payload
  existing="$(arr_request GET "$coll" "$key")" || return 1
  id="$(jq -r --arg n "$name" 'first(.[] | select(.name == $n) | .id) // empty' <<<"$existing")"

  if [[ -n "$id" ]]; then
    item="$(jq -c --argjson id "$id" 'first(.[] | select(.id == $id))' <<<"$existing")" || return 1
    payload="$(jq -c "${JQ_ARGS[@]}" "$JQ_FILTER" <<<"$item")" || return 1
    arr_request PUT "$coll/$id?forceSave=true" "$key" "$payload" >/dev/null || return 1
    return $API_UPDATED
  fi

  schema="$(arr_request GET "$schema_url" "$key")" || return 1
  item="$(jq -c --arg impl "$impl" '[.[] | select(.implementation == $impl)] | first | del(.presets)' <<<"$schema")" || return 1
  [[ -n "$item" && "$item" != "null" ]] || { echo "no schema for $impl at $schema_url" >>"$UI_LOG"; return 1; }
  payload="$(jq -c "${JQ_ARGS[@]}" "$JQ_FILTER" <<<"$item")" || return 1
  arr_request POST "$coll?forceSave=true" "$key" "$payload" >/dev/null || return 1
}

# ── Prowlarr ──────────────────────────────────────────────────────

# link_indexer <name> <base_url> <api_key>
link_indexer() {
  local name="$1" url="$2" key="$3" profile
  profile="$(arr_request GET "$PROWLARR_URL/api/v1/appprofile" "$PROWLARR_API_KEY" | jq -r '.[0].id // 1' 2>/dev/null || echo 1)"
  JQ_ARGS=(--arg name "$name" --arg url "${url%/}" --arg key "$key" --argjson profile "${profile:-1}")
  JQ_FILTER='
    .name = $name | .enable = true | .priority = 25 | .appProfileId = $profile | .tags = []
    | .fields |= map(
        if   .name == "baseUrl" then .value = $url
        elif .name == "apiPath" then .value = "/api"
        elif .name == "apiKey"  then .value = $key
        else . end)'
  _upsert "$PROWLARR_URL/api/v1/indexer" "$PROWLARR_URL/api/v1/indexer/schema" "$PROWLARR_API_KEY" "$name" "Newznab"
}

# link_prowlarr_app <Radarr|Sonarr> <internal_base_url> <api_key>
link_prowlarr_app() {
  local impl="$1" base="$2" key="$3"
  JQ_ARGS=(--arg name "$impl" --arg base "$base" --arg key "$key")
  JQ_FILTER='
    .name = $name | .syncLevel = "fullSync" | .tags = []
    | .fields |= map(
        if   .name == "prowlarrUrl" then .value = "http://prowlarr:9696"
        elif .name == "baseUrl"     then .value = $base
        elif .name == "apiKey"      then .value = $key
        else . end)'
  _upsert "$PROWLARR_URL/api/v1/applications" "$PROWLARR_URL/api/v1/applications/schema" "$PROWLARR_API_KEY" "$impl" "$impl"
}

# ── Radarr / Sonarr ───────────────────────────────────────────────

# link_root_folder <base_url> <api_key> <path>
link_root_folder() {
  local base="$1" key="$2" path="$3" existing
  existing="$(arr_request GET "$base/api/v3/rootfolder" "$key")" || return 1
  if jq -e --arg p "$path" 'any(.[]; .path == $p or .path == ($p + "/"))' <<<"$existing" >/dev/null 2>&1; then
    return $API_EXISTS
  fi
  arr_request POST "$base/api/v3/rootfolder" "$key" "$(jq -nc --arg p "$path" '{path: $p}')" >/dev/null || return 1
}

# AltMount can register itself as a SABnzbd client in Radarr/Sonarr
# (POST /api/arrs/download-client/register). We let it do that once and then
# read the URL base it chose, so we never have to guess AltMount's API path.
ALTMOUNT_REG_DONE=0
altmount_register_client() {
  [[ "$ALTMOUNT_REG_DONE" == "1" ]] && return 0
  ALTMOUNT_REG_DONE=1
  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 -X POST "$ALTMOUNT_URL/api/arrs/download-client/register" 2>>"$UI_LOG" || echo 000)"
  printf 'AltMount self-register → HTTP %s\n' "$code" >>"$UI_LOG"
  [[ "$code" =~ ^2 ]]
}

# URL base of the SABnzbd client AltMount registered in <arr base> (prints it, may be empty)
_registered_urlbase() {
  local base="$1" key="$2" list ub
  list="$(arr_request GET "$base/api/v3/downloadclient" "$key")" || return 1
  ub="$(jq -r '[.[] | select(.implementation == "Sabnzbd") | .fields[]? | select(.name == "urlBase") | .value][0] // "__none__"' <<<"$list" 2>/dev/null)" || return 1
  [[ "$ub" == "__none__" ]] && return 1
  printf '%s' "$ub"
}

# Fallback: probe the usual paths for SABnzbd's "version" call.
# Radarr/Sonarr call <urlBase>/api, so /sabnzbd/api -> urlBase "/sabnzbd".
altmount_sab_urlbase() {
  local base resp
  for base in "/sabnzbd" "/api/sabnzbd" "" "/api"; do
    resp="$(curl -s --max-time 8 "$ALTMOUNT_URL${base}/api?mode=version&output=json&apikey=$ALTMOUNT_API_KEY" 2>>"$UI_LOG" || true)"
    if jq -e 'has("version")' <<<"$resp" >/dev/null 2>&1; then
      printf '%s' "$base"; return 0
    fi
    printf 'SAB probe %s/api -> %.80s\n' "$base" "$resp" >>"$UI_LOG"
  done
  return 1
}

# link_download_client <base_url> <api_key> <category_field> <category>
# category_field: movieCategory (Radarr) or tvCategory (Sonarr)
link_download_client() {
  local base="$1" key="$2" catfield="$3" cat="$4" ub
  altmount_register_client || true
  ub="$(_registered_urlbase "$base" "$key")" \
    || ub="$(altmount_sab_urlbase)" \
    || { printf 'AltMount SABnzbd API not found: self-register and probes failed\n' >>"$UI_LOG"; return 1; }
  JQ_ARGS=(--arg key "$ALTMOUNT_API_KEY" --arg catfield "$catfield" --arg cat "$cat" --arg ub "$ub")
  JQ_FILTER='
    .name = "AltMount" | .enable = true | .priority = 1 | .tags = []
    | .fields |= map(
        if   .name == "host"    then .value = "altmount"
        elif .name == "port"    then .value = 8080
        elif .name == "useSsl"  then .value = false
        elif .name == "urlBase" then .value = $ub
        elif .name == "apiKey"  then .value = $key
        elif .name == $catfield then .value = $cat
        else . end)'
  _upsert "$base/api/v3/downloadclient" "$base/api/v3/downloadclient/schema" "$key" "AltMount" "Sabnzbd"
}

# ── AltMount ──────────────────────────────────────────────────────

# Ask AltMount to register its import webhooks in Radarr/Sonarr
altmount_register_webhooks() {
  local code
  code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 -X POST "$ALTMOUNT_URL/api/arrs/webhook/register" 2>>"$UI_LOG" || echo 000)"
  [[ "$code" =~ ^2 ]] || { printf 'webhook register → HTTP %s\n' "$code" >>"$UI_LOG"; return 1; }
}

# ── Orchestration ─────────────────────────────────────────────────

# Records every ✓ / ▲ / ✗ of the wiring phase for the guide page
services_link() {
  local rc=0
  UI_RESULTS="$CLEZJELLY_ROOT/logs/last-wiring.tsv"; export UI_RESULTS
  : > "$UI_RESULTS"
  _services_link_run || rc=$?
  UI_RESULTS=""; export UI_RESULTS
  return $rc
}

_services_link_run() {
  ui_phase 5 5 "Wiring"
  local rc
  cd "$CLEZJELLY_ROOT" || return 1

  if ! command -v jq &>/dev/null; then
    log_err "jq is required for this step (brew install jq)."
    return 1
  fi

  # ── Prowlarr ──
  log_step "Prowlarr · indexers"
  rc=0; link_indexer "NZBGeek" "$NZBGEEK_URL" "$NZBGEEK_API_KEY" || rc=$?
  _report "NZBGeek" "$rc"
  if [[ -n "${INDEXER2_NAME:-}" ]]; then
    rc=0; link_indexer "$INDEXER2_NAME" "$INDEXER2_URL" "$INDEXER2_API_KEY" || rc=$?
    _report "$INDEXER2_NAME" "$rc"
  fi

  log_step "Prowlarr · apps"
  rc=0; link_prowlarr_app "Radarr" "http://radarr:7878" "$RADARR_API_KEY" || rc=$?
  _report "Radarr  → http://radarr:7878" "$rc"
  rc=0; link_prowlarr_app "Sonarr" "http://sonarr:8989" "$SONARR_API_KEY" || rc=$?
  _report "Sonarr  → http://sonarr:8989" "$rc"
  if arr_request POST "$PROWLARR_URL/api/v1/command" "$PROWLARR_API_KEY" \
       '{"name":"ApplicationIndexerSync"}' >/dev/null; then
    log_ok "Indexers pushed to Radarr and Sonarr"
  fi

  # ── Radarr ──
  log_step "Radarr"
  rc=0; link_root_folder "$RADARR_URL" "$RADARR_API_KEY" "/data/library/movies" || rc=$?
  _report "Root folder /data/library/movies" "$rc"
  rc=0; link_download_client "$RADARR_URL" "$RADARR_API_KEY" "movieCategory" "movies" || rc=$?
  _report "Download client AltMount (altmount:8080 · movies)" "$rc"

  # ── Sonarr ──
  log_step "Sonarr"
  rc=0; link_root_folder "$SONARR_URL" "$SONARR_API_KEY" "/data/library/tv" || rc=$?
  _report "Root folder /data/library/tv" "$rc"
  rc=0; link_download_client "$SONARR_URL" "$SONARR_API_KEY" "tvCategory" "tv" || rc=$?
  _report "Download client AltMount (altmount:8080 · tv)" "$rc"

  # ── AltMount ──
  log_step "AltMount"
  if altmount_register_webhooks; then
    log_ok "Import webhooks registered in Radarr and Sonarr"
  else
    log_warn "Couldn't register webhooks — in AltMount: Settings → ARRs → Register Webhooks"
  fi

  # ── Optional parts ──
  if [[ "$ENABLE_GERMAN" == "true" ]]; then german_formats_apply; fi
  if [[ "$ENABLE_SEERR" == "true" ]];  then seerr_prewire; fi
}
