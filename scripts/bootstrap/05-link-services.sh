#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# Phase 5: Services via API verknüpfen
#
# Prowlarr:
#   - NZBGeek-Indexer hinzufügen
#   - (optional) zweiter Indexer
#   - Radarr + Sonarr als Apps
#   - Sync Indexers
# Radarr/Sonarr:
#   - Root Folder
#   - AltMount als Download Client (SABnzbd-API)
#   - Jellyfin Connect
# Bazarr: Konfig via config.ini — kein zusätzlicher API-Call nötig
# Seerr: braucht Jellyfin-Login — manuell
# ──────────────────────────────────────────────────────────────────

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
[[ -z "${CLEZJELLY_API_LOADED:-}" ]]    && source "$(dirname "${BASH_SOURCE[0]}")/../lib/api.sh"

PROWLARR_URL="http://localhost:9696"
RADARR_URL="http://localhost:7878"
SONARR_URL="http://localhost:8989"
ALTMOUNT_URL="http://localhost:8080"

link_prowlarr_indexer() {
  local name="$1"
  local base_url="$2"
  local api_key="$3"
  local def_name="${4:-Newznab}"  # Prowlarr-Indexer-Definition

  local payload
  payload=$(cat <<EOF
{
  "name": "$name",
  "fields": [
    {"name": "baseUrl", "value": "$base_url"},
    {"name": "apiKey", "value": "$api_key"},
    {"name": "categories", "value": [2000,5000,5030,5040,5045]}
  ],
  "configContract": "NewznabSettings",
  "implementation": "Newznab",
  "implementationName": "Newznab",
  "protocol": "usenet",
  "enable": true,
  "priority": 25,
  "appProfileId": 1
}
EOF
  )
  arr_api_call POST "$PROWLARR_URL/api/v1/indexer" "$PROWLARR_API_KEY" "$payload" | head -c 100
}

link_prowlarr_app() {
  local name="$1"
  local url="$2"
  local api_key="$3"
  local app_name="$4"  # Radarr / Sonarr

  local payload
  payload=$(cat <<EOF
{
  "name": "$name",
  "syncLevel": "fullSync",
  "fields": [
    {"name": "prowlarrUrl", "value": "http://prowlarr:9696"},
    {"name": "baseUrl", "value": "$url"},
    {"name": "apiKey", "value": "$api_key"},
    {"name": "syncCategories", "value": [2000,5000,5030,5040,5045]}
  ],
  "implementation": "$app_name",
  "implementationName": "$app_name",
  "configContract": "${app_name}Settings"
}
EOF
  )
  arr_api_call POST "$PROWLARR_URL/api/v1/applications" "$PROWLARR_API_KEY" "$payload" | head -c 100
}

link_arr_download_client() {
  local arr_url="$1"
  local arr_api_key="$2"
  local category="$3"  # movies oder tv
  local api_version="${4:-v3}"

  local payload
  payload=$(cat <<EOF
{
  "enable": true,
  "protocol": "usenet",
  "priority": 1,
  "name": "AltMount",
  "fields": [
    {"name": "host", "value": "altmount"},
    {"name": "port", "value": 8080},
    {"name": "useSsl", "value": false},
    {"name": "urlBase", "value": ""},
    {"name": "apiKey", "value": "$ALTMOUNT_SAB_API_KEY"},
    {"name": "movieCategory", "value": "$category"},
    {"name": "tvCategory", "value": "$category"},
    {"name": "recentTvPriority", "value": -100},
    {"name": "olderTvPriority", "value": -100},
    {"name": "recentMoviePriority", "value": -100},
    {"name": "olderMoviePriority", "value": -100}
  ],
  "implementation": "Sabnzbd",
  "implementationName": "SABnzbd",
  "configContract": "SabnzbdSettings"
}
EOF
  )
  arr_api_call POST "$arr_url/api/$api_version/downloadclient" "$arr_api_key" "$payload" | head -c 100
}

link_arr_root_folder() {
  local arr_url="$1"
  local arr_api_key="$2"
  local path="$3"
  local api_version="${4:-v3}"

  arr_api_call POST "$arr_url/api/$api_version/rootfolder" "$arr_api_key" \
    "{\"path\": \"$path\"}" | head -c 100
}

services_link() {
  log_header "Phase 5 · Services verknüpfen (API)"

  # ── Prowlarr: Indexer hinzufügen ────────────────────────────────
  log_step "Prowlarr: NZBGeek Indexer"
  link_prowlarr_indexer "NZBGeek" "$NZBGEEK_URL" "$NZBGEEK_API_KEY" >/dev/null
  log_ok "NZBGeek hinzugefügt"

  if [[ -n "$INDEXER2_NAME" ]]; then
    log_step "Prowlarr: $INDEXER2_NAME Indexer"
    link_prowlarr_indexer "$INDEXER2_NAME" "$INDEXER2_URL" "$INDEXER2_API_KEY" >/dev/null
    log_ok "$INDEXER2_NAME hinzugefügt"
  fi

  # ── Prowlarr: Radarr + Sonarr als Apps ──────────────────────────
  log_step "Prowlarr: Radarr verknüpfen"
  link_prowlarr_app "Radarr" "http://radarr:7878" "$RADARR_API_KEY" "Radarr" >/dev/null
  log_ok "Radarr unter Apps"

  log_step "Prowlarr: Sonarr verknüpfen"
  link_prowlarr_app "Sonarr" "http://sonarr:8989" "$SONARR_API_KEY" "Sonarr" >/dev/null
  log_ok "Sonarr unter Apps"

  log_step "Prowlarr: Sync App Indexers"
  arr_api_call POST "$PROWLARR_URL/api/v1/command" "$PROWLARR_API_KEY" \
    '{"name":"ApplicationIndexerSync","forceSync":true}' >/dev/null
  sleep 3
  log_ok "Indexer synced"

  # ── Radarr: Root Folder + Download Client ──────────────────────
  log_step "Radarr: Root Folder /movies"
  link_arr_root_folder "$RADARR_URL" "$RADARR_API_KEY" "/movies" "v3" >/dev/null
  log_ok "Root Folder gesetzt"

  log_step "Radarr: AltMount als Download Client"
  link_arr_download_client "$RADARR_URL" "$RADARR_API_KEY" "movies" "v3" >/dev/null
  log_ok "AltMount verknüpft"

  # ── Sonarr: Root Folder + Download Client ──────────────────────
  log_step "Sonarr: Root Folder /tv"
  link_arr_root_folder "$SONARR_URL" "$SONARR_API_KEY" "/tv" "v3" >/dev/null
  log_ok "Root Folder gesetzt"

  log_step "Sonarr: AltMount als Download Client"
  link_arr_download_client "$SONARR_URL" "$SONARR_API_KEY" "tv" "v3" >/dev/null
  log_ok "AltMount verknüpft"

  log_ok "Alle Service-Verknüpfungen angelegt"
}
