#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# Phase 3 · Folders & config files
#
# Seeds each service's config from config-templates/ — but never clobbers a
# config the service has already written (your UI changes are safe).
#
#   configs_generate seed      only create what is missing        (default)
#   configs_generate altmount  also rewrite AltMount's config     (new provider keys)
#   configs_generate all       rewrite everything, with a backup
# ──────────────────────────────────────────────────────────────────

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

folders_setup() {
  log_step "Folders"
  cd "$CLEZJELLY_ROOT" || return 1
  local d
  for d in config/altmount config/prowlarr config/radarr config/sonarr config/bazarr config/seerr \
           data/strm data/library/movies data/library/tv logs; do
    mkdir -p "$d"
  done
  log_ok "config/ · data/strm · data/library/{movies,tv}"
}

# Back up an existing file into config/.backups/<timestamp>/
_backup_config() {
  local src="$1" label="$2"
  local dir="${CLEZJELLY_ROOT}/config/.backups/${CONFIG_STAMP}"
  mkdir -p "$dir"
  cp "$src" "${dir}/${label}"
}

# _seed <label> <dest> <template> <force:true|false> VAR...
_seed() {
  local label="$1" dest="$2" tpl="$3" force="$4"; shift 4
  if [[ -f "$dest" && "$force" != "true" ]]; then
    log_info "$label: kept your existing file"
    return 0
  fi
  if [[ -f "$dest" ]]; then _backup_config "$dest" "$label"; fi
  render_template "$tpl" "$dest" "$@"
  log_ok "$label"
}

# If a service already wrote a config.xml, trust its API key over a fresh one
# (otherwise linking would fail with 401).
_adopt_arr_key() {
  local var="$1" file="$2" existing
  [[ -f "$file" ]] || return 0
  existing="$(sed -n 's:.*<ApiKey>\(.*\)</ApiKey>.*:\1:p' "$file" | head -n 1)"
  if [[ -n "$existing" && "$existing" != "${!var}" ]]; then
    printf -v "$var" '%s' "$existing"
    export "${var?}"
    KEYS_ADOPTED=true
    log_info "$var: using the key already stored by the service"
  fi
}

# Replace apikey under an INI section
_patch_ini_apikey() {
  local file="$1" section="$2" key="$3" tmp
  tmp="$(mktemp)"
  awk -v sec="[$section]" -v key="$key" '
    /^\[/ { in_sec = ($0 == sec) }
    in_sec && /^apikey[ ]*=/ { print "apikey = " key; next }
    { print }
  ' "$file" > "$tmp" && mv "$tmp" "$file"
}

configs_generate() {
  local mode="${1:-seed}"
  ui_phase 3 5 "Folders & configs"

  folders_setup
  components_derive

  local tpl="${CLEZJELLY_ROOT}/config-templates"
  local cfg="${CLEZJELLY_ROOT}/config"
  CONFIG_STAMP="$(date +%Y%m%d-%H%M%S)"
  KEYS_ADOPTED=false

  local force_all=false force_alt=false
  [[ "$mode" == "all" ]] && { force_all=true; force_alt=true; }
  [[ "$mode" == "altmount" ]] && force_alt=true

  log_step "Config files"

  # Keys first, so every file below uses the final values
  _adopt_arr_key PROWLARR_API_KEY "$cfg/prowlarr/config.xml"
  _adopt_arr_key RADARR_API_KEY   "$cfg/radarr/config.xml"
  _adopt_arr_key SONARR_API_KEY   "$cfg/sonarr/config.xml"

  # AltMount: YAML-safe values
  Y_EWEKA_HOST="$(yaml_squote "$EWEKA_HOST")"
  Y_EWEKA_USER="$(yaml_squote "$EWEKA_USER")"
  Y_EWEKA_PASS="$(yaml_squote "$EWEKA_PASS")"
  case "$EWEKA_PORT" in
    563|443|995|993) EWEKA_TLS=true ;;
    *)               EWEKA_TLS=false ;;
  esac
  export Y_EWEKA_HOST Y_EWEKA_USER Y_EWEKA_PASS EWEKA_TLS

  _seed "AltMount config.yaml" "$cfg/altmount/config.yaml" "$tpl/altmount.config.yaml" "$force_alt" \
    Y_EWEKA_HOST EWEKA_PORT Y_EWEKA_USER Y_EWEKA_PASS EWEKA_TLS EWEKA_MAX_CONN \
    ALTMOUNT_API_KEY RADARR_API_KEY SONARR_API_KEY PUBLIC_HOST
  _seed "Prowlarr config.xml" "$cfg/prowlarr/config.xml" "$tpl/prowlarr.config.xml" "$force_all" PROWLARR_API_KEY
  _seed "Radarr config.xml"   "$cfg/radarr/config.xml"   "$tpl/radarr.config.xml"   "$force_all" RADARR_API_KEY
  _seed "Sonarr config.xml"   "$cfg/sonarr/config.xml"   "$tpl/sonarr.config.xml"   "$force_all" SONARR_API_KEY

  if [[ "$ENABLE_BAZARR" == "true" ]]; then
    if [[ -f "$cfg/bazarr/config/config.ini" ]]; then
      # linuxserver/bazarr keeps its config one level deeper
      _patch_ini_apikey "$cfg/bazarr/config/config.ini" sonarr "$SONARR_API_KEY"
      _patch_ini_apikey "$cfg/bazarr/config/config.ini" radarr "$RADARR_API_KEY"
      log_info "Bazarr config.ini: refreshed Radarr/Sonarr keys"
    else
      mkdir -p "$cfg/bazarr/config"
      _seed "Bazarr config.ini" "$cfg/bazarr/config/config.ini" "$tpl/bazarr.config.ini" "$force_all" \
        RADARR_API_KEY SONARR_API_KEY
    fi
  fi

  if [[ "$KEYS_ADOPTED" == "true" ]]; then
    if [[ -n "${CLEZ_PASSPHRASE:-}" ]]; then
      local plain k
      plain="$(mktemp)"; chmod 600 "$plain"
      { for k in $CRED_KEYS; do printf '%s=%s\n' "$k" "${!k}"; done; } > "$plain"
      crypto_encrypt_file "$plain" "$CREDS_FILE" "$CLEZ_PASSPHRASE"
      rm -f "$plain"
      log_ok ".env.local updated with the adopted keys"
    else
      log_warn "Adopted existing service keys — run 'Credentials' once to refresh .env.local"
    fi
  fi
}
