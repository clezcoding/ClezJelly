#!/usr/bin/env bash
# ClezJelly Health Check — zeigt den Status aller Services an

set -euo pipefail
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

readonly GREEN=$'\033[0;32m'
readonly RED=$'\033[0;31m'
readonly YELLOW=$'\033[0;33m'
readonly CYAN=$'\033[0;36m'
readonly BOLD=$'\033[1m'
readonly DIM=$'\033[2m'
readonly RESET=$'\033[0m'

check_url() {
  local name="$1"
  local url="$2"
  local port="$3"
  if curl -sSf -o /dev/null --max-time 3 "$url" 2>/dev/null; then
    printf "  ${GREEN}✓${RESET} ${BOLD}%-14s${RESET} ${DIM}%-30s${RESET} ${GREEN}OK${RESET}\n" "$name" "$url"
  elif nc -z localhost "$port" 2>/dev/null; then
    printf "  ${YELLOW}~${RESET} ${BOLD}%-14s${RESET} ${DIM}%-30s${RESET} ${YELLOW}Port offen, HTTP schweigt${RESET}\n" "$name" "$url"
  else
    printf "  ${RED}✗${RESET} ${BOLD}%-14s${RESET} ${DIM}%-30s${RESET} ${RED}DOWN${RESET}\n" "$name" "$url"
  fi
}

echo ""
echo "${BOLD}${CYAN}▶ ClezJelly Health Check${RESET}"
echo ""

echo "${BOLD}Container-Status:${RESET}"
docker compose ps --format "table {{.Name}}\t{{.Status}}" | sed 's/^/  /'
echo ""

echo "${BOLD}Service-Erreichbarkeit:${RESET}"
check_url "Jellyfin"    "http://localhost:8096"       8096
check_url "Jellyseerr"  "http://localhost:5055"       5055
check_url "AltMount"    "http://localhost:8080"       8080
check_url "Prowlarr"    "http://localhost:9696"       9696
check_url "Radarr"      "http://localhost:7878"       7878
check_url "Sonarr"      "http://localhost:8989"       8989
check_url "Bazarr"      "http://localhost:6767"       6767
echo ""

echo "${BOLD}Datenverzeichnis:${RESET}"
if [[ -d "./data/media" ]]; then
  movies=$(find ./data/media/movies -maxdepth 2 -type d 2>/dev/null | wc -l | tr -d ' ')
  tv=$(find ./data/media/tv -maxdepth 2 -type d 2>/dev/null | wc -l | tr -d ' ')
  echo "  ${CYAN}➜${RESET} Movies-Einträge: $movies"
  echo "  ${CYAN}➜${RESET} TV-Einträge:     $tv"
fi

echo ""
