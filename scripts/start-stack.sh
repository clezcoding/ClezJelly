#!/usr/bin/env bash
set -euo pipefail
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo "➜ Starte ClezJelly Stack…"
docker compose up -d

echo ""
echo "✓ Services:"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "➜ Jellyfin starten (nativ)…"
if [[ -d "/Applications/Jellyfin.app" ]]; then
  open -a Jellyfin && echo "✓ Jellyfin.app gestartet"
else
  echo "⚠ Jellyfin.app nicht gefunden"
fi

echo ""
echo "Web-UIs:"
echo "  Jellyfin    http://localhost:8096"
echo "  Jellyseerr  http://localhost:5055"
echo "  AltMount    http://localhost:8080"
echo "  Prowlarr    http://localhost:9696"
echo "  Radarr      http://localhost:7878"
echo "  Sonarr      http://localhost:8989"
echo "  Bazarr      http://localhost:6767"
