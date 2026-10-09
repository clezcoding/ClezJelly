#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║                                                                  ║
# ║   ClezJelly — Jellyfin Media-Server Installer                   ║
# ║   Interaktive Einrichtung auf macOS                             ║
# ║                                                                  ║
# ╚══════════════════════════════════════════════════════════════════╝

# -u raus: Interaktive read-Dialoge und optionale Env-Vars sollen keine
# Unbound-Variable-Errors werfen. Fehlerstrictheit via -e + pipefail bleibt.
set -eo pipefail

# ── Farben ────────────────────────────────────────────────────────
readonly RESET=$'\033[0m'
readonly BOLD=$'\033[1m'
readonly DIM=$'\033[2m'
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[0;33m'
readonly BLUE=$'\033[0;34m'
readonly MAGENTA=$'\033[0;35m'
readonly CYAN=$'\033[0;36m'
readonly WHITE=$'\033[0;37m'

readonly CHECK="${GREEN}✓${RESET}"
readonly CROSS="${RED}✗${RESET}"
readonly ARROW="${CYAN}➜${RESET}"
readonly INFO="${BLUE}ℹ${RESET}"
readonly WARN="${YELLOW}⚠${RESET}"
readonly ROCKET="🚀"

readonly SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ── Logging-Helpers ───────────────────────────────────────────────
log_header() {
  echo ""
  echo "${BOLD}${MAGENTA}╔══════════════════════════════════════════════════════════════════╗${RESET}"
  printf "${BOLD}${MAGENTA}║${RESET} ${BOLD}%-64s${RESET} ${BOLD}${MAGENTA}║${RESET}\n" "$1"
  echo "${BOLD}${MAGENTA}╚══════════════════════════════════════════════════════════════════╝${RESET}"
  echo ""
}

log_step()    { echo "${ARROW} ${BOLD}$1${RESET}"; }
log_ok()      { echo "  ${CHECK} $1"; }
log_err()     { echo "  ${CROSS} ${RED}$1${RESET}"; }
log_info()    { echo "  ${INFO} ${DIM}$1${RESET}"; }
log_warn()    { echo "  ${WARN} ${YELLOW}$1${RESET}"; }

prompt_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  local hint
  if [[ "$default" == "y" ]]; then
    hint="[Y/n]"
  else
    hint="[y/N]"
  fi
  while true; do
    read -r -p "  ${BOLD}?${RESET} $prompt $hint " answer
    answer="${answer:-$default}"
    case "${answer,,}" in
      y|yes|j|ja) return 0 ;;
      n|no|nein)  return 1 ;;
      *) echo "    ${DIM}Bitte y oder n eingeben.${RESET}" ;;
    esac
  done
}

prompt_input() {
  local prompt="$1"
  local default="${2:-}"
  local hint=""
  [[ -n "$default" ]] && hint=" ${DIM}(Default: $default)${RESET}"
  local answer
  read -r -p "  ${BOLD}?${RESET} $prompt$hint: " answer
  echo "${answer:-$default}"
}

# ── Banner ────────────────────────────────────────────────────────
show_banner() {
  clear
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
  echo "${DIM}  Jellyfin Media-Server mit Usenet-Streaming${RESET}"
  echo "${DIM}  macOS Edition · von Clemens, für Clemens${RESET}"
  echo ""
}

# ── Preflight Checks ──────────────────────────────────────────────
check_macos() {
  log_step "macOS Check"
  if [[ "$(uname -s)" != "Darwin" ]]; then
    log_err "Dieses Script läuft nur auf macOS. Du bist auf $(uname -s)."
    exit 1
  fi
  log_ok "macOS $(sw_vers -productVersion) auf $(uname -m)"
}

check_homebrew() {
  log_step "Homebrew Check"
  if ! command -v brew &>/dev/null; then
    log_err "Homebrew ist nicht installiert."
    log_info "Installiere mit:"
    log_info '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
  fi
  log_ok "Homebrew installiert: $(brew --version | head -1)"
}

