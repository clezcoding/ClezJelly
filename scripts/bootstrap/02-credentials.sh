#!/usr/bin/env bash
# shellcheck disable=SC2034  # globals are consumed by other sourced files
# ──────────────────────────────────────────────────────────────────
# Phase 2 · Credentials
#
# Asks for the Usenet provider and indexer(s), generates every internal
# API key, and stores everything AES-256 encrypted in .env.local.
# ──────────────────────────────────────────────────────────────────

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
[[ -z "${CLEZJELLY_CRYPTO_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/crypto.sh"

CREDS_FILE="${CLEZJELLY_ROOT}/.env.local"
CRED_KEYS="EWEKA_HOST EWEKA_PORT EWEKA_USER EWEKA_PASS EWEKA_MAX_CONN NZBGEEK_URL NZBGEEK_API_KEY INDEXER2_NAME INDEXER2_URL INDEXER2_API_KEY QUALITY_PROFILE PROWLARR_API_KEY RADARR_API_KEY SONARR_API_KEY BAZARR_API_KEY ALTMOUNT_API_KEY ALTMOUNT_JWT_SECRET"

# Best-effort sanity check of an indexer key (never blocks the install)
_check_indexer() {
  local name="$1" url="$2" key="$3" body
  body="$(curl -sS --max-time 10 "${url%/}/api?t=caps&apikey=${key}" 2>/dev/null || true)"
  if [[ -z "$body" ]]; then
    log_warn "$name didn't answer — check the URL later in Prowlarr"
  elif printf '%s' "$body" | grep -qiE '<error[^>]*code="1[0-9][0-9]"'; then
    log_warn "$name rejected that API key — you can fix it later in Prowlarr"
  elif printf '%s' "$body" | grep -qi '<caps'; then
    log_ok "$name accepted the key"
  else
    log_info "$name answered, but not with a Newznab response"
  fi
}

credentials_collect() {
  # ── Usenet provider ──
  ui_card_open "Usenet provider"
  ui_card_line "${C_MUTE}Eweka is the tested default (Dutch backbone, strong German retention).${RESET}"
  ui_card_line "${C_MUTE}Any SSL provider works. Find the host in your provider's account page.${RESET}"
  ui_card_close
  EWEKA_HOST="$(prompt_input 'Server host' "${EWEKA_HOST:-ssl-eu.eweka.nl}")"
  EWEKA_PORT="$(prompt_input 'SSL port' "${EWEKA_PORT:-563}")"
  EWEKA_USER="$(prompt_required 'Username' "${EWEKA_USER:-}")"
  EWEKA_PASS="$(prompt_secret_keep 'Password' "${EWEKA_PASS:-}")"
  EWEKA_MAX_CONN="$(prompt_input 'Max connections (see your plan)' "${EWEKA_MAX_CONN:-20}")"
  if port_open "$EWEKA_HOST" "$EWEKA_PORT"; then
    log_ok "$EWEKA_HOST:$EWEKA_PORT is reachable"
  else
    log_warn "Couldn't reach $EWEKA_HOST:$EWEKA_PORT — check host/port and your connection"
  fi

  # ── Primary indexer ──
  echo ""
  ui_card_open "Indexer"
  ui_card_line "${C_MUTE}NZBGeek is the primary. Your key lives at nzbgeek.info → Profile.${RESET}"
  ui_card_close
  NZBGEEK_URL="$(prompt_input 'API URL' "${NZBGEEK_URL:-https://api.nzbgeek.info}")"
  NZBGEEK_API_KEY="$(prompt_secret_keep 'API key' "${NZBGEEK_API_KEY:-}")"
  _check_indexer "NZBGeek" "$NZBGEEK_URL" "$NZBGEEK_API_KEY"

  # ── Optional second indexer ──
  echo ""
  ui_card_open "Second indexer (optional)"
  ui_card_line "${C_MUTE}More coverage for German releases. DrunkenSlug, NZBPlanet or NZB.su work well.${RESET}"
  ui_card_line "${C_MUTE}Press Enter on the name to skip (or keep the current one). Type - to remove it.${RESET}"
  ui_card_close
  local prev2_url="${INDEXER2_URL:-}" prev2_key="${INDEXER2_API_KEY:-}"
  INDEXER2_NAME="$(prompt_input 'Name (e.g. DrunkenSlug)' "${INDEXER2_NAME:-}")"
  [[ "$INDEXER2_NAME" == "-" ]] && INDEXER2_NAME=""
  INDEXER2_URL=""
  INDEXER2_API_KEY=""
  if [[ -n "$INDEXER2_NAME" ]]; then
    INDEXER2_URL="$(prompt_required 'API URL' "$prev2_url")"
    INDEXER2_API_KEY="$(prompt_secret_keep 'API key' "$prev2_key")"
    _check_indexer "$INDEXER2_NAME" "$INDEXER2_URL" "$INDEXER2_API_KEY"
  fi

  # ── Quality ──
  echo ""
  local q qdef=1
  case "${QUALITY_PROFILE:-}" in 2160p-webdl) qdef=2 ;; 720p-webdl) qdef=3 ;; esac
  q="$(prompt_choice 'Default quality (your downstream decides)' "$qdef" \
        '1080p WEB-DL    — recommended at ~40 Mbit/s' \
        '2160p WEB-DL    — needs a fast line (80+ Mbit/s)' \
        '720p WEB-DL     — for slow or shared connections')"
  case "$q" in
    1) QUALITY_PROFILE="1080p-webdl" ;;
    2) QUALITY_PROFILE="2160p-webdl" ;;
    *) QUALITY_PROFILE="720p-webdl" ;;
  esac

  # ── Internal secrets ──
  echo ""
  log_step "Internal keys"
  if [[ -n "${PROWLARR_API_KEY:-}" && -n "${ALTMOUNT_API_KEY:-}" ]]; then
    # Loaded from an earlier run: keep them, otherwise running services would lose their links.
    log_ok "Keeping the existing internal keys"
  else
    PROWLARR_API_KEY="$(gen_api_key)"
    RADARR_API_KEY="$(gen_api_key)"
    SONARR_API_KEY="$(gen_api_key)"
    BAZARR_API_KEY="$(gen_api_key)"
    ALTMOUNT_API_KEY="$(gen_api_key_33)"
    ALTMOUNT_JWT_SECRET="$(gen_jwt_secret)"
    log_ok "Generated 5 API keys + 1 JWT secret (random, never leave this Mac)"
  fi

  credentials_save
}

