#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║   ClezJelly — Quick Install                                      ║
# ║   Klont das Repo nach ~/Desktop/ClezJelly und startet install.sh ║
# ║                                                                  ║
# ║   Aufruf:                                                        ║
# ║     bash <(curl -fsSL https://raw.githubusercontent.com/\       ║
# ║       clezcoding/ClezJelly/main/scripts/quickstart.sh)           ║
# ║                                                                  ║
# ║   Optional (Env-Vars):                                           ║
# ║     CLEZJELLY_TARGET_DIR   → anderer Zielordner                  ║
# ║     CLEZJELLY_BRANCH       → anderer Branch (default: main)      ║
# ╚══════════════════════════════════════════════════════════════════╝

# Hinweis: Kein `set -u` — Env-Variablen wie CLEZJELLY_TARGET_DIR können
# ungesetzt sein, und das soll kein Fehler sein (nutzt dann den Default).
set -eo pipefail

# ── Farben ────────────────────────────────────────────────────────
RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'
MAGENTA=$'\033[0;35m'

# ── Config ────────────────────────────────────────────────────────
: "${HOME:?HOME ist nicht gesetzt — kann nicht fortfahren}"
REPO_URL="https://github.com/clezcoding/ClezJelly.git"
TARGET_DIR="${CLEZJELLY_TARGET_DIR:-$HOME/Desktop/ClezJelly}"
BRANCH="${CLEZJELLY_BRANCH:-main}"

# ── Logging ───────────────────────────────────────────────────────
log()   { echo "${CYAN}➜${RESET} ${BOLD}$1${RESET}"; }
ok()    { echo "  ${GREEN}✓${RESET} $1"; }
err()   { echo "  ${RED}✗${RESET} ${RED}$1${RESET}" >&2; }
warn()  { echo "  ${YELLOW}⚠${RESET} ${YELLOW}$1${RESET}"; }
info()  { echo "  ${DIM}$1${RESET}"; }

# ── Banner ────────────────────────────────────────────────────────
clear 2>/dev/null || true
echo "${BOLD}${MAGENTA}"
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
echo "${DIM}  Quick Install — holt das Repo & startet den Installer${RESET}"
echo ""

# ── Preflight ─────────────────────────────────────────────────────
log "Preflight Checks"

# macOS Check
if [[ "$(uname -s)" != "Darwin" ]]; then
  err "Dieses Script läuft nur auf macOS. Du bist auf $(uname -s)."
  exit 1
fi
ok "macOS $(sw_vers -productVersion) auf $(uname -m)"

# Homebrew
if ! command -v brew &>/dev/null; then
  err "Homebrew fehlt. Installiere es zuerst:"
  info '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi
ok "Homebrew installiert"

# git
if ! command -v git &>/dev/null; then
  warn "git fehlt — installiere via brew…"
  brew install git
fi
ok "git verfügbar"

echo ""

# ── Target directory prüfen ───────────────────────────────────────
log "Zielordner: ${BOLD}$TARGET_DIR${RESET}"

if [[ -e "$TARGET_DIR" ]]; then
  if [[ -d "$TARGET_DIR/.git" ]]; then
    warn "Repo existiert bereits — update mit git pull"
    cd "$TARGET_DIR"
    git pull --rebase
    ok "Repo aktualisiert"
  else
    err "$TARGET_DIR existiert, ist aber kein Git-Repo."
    info "Bitte Ordner löschen oder einen anderen Pfad wählen:"
    info "  CLEZJELLY_TARGET_DIR=\$HOME/Desktop/ClezJelly2 bash <(curl…)"
    exit 1
  fi
else
  log "Klone Repo nach $TARGET_DIR…"
  mkdir -p "$(dirname "$TARGET_DIR")"
  git clone --branch "$BRANCH" "$REPO_URL" "$TARGET_DIR"
  ok "Repo geklont"
fi

cd "$TARGET_DIR"
chmod +x install.sh scripts/*.sh 2>/dev/null || true

echo ""
log "Starte Installer…"
echo ""
exec ./install.sh
