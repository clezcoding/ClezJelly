#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║                                                                  ║
# ║   ClezJelly — Jellyfin Media-Server Installer                   ║
# ║   Interaktive Einrichtung auf macOS                             ║
# ║                                                                  ║
# ║   Fragt Credentials, generiert Configs, startet Services,       ║
# ║   verknüpft sie via API — fast vollständig automatisiert.       ║
# ║                                                                  ║
# ╚══════════════════════════════════════════════════════════════════╝

# -u raus: optionale Env-Vars (prompt_input default) sollen keine
# Unbound-Variable-Errors werfen; -e + pipefail bleiben.
set -eo pipefail

# ── Pfade ─────────────────────────────────────────────────────────
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export CLEZJELLY_ROOT="$SCRIPT_DIR"

# ── Libs laden ────────────────────────────────────────────────────
source "$SCRIPT_DIR/scripts/lib/common.sh"
source "$SCRIPT_DIR/scripts/lib/crypto.sh"
source "$SCRIPT_DIR/scripts/lib/api.sh"

# ── Bootstrap-Phasen ──────────────────────────────────────────────
source "$SCRIPT_DIR/scripts/bootstrap/01-preflight.sh"
source "$SCRIPT_DIR/scripts/bootstrap/02-credentials.sh"
source "$SCRIPT_DIR/scripts/bootstrap/03-generate-configs.sh"
source "$SCRIPT_DIR/scripts/bootstrap/04-start-containers.sh"
source "$SCRIPT_DIR/scripts/bootstrap/05-link-services.sh"
source "$SCRIPT_DIR/scripts/bootstrap/06-trash-profiles.sh"

# ── Banner ────────────────────────────────────────────────────────
show_banner() {
  clear 2>/dev/null || true
  echo "${BOLD}${CYAN}"
  cat << 'EOF'
    _____ _          _      _ _
   / ____| |        | |    | | |
  | |    | | ___ ___| | ___| | |_   _
  | |    | |/ _ \_  / |/ _ \ | | | | |
  | |____| |  __// /| |  __/ | | |_| |
   \_____|_|\___/___|_|\___|_|_|\__, |
                                 __/ |
                                |___/
EOF
  echo "${RESET}"
  echo "${DIM}  Jellyfin + Usenet Media Stack · Automated Installer${RESET}"
  echo ""
}

# ── Setup-Ordnerstruktur ──────────────────────────────────────────
folders_setup() {
  log_step "Ordnerstruktur anlegen"
  cd "$CLEZJELLY_ROOT"
  local dirs=(
    "config/altmount"
    "config/prowlarr"
    "config/radarr"
    "config/sonarr"
    "config/seerr"
    "config/bazarr"
    "data/media/movies"
    "data/media/tv"
    "data/strm/movies"
    "data/strm/tv"
    "data/metadata"
  )
  for d in "${dirs[@]}"; do mkdir -p "$d"; done
  log_ok "Alle Ordner angelegt"
}

