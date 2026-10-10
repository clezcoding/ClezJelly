#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# Phase 3: Config-Files für alle Services generieren
#
# Erwartet, dass die Credentials als Env-Vars gesetzt sind
# (via credentials_collect oder credentials_load).
# ──────────────────────────────────────────────────────────────────

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

configs_generate() {
  log_header "Phase 3 · Config-Files erzeugen"

  local tpl_dir="${CLEZJELLY_ROOT}/config-templates"
  local cfg_dir="${CLEZJELLY_ROOT}/config"

  mkdir -p "$cfg_dir"/{altmount,prowlarr,radarr,sonarr,bazarr,seerr}

  # ── AltMount ────────────────────────────────────────────────────
  log_step "AltMount config.yaml"
  envsubst < "$tpl_dir/altmount.config.yaml" > "$cfg_dir/altmount/config.yaml"
  log_ok "config/altmount/config.yaml ($(wc -l < "$cfg_dir/altmount/config.yaml") Zeilen)"

  # ── Prowlarr ────────────────────────────────────────────────────
  log_step "Prowlarr config.xml"
  envsubst < "$tpl_dir/prowlarr.config.xml" > "$cfg_dir/prowlarr/config.xml"
  log_ok "config/prowlarr/config.xml"

  # ── Radarr ──────────────────────────────────────────────────────
  log_step "Radarr config.xml"
  envsubst < "$tpl_dir/radarr.config.xml" > "$cfg_dir/radarr/config.xml"
  log_ok "config/radarr/config.xml"

  # ── Sonarr ──────────────────────────────────────────────────────
  log_step "Sonarr config.xml"
  envsubst < "$tpl_dir/sonarr.config.xml" > "$cfg_dir/sonarr/config.xml"
  log_ok "config/sonarr/config.xml"

  # ── Bazarr ──────────────────────────────────────────────────────
  log_step "Bazarr config.ini"
  # Bazarr erstellt beim ersten Start config.ini automatisch, wir patchen Auth-Setting
  mkdir -p "$cfg_dir/bazarr"
  cat > "$cfg_dir/bazarr/config.ini" <<EOF
[general]
ip = 0.0.0.0
port = 6767
base_url = /
path_mappings = []
path_mappings_movie = []
subfolder = current
subfolder_custom =
upgrade_subs = True
upgrade_frequency = 12
days_to_upgrade_subs = 7
upgrade_manual = True
anti_captcha_provider =
anti_captcha_key =
auth_type = form
auth_username = admin
auth_password =
single_language = False
minimum_score = 70
use_scenename = True
use_postprocessing = False
postprocessing_cmd =
use_sonarr = True
use_radarr = True
page_size = 25
enabled_providers = ['opensubtitlescom']
enabled_integrations = []
multithreading = True
chmod = 0640
chmod_enabled = False

[sonarr]
ip = sonarr
port = 8989
base_url = /
ssl = False
apikey = ${SONARR_API_KEY}
full_update = Daily
only_monitored = False

[radarr]
ip = radarr
port = 7878
base_url = /
ssl = False
apikey = ${RADARR_API_KEY}
full_update = Daily
only_monitored = False
EOF
  log_ok "config/bazarr/config.ini"

  # ── Seerr ───────────────────────────────────────────────────────
  log_step "Seerr settings.json"
  cat > "$cfg_dir/seerr/settings.json" <<EOF
{
  "clientId": "$(openssl rand -hex 16)",
  "vapidPrivate": "",
  "vapidPublic": "",
  "main": {
    "apiKey": "$(gen_api_key)",
    "applicationTitle": "ClezJelly",
    "applicationUrl": "",
    "trustProxy": false,
    "csrfProtection": false,
    "cacheImages": false,
    "defaultPermissions": 32,
    "defaultQuotas": {"movie": {"quotaLimit": 0, "quotaDays": 7}, "tv": {"quotaLimit": 0, "quotaDays": 7}},
    "hideAvailable": false,
    "localLogin": true,
    "newPlexLogin": true,
    "region": "AT",
    "originalLanguage": "de",
    "youtubeUrl": ""
  }
}
EOF
  log_ok "config/seerr/settings.json"

  # Berechtigungen
  chmod -R 755 "$cfg_dir"
  log_ok "Berechtigungen gesetzt"
}