check_docker() {
  log_step "Docker Check"

  # Detect runtime: OrbStack, Docker Desktop, Colima, Rancher Desktop…
  local runtime="unbekannt"
  if command -v orb &>/dev/null || [[ -d "/Applications/OrbStack.app" ]]; then
    runtime="OrbStack"
  elif [[ -d "/Applications/Docker.app" ]]; then
    runtime="Docker Desktop"
  elif command -v colima &>/dev/null; then
    runtime="Colima"
  fi

  if ! command -v docker &>/dev/null; then
    log_warn "Kein Docker-CLI gefunden."
    log_info "Empfehlung für macOS: OrbStack (leichter, schneller als Docker Desktop)"
    log_info "  brew install --cask orbstack"
    log_info "Alternativ Docker Desktop:"
    log_info "  brew install --cask docker"
    exit 1
  fi

  if ! docker info &>/dev/null; then
    log_err "Docker-Daemon läuft nicht ($runtime)."
    case "$runtime" in
      OrbStack)       log_info "Starten mit: open -a OrbStack" ;;
      "Docker Desktop") log_info "Starten mit: open -a Docker" ;;
      Colima)         log_info "Starten mit: colima start" ;;
      *)              log_info "Bitte deine Docker-Runtime manuell starten." ;;
    esac
    exit 1
  fi

  log_ok "$runtime läuft: $(docker --version)"
}

check_jellyfin() {
  log_step "Jellyfin Check"
  if [[ -d "/Applications/Jellyfin.app" ]]; then
    log_ok "Jellyfin.app bereits installiert"
    return 0
  fi
  if prompt_yes_no "Jellyfin.app jetzt mit Homebrew installieren? (empfohlen für Hardware-Transcoding)"; then
    brew install --cask jellyfin
    log_ok "Jellyfin installiert"
  else
    log_warn "Jellyfin wird nicht installiert — du musst es selbst machen."
  fi
}

check_openssl() {
  log_step "OpenSSL Check"
  if ! command -v openssl &>/dev/null; then
    log_err "openssl fehlt. Installiere mit: brew install openssl"
    exit 1
  fi
  log_ok "openssl verfügbar"
}

# ── Setup .env ────────────────────────────────────────────────────
setup_env() {
  log_header "Konfiguration"
  log_step "Erstelle .env"

  if [[ -f "$SCRIPT_DIR/.env" ]]; then
    log_warn ".env existiert bereits."
    if ! prompt_yes_no "Überschreiben?" "n"; then
      log_info "Nutze bestehende .env"
      return 0
    fi
  fi

  local jwt_secret
  jwt_secret="$(openssl rand -hex 32)"
  local puid
  puid="$(id -u)"
  local pgid
  pgid="$(id -g)"

  cat > "$SCRIPT_DIR/.env" << EOF
# Automatisch generiert von install.sh am $(date '+%Y-%m-%d %H:%M:%S')
TZ=Europe/Vienna
PUID=$puid
PGID=$pgid
ALTMOUNT_JWT_SECRET=$jwt_secret
EOF
  chmod 600 "$SCRIPT_DIR/.env"
  log_ok ".env erstellt mit PUID=$puid PGID=$pgid"
  log_ok "JWT-Secret generiert (chmod 600)"
}

# ── Ordnerstruktur anlegen ────────────────────────────────────────
setup_folders() {
  log_step "Ordnerstruktur anlegen"
  cd "$SCRIPT_DIR"
  local dirs=(
    "config/altmount"
    "config/prowlarr"
    "config/radarr"
    "config/sonarr"
    "config/jellyseerr"
    "config/bazarr"
    "data/media/movies"
    "data/media/tv"
    "data/strm/movies"
    "data/strm/tv"
    "data/metadata"
  )
  for d in "${dirs[@]}"; do
    mkdir -p "$d"
  done
  log_ok "Alle Ordner angelegt unter $SCRIPT_DIR/{config,data}"
}

# ── Docker Compose starten ────────────────────────────────────────
start_stack() {
  log_header "Services starten"
  log_step "Images ziehen (das kann 1-2 Minuten dauern)…"
  cd "$SCRIPT_DIR"
  docker compose pull 2>&1 | sed 's/^/    /'
  log_ok "Alle Images gezogen"

  log_step "Container starten"
  docker compose up -d 2>&1 | sed 's/^/    /'
  log_ok "Stack läuft"

  echo ""
  log_step "Service-Status"
  sleep 3
  docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" | sed 's/^/    /'
}

