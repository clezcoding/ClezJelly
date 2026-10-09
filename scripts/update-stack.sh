#!/usr/bin/env bash
set -euo pipefail
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo "➜ Ziehe neueste Images…"
docker compose pull

echo "➜ Neustart mit neuen Images…"
docker compose up -d

echo "➜ Prune alte Images…"
docker image prune -f

echo ""
echo "✓ Stack aktualisiert."
docker compose ps
