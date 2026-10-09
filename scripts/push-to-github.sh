#!/usr/bin/env bash
# Erstellt ein privates GitHub-Repo und pusht ClezJelly dorthin.
# Einmaliger Vorgang nach dem initialen Setup.

set -euo pipefail
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[0;33m'
readonly CYAN=$'\033[0;36m'
readonly BOLD=$'\033[1m'
readonly RESET=$'\033[0m'

echo ""
echo "${BOLD}${CYAN}➜ ClezJelly → GitHub Push${RESET}"
echo ""

# Check gh
if ! command -v gh &>/dev/null; then
  echo "${YELLOW}⚠ GitHub CLI ist nicht installiert.${RESET}"
  echo ""
  echo "Installiere mit:"
  echo "  ${BOLD}brew install gh${RESET}"
  echo ""
  echo "Dann einmalig einloggen:"
  echo "  ${BOLD}gh auth login${RESET}"
  echo ""
  echo "Danach dieses Script erneut ausführen."
  exit 1
fi

# Check gh auth
if ! gh auth status &>/dev/null; then
  echo "${YELLOW}⚠ Du bist nicht bei GitHub eingeloggt.${RESET}"
  echo ""
  echo "Einloggen mit:"
  echo "  ${BOLD}gh auth login${RESET}"
  exit 1
fi

# Check if remote already exists
if git remote get-url origin &>/dev/null; then
  echo "${YELLOW}⚠ Remote 'origin' existiert bereits:${RESET}"
  git remote get-url origin
  echo ""
  read -p "Trotzdem pushen? [y/N] " confirm
  if [[ "${confirm,,}" != "y" ]]; then
    exit 0
  fi
  git push -u origin main
  echo "${GREEN}✓ Gepusht.${RESET}"
  exit 0
fi

REPO_NAME="${1:-ClezJelly}"
echo "Repo-Name: ${BOLD}${REPO_NAME}${RESET}"
echo "Sichtbarkeit: ${BOLD}private${RESET}"
echo ""
read -p "OK? [Y/n] " confirm
confirm="${confirm:-y}"
if [[ "${confirm,,}" != "y" ]]; then
  exit 0
fi

# Create private repo and push
gh repo create "$REPO_NAME" \
  --private \
  --source=. \
  --remote=origin \
  --description "Jellyfin Media-Server mit Usenet-Streaming auf macOS — AltMount, Prowlarr/Radarr/Sonarr/Jellyseerr Stack" \
  --push

echo ""
echo "${GREEN}✓ Repo erstellt und gepusht.${RESET}"
echo ""
gh repo view --web