# ── Finale Nachricht ──────────────────────────────────────────────
show_next_steps() {
  log_header "Setup abgeschlossen 🚀"

  echo "  ${BOLD}${GREEN}Was JETZT noch manuell zu tun ist:${RESET}"
  echo ""
  echo "  ${BOLD}1.${RESET} ${BOLD}Jellyfin${RESET} — Setup-Wizard im Browser (einmalig)"
  echo "     ${CYAN}http://localhost:8096${RESET}"
  echo "     ${DIM}• Sprache: Deutsch${RESET}"
  echo "     ${DIM}• Admin-User anlegen${RESET}"
  echo "     ${DIM}• Library 'Filme'  → /Users/\$USER/Desktop/ClezJelly/data/strm/movies${RESET}"
  echo "     ${DIM}• Library 'Serien' → /Users/\$USER/Desktop/ClezJelly/data/strm/tv${RESET}"
  echo "     ${DIM}• Playback → Hardware-Accel: VideoToolbox${RESET}"
  echo ""
  echo "  ${BOLD}2.${RESET} ${BOLD}Seerr${RESET} — Login mit Jellyfin (einmalig)"
  echo "     ${CYAN}http://localhost:5055${RESET}"
  echo "     ${DIM}• 'Sign in with Jellyfin'${RESET}"
  echo "     ${DIM}• Jellyfin URL: http://host.docker.internal:8096${RESET}"
  echo "     ${DIM}• Services → Radarr/Sonarr sind bereits konfiguriert${RESET}"
  echo ""
  echo "  ${BOLD}3.${RESET} ${BOLD}Samsung TV${RESET} — Jellyfin-App verbinden"
  echo "     ${DIM}• Mac-IP:  ipconfig getifaddr en0${RESET}"
  echo "     ${DIM}• TV-App → http://<Mac-IP>:8096${RESET}"
  echo ""
  echo "  ${BOLD}${YELLOW}Alles andere ist konfiguriert:${RESET}"
  echo "  ${GREEN}✓${RESET} AltMount:  Eweka-Provider, SABnzbd-API, Import-STRM"
  echo "  ${GREEN}✓${RESET} Prowlarr:  Indexer + Radarr/Sonarr Apps verknüpft"
  echo "  ${GREEN}✓${RESET} Radarr:    Root Folder, AltMount als Download-Client"
  echo "  ${GREEN}✓${RESET} Sonarr:    Root Folder, AltMount als Download-Client"
  echo "  ${GREEN}✓${RESET} Bazarr:    Radarr+Sonarr verlinkt, OpenSubtitles.com"
  echo "  ${GREEN}✓${RESET} Credentials verschlüsselt in .env.local"
  echo ""
  echo "  ${DIM}Web-UIs auf einen Blick:${RESET}"
  echo "    ${CYAN}http://localhost:8080${RESET}  AltMount"
  echo "    ${CYAN}http://localhost:9696${RESET}  Prowlarr"
  echo "    ${CYAN}http://localhost:7878${RESET}  Radarr"
  echo "    ${CYAN}http://localhost:8989${RESET}  Sonarr"
  echo "    ${CYAN}http://localhost:5055${RESET}  Seerr"
  echo "    ${CYAN}http://localhost:6767${RESET}  Bazarr"
  echo "    ${CYAN}http://localhost:8096${RESET}  Jellyfin"
  echo ""
}

# ── Aktionen ──────────────────────────────────────────────────────
action_full_install() {
  preflight_run || return 1
  credentials_collect
  folders_setup
  configs_generate
  containers_start
  services_link
  if [[ "$PREFER_GERMAN" == "true" ]]; then
    trash_profiles_apply
  fi

  # Jellyfin starten
  if [[ -d "/Applications/Jellyfin.app" ]]; then
    open -a Jellyfin 2>/dev/null && log_ok "Jellyfin.app gestartet" || true
  fi

  show_next_steps
}

action_update_credentials() {
  log_header "Credentials aktualisieren"
  log_info "Alte .env.local wird mit neuer Passphrase/Daten überschrieben."
  if [[ -f "$CLEZJELLY_ROOT/.env.local" ]]; then
    if prompt_yes_no "Bestehende .env.local sichern (.env.local.bak)?"; then
      cp "$CLEZJELLY_ROOT/.env.local" "$CLEZJELLY_ROOT/.env.local.bak"
      log_ok "Backup erstellt"
    fi
  fi
  credentials_collect
  configs_generate
  if prompt_yes_no "Container mit neuen Configs neustarten?"; then
    cd "$CLEZJELLY_ROOT"
    docker compose restart
    log_ok "Container neugestartet"
  fi
}

action_relink_services() {
  log_header "Services neu verknüpfen (API)"
  credentials_load || return 1
  services_link
}

action_apply_trash() {
  log_header "TRaSH German-Profile anwenden"
  credentials_load || return 1
  PREFER_GERMAN=true trash_profiles_apply
}

action_regenerate_configs() {
  log_header "Config-Files regenerieren"
  credentials_load || return 1
  configs_generate
  log_info "Container neustarten damit sie die neuen Configs lesen:"
  log_info "  docker compose restart"
}

