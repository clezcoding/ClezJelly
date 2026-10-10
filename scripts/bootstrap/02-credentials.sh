#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# Phase 2: Credentials erfassen und in .env.local verschlüsseln
#
# Fragt den User interaktiv nach:
#   - Eweka (Host, Port, User, Pass, Max-Connections)
#   - NZBGeek (API-URL, API-Key)
#   - Zweiter Indexer (optional)
#   - Qualität-Default (1080p WEBDL)
# Generiert dann:
#   - Random API-Keys für prowlarr/radarr/sonarr/altmount-SAB-API
#   - JWT-Secret für AltMount
# Verschlüsselt alles mit Passphrase → .env.local
# ──────────────────────────────────────────────────────────────────

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
[[ -z "${CLEZJELLY_CRYPTO_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/crypto.sh"

CREDS_FILE="${CLEZJELLY_ROOT}/.env.local"

credentials_collect() {
  log_header "Phase 2 · Credentials"

  log_step "Usenet-Provider (Eweka empfohlen)"
  log_dim "Host: ssl-eu.eweka.nl für Eweka. ssl-news.newshosting.com für Newshosting."
  EWEKA_HOST="$(prompt_input 'Usenet Host' 'ssl-eu.eweka.nl')"
  EWEKA_PORT="$(prompt_input 'Port (SSL)' '563')"
  EWEKA_USER="$(prompt_input 'Username')"
  EWEKA_PASS="$(prompt_secret 'Passwort')"
  EWEKA_MAX_CONN="$(prompt_input 'Max Connections (siehe Tarif)' '20')"
  log_ok "Usenet-Provider erfasst"

  echo ""
  log_step "Primärer Indexer: NZBGeek"
  log_dim "API-Key findest du unter https://nzbgeek.info/profile.php"
  NZBGEEK_URL="$(prompt_input 'API URL' 'https://api.nzbgeek.info')"
  NZBGEEK_API_KEY="$(prompt_secret 'NZBGeek API Key')"
  log_ok "NZBGeek erfasst"

  echo ""
  log_step "Zweiter Indexer (optional, Enter zum Überspringen)"
  log_dim "Empfohlen: DrunkenSlug, NZBPlanet, NZB.su"
  INDEXER2_NAME="$(prompt_input 'Name (z.B. drunkenslug)' '')"
  if [[ -n "$INDEXER2_NAME" ]]; then
    INDEXER2_URL="$(prompt_input 'API URL' '')"
    INDEXER2_API_KEY="$(prompt_secret 'API Key')"
    log_ok "Zweiter Indexer erfasst"
  else
    INDEXER2_URL=""
    INDEXER2_API_KEY=""
    log_info "Übersprungen"
  fi

  echo ""
  log_step "Qualitäts-Default"
  log_dim "Bei 40 Mbit/s empfehlen wir 1080p WEBDL."
  QUALITY_PROFILE="$(prompt_input 'Profile (1080p-webdl / 2160p-webdl / 720p-webdl)' '1080p-webdl')"

  echo ""
  log_step "Deutsche Inhalte priorisieren?"
  if prompt_yes_no "TRaSH German Custom Formats (DE > ML > EN) aktivieren?" "y"; then
    PREFER_GERMAN="true"
  else
    PREFER_GERMAN="false"
  fi

  # Random API Keys generieren
  echo ""
  log_step "Generiere interne API-Keys"
  PROWLARR_API_KEY="$(gen_api_key)"
  RADARR_API_KEY="$(gen_api_key)"
  SONARR_API_KEY="$(gen_api_key)"
  BAZARR_API_KEY="$(gen_api_key)"
  ALTMOUNT_SAB_API_KEY="$(gen_api_key)"
  ALTMOUNT_JWT_SECRET="$(gen_jwt_secret)"
  log_ok "6 API-Keys und 1 JWT-Secret generiert"

  # Credentials in Plain-File zusammenstellen
  local plain_file
  plain_file="$(mktemp)"
  cat > "$plain_file" <<EOF
# ClezJelly Credentials — verschlüsselt in .env.local
# Generiert am $(date '+%Y-%m-%d %H:%M:%S')

EWEKA_HOST=$EWEKA_HOST
EWEKA_PORT=$EWEKA_PORT
EWEKA_USER=$EWEKA_USER
EWEKA_PASS=$EWEKA_PASS
EWEKA_MAX_CONN=$EWEKA_MAX_CONN

NZBGEEK_URL=$NZBGEEK_URL
NZBGEEK_API_KEY=$NZBGEEK_API_KEY

INDEXER2_NAME=$INDEXER2_NAME
INDEXER2_URL=$INDEXER2_URL
INDEXER2_API_KEY=$INDEXER2_API_KEY

QUALITY_PROFILE=$QUALITY_PROFILE
PREFER_GERMAN=$PREFER_GERMAN

PROWLARR_API_KEY=$PROWLARR_API_KEY
RADARR_API_KEY=$RADARR_API_KEY
SONARR_API_KEY=$SONARR_API_KEY
BAZARR_API_KEY=$BAZARR_API_KEY
ALTMOUNT_SAB_API_KEY=$ALTMOUNT_SAB_API_KEY
ALTMOUNT_JWT_SECRET=$ALTMOUNT_JWT_SECRET
EOF

  echo ""
  log_step "Verschlüssle .env.local"
  log_dim "Diese Passphrase brauchst du bei Re-Setup / Credential-Änderung"
  local passphrase
  passphrase="$(crypto_prompt_new_passphrase)"

  crypto_encrypt_file "$plain_file" "$CREDS_FILE" "$passphrase"
  chmod 600 "$CREDS_FILE"
  rm -f "$plain_file"
  log_ok ".env.local verschlüsselt (chmod 600)"

  # Direkt exportieren für weitere Phasen
  export EWEKA_HOST EWEKA_PORT EWEKA_USER EWEKA_PASS EWEKA_MAX_CONN
  export NZBGEEK_URL NZBGEEK_API_KEY
  export INDEXER2_NAME INDEXER2_URL INDEXER2_API_KEY
  export QUALITY_PROFILE PREFER_GERMAN
  export PROWLARR_API_KEY RADARR_API_KEY SONARR_API_KEY BAZARR_API_KEY
  export ALTMOUNT_SAB_API_KEY ALTMOUNT_JWT_SECRET
}

# Credentials aus bestehender .env.local laden
credentials_load() {
  log_step "Lade Credentials aus .env.local"
  if [[ ! -f "$CREDS_FILE" ]]; then
    log_err ".env.local fehlt — zuerst credentials_collect ausführen"
    return 1
  fi
  local passphrase
  passphrase="$(crypto_prompt_unlock "$CREDS_FILE")" || return 1
  crypto_source_envfile "$CREDS_FILE" "$passphrase" || return 1
  log_ok "Credentials geladen"
}
