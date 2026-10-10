#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# ClezJelly — Common library
# Colors, logging, prompts, generic helpers
# ──────────────────────────────────────────────────────────────────

# Nur einmal sourcen
[[ -n "${CLEZJELLY_COMMON_LOADED:-}" ]] && return 0
CLEZJELLY_COMMON_LOADED=1

# ── Farben ────────────────────────────────────────────────────────
RESET=$'\033[0m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
MAGENTA=$'\033[0;35m'
CYAN=$'\033[0;36m'

# ── Logging ───────────────────────────────────────────────────────
log_header() {
  echo ""
  echo "${BOLD}${MAGENTA}╔══════════════════════════════════════════════════════════════════╗${RESET}"
  printf "${BOLD}${MAGENTA}║${RESET} ${BOLD}%-64s${RESET} ${BOLD}${MAGENTA}║${RESET}\n" "$1"
  echo "${BOLD}${MAGENTA}╚══════════════════════════════════════════════════════════════════╝${RESET}"
  echo ""
}

log_step()    { echo "${CYAN}➜${RESET} ${BOLD}$1${RESET}"; }
log_ok()      { echo "  ${GREEN}✓${RESET} $1"; }
log_err()     { echo "  ${RED}✗${RESET} ${RED}$1${RESET}" >&2; }
log_info()    { echo "  ${BLUE}ℹ${RESET} ${DIM}$1${RESET}"; }
log_warn()    { echo "  ${YELLOW}⚠${RESET} ${YELLOW}$1${RESET}"; }
log_dim()     { echo "  ${DIM}$1${RESET}"; }

# ── Prompts ───────────────────────────────────────────────────────
prompt_yes_no() {
  local prompt="$1"
  local default="${2:-y}"
  local hint
  if [[ "$default" == "y" ]]; then hint="[Y/n]"; else hint="[y/N]"; fi
  local answer answer_lc
  while true; do
    read -r -p "  ${BOLD}?${RESET} $prompt $hint " answer
    answer="${answer:-$default}"
    answer_lc="$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')"
    case "$answer_lc" in
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

prompt_secret() {
  local prompt="$1"
  local answer
  read -r -s -p "  ${BOLD}?${RESET} $prompt: " answer
  echo "" >&2
  echo "$answer"
}

# ── Repo root ──────────────────────────────────────────────────────
# Setzt CLEZJELLY_ROOT auf das Projekt-Root (das Verzeichnis mit docker-compose.yml)
find_root() {
  local dir="${1:-$PWD}"
  while [[ "$dir" != "/" ]]; do
    [[ -f "$dir/docker-compose.yml" && -f "$dir/install.sh" ]] && echo "$dir" && return 0
    dir="$(dirname "$dir")"
  done
  return 1
}

# ── Random helpers ────────────────────────────────────────────────
# 32 hex chars — passt für API keys à la *arr
gen_api_key() {
  openssl rand -hex 16
}

# 64 hex chars — JWT secret
gen_jwt_secret() {
  openssl rand -hex 32
}