# ── Jellyfin starten ──────────────────────────────────────────────
start_jellyfin() {
  log_step "Jellyfin starten"
  if [[ -d "/Applications/Jellyfin.app" ]]; then
    open -a Jellyfin 2>/dev/null && log_ok "Jellyfin.app gestartet" || log_warn "Jellyfin lief vielleicht schon"
  else
    log_warn "Jellyfin.app nicht gefunden, überspringe"
  fi
}

# ── Finale Nachricht ──────────────────────────────────────────────
show_next_steps() {
  log_header "Setup abgeschlossen ${ROCKET}"

  echo "  ${BOLD}${GREEN}Nächste Schritte:${RESET}"
  echo ""
  echo "  ${BOLD}1.${RESET} ${BOLD}AltMount${RESET} konfigurieren"
  echo "     ${CYAN}http://localhost:8080${RESET}"
  echo "     ${DIM}Admin-Account anlegen → Provider (Eweka) hinzufügen → Import = STRM${RESET}"
  echo ""
  echo "  ${BOLD}2.${RESET} ${BOLD}Prowlarr${RESET} — Indexer einrichten"
  echo "     ${CYAN}http://localhost:9696${RESET}"
  echo "     ${DIM}NZBGeek + mind. 1 weiterer Indexer, dann Apps (Radarr/Sonarr) verbinden${RESET}"
  echo ""
  echo "  ${BOLD}3.${RESET} ${BOLD}Radarr${RESET} — Film-Automation"
  echo "     ${CYAN}http://localhost:7878${RESET}"
  echo "     ${DIM}Root Folder: /movies, Download Client: AltMount (als SABnzbd)${RESET}"
  echo ""
  echo "  ${BOLD}4.${RESET} ${BOLD}Sonarr${RESET} — Serien-Automation"
  echo "     ${CYAN}http://localhost:8989${RESET}"
  echo "     ${DIM}Root Folder: /tv, Download Client: AltMount (als SABnzbd)${RESET}"
  echo ""
  echo "  ${BOLD}5.${RESET} ${BOLD}Jellyfin${RESET} — Media-Server"
  echo "     ${CYAN}http://localhost:8096${RESET}"
  echo "     ${DIM}Libraries hinzufügen, HW-Transcoding: VideoToolbox${RESET}"
  echo ""
  echo "  ${BOLD}6.${RESET} ${BOLD}Jellyseerr${RESET} — Request-UI"
  echo "     ${CYAN}http://localhost:5055${RESET}"
  echo "     ${DIM}Mit Jellyfin, Radarr, Sonarr verbinden${RESET}"
  echo ""
  echo "  ${BOLD}7.${RESET} ${BOLD}Bazarr${RESET} — Untertitel"
  echo "     ${CYAN}http://localhost:6767${RESET}"
  echo "     ${DIM}OpenSubtitles.com + Deutsch/Englisch, mit Radarr/Sonarr verbinden${RESET}"
  echo ""
  echo "  ${BOLD}${YELLOW}Detaillierte Anleitung:${RESET} ${DIM}docs/03-configuration.md${RESET}"
  echo ""
  echo "  ${DIM}Praktische Commands:${RESET}"
  echo "    ${DIM}./scripts/start-stack.sh${RESET}    ${DIM}# Stack starten${RESET}"
  echo "    ${DIM}./scripts/stop-stack.sh${RESET}     ${DIM}# Stack stoppen${RESET}"
  echo "    ${DIM}./scripts/health-check.sh${RESET}   ${DIM}# Status checken${RESET}"
  echo "    ${DIM}docker compose logs -f${RESET}      ${DIM}# Live-Logs${RESET}"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────
main() {
  show_banner

  log_header "Preflight Checks"
  check_macos
  check_homebrew
  check_docker
  check_jellyfin
  check_openssl

  setup_env
  setup_folders
  start_stack
  start_jellyfin
  show_next_steps
}

main "$@"
