#!/usr/bin/env bash
set -euo pipefail
cd "$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"

echo "➜ Stoppe ClezJelly Stack…"
docker compose down

echo "✓ Stack gestoppt."
echo ""
echo "ℹ Jellyfin.app läuft weiter — bei Bedarf manuell schließen (Cmd+Q)."