# Write all credential variables into the encrypted .env.local
credentials_save() {
  echo ""
  ui_card_open "Lock it up"
  ui_card_line "${C_MUTE}Everything above is stored AES-256 encrypted in .env.local.${RESET}"
  ui_card_line "${C_MUTE}You need this passphrase to re-run setup. There is no recovery.${RESET}"
  ui_card_close

  local plain k passphrase
  plain="$(mktemp)"
  chmod 600 "$plain"
  {
    echo "# ClezJelly credentials — generated $(date '+%Y-%m-%d %H:%M:%S')"
    for k in $CRED_KEYS; do printf '%s=%s\n' "$k" "${!k}"; done
  } > "$plain"

  passphrase="$(crypto_prompt_new_passphrase)"
  CLEZ_PASSPHRASE="$passphrase"   # kept in memory for this run only (not exported)
  crypto_encrypt_file "$plain" "$CREDS_FILE" "$passphrase"
  chmod 600 "$CREDS_FILE"
  rm -f "$plain"
  log_ok ".env.local encrypted (chmod 600, gitignored)"

  # shellcheck disable=SC2086,SC2163
  export $CRED_KEYS
}

# Decrypt .env.local into the environment
credentials_load() {
  log_step "Unlocking .env.local"
  if [[ ! -f "$CREDS_FILE" ]]; then
    log_err "No .env.local found — run the full install first."
    return 1
  fi
  local passphrase
  passphrase="$(crypto_prompt_unlock "$CREDS_FILE")" || return 1
  crypto_source_envfile "$CREDS_FILE" "$passphrase" || return 1
  CLEZ_PASSPHRASE="$passphrase"
  if [[ -z "${ALTMOUNT_API_KEY:-}" ]]; then
    log_err ".env.local was written by an older version — re-enter your details via 'Credentials'."
    return 1
  fi
  log_ok "Credentials loaded"
}