action_backup_env() {
  log_header "Backup .env.local"
  local src="$CLEZJELLY_ROOT/.env.local"
  if [[ ! -f "$src" ]]; then
    log_err "Keine .env.local vorhanden"
    return 1
  fi
  local dst="$HOME/clezjelly.env.local.$(date +%Y%m%d-%H%M%S).bak"
  cp "$src" "$dst"
  chmod 600 "$dst"
  log_ok "Gesichert nach: $dst"
}

action_restore_env() {
  log_header "Restore .env.local"
  local path
  path="$(prompt_input 'Pfad zum Backup' "$HOME/clezjelly.env.local.*.bak")"
  path="$(ls -1 $path 2>/dev/null | tail -1)"
  if [[ ! -f "$path" ]]; then
    log_err "Backup nicht gefunden"
    return 1
  fi
  cp "$path" "$CLEZJELLY_ROOT/.env.local"
  chmod 600 "$CLEZJELLY_ROOT/.env.local"
  log_ok "Restored aus $path"
}

action_status() {
  log_header "Stack Status"
  cd "$CLEZJELLY_ROOT"
  docker compose ps 2>&1
  echo ""
  log_step "Service-Checks"
  for ep in \
    "AltMount|http://localhost:8080" \
    "Prowlarr|http://localhost:9696/ping" \
    "Radarr|http://localhost:7878/ping" \
    "Sonarr|http://localhost:8989/ping" \
    "Seerr|http://localhost:5055/api/v1/status" \
    "Bazarr|http://localhost:6767" \
    "Jellyfin|http://localhost:8096"; do
    IFS='|' read -r name url <<< "$ep"
    code="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 3 "$url" 2>/dev/null || echo 000)"
    if [[ "$code" =~ ^[234] ]]; then
      log_ok "$name ($url)"
    else
      log_err "$name ($url) → $code"
    fi
  done
}

# ── Menü ──────────────────────────────────────────────────────────
show_menu() {
  echo ""
  echo "${BOLD}Was möchtest du tun?${RESET}"
  echo ""
  echo "  ${BOLD}1)${RESET} 🚀 Fresh Install (empfohlen für Erst-Setup)"
  echo "  ${BOLD}2)${RESET} 🔑 Credentials ändern / erneuern"
  echo "  ${BOLD}3)${RESET} 🔗 Services neu verknüpfen (API)"
  echo "  ${BOLD}4)${RESET} 🇩🇪 TRaSH German-Profile anwenden"
  echo "  ${BOLD}5)${RESET} 📝 Config-Files regenerieren"
  echo "  ${BOLD}6)${RESET} 💾 Backup .env.local"
  echo "  ${BOLD}7)${RESET} ♻️  Restore .env.local"
  echo "  ${BOLD}8)${RESET} 🩺 Status checken"
  echo "  ${BOLD}q)${RESET} Beenden"
  echo ""
}

main_menu() {
  while true; do
    show_banner
    show_menu
    local choice
    read -r -p "  ${BOLD}Wahl${RESET} [1-8/q]: " choice
    case "$choice" in
      1) action_full_install; break ;;
      2) action_update_credentials; break ;;
      3) action_relink_services; break ;;
      4) action_apply_trash; break ;;
      5) action_regenerate_configs; break ;;
      6) action_backup_env ;;
      7) action_restore_env ;;
      8) action_status ;;
      q|Q) echo "Bis bald."; exit 0 ;;
      *) log_warn "Ungültige Wahl"; sleep 1 ;;
    esac
  done
}

# ── Entry Point ───────────────────────────────────────────────────
# Argumente: Direkt-Aufruf einer Action ohne Menü
case "${1:-}" in
  install)     show_banner; action_full_install ;;
  credentials) show_banner; action_update_credentials ;;
  relink)      show_banner; action_relink_services ;;
  trash)       show_banner; action_apply_trash ;;
  configs)     show_banner; action_regenerate_configs ;;
  backup)      show_banner; action_backup_env ;;
  restore)     show_banner; action_restore_env ;;
  status)      show_banner; action_status ;;
  "")          main_menu ;;
  *)
    show_banner
    log_err "Unbekannte Action: $1"
    echo ""
    echo "Verfügbar: install | credentials | relink | trash | configs | backup | restore | status"
    exit 1
    ;;
esac
