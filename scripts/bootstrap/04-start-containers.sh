#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# Phase 4: Container pullen und starten
# ──────────────────────────────────────────────────────────────────

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
[[ -z "${CLEZJELLY_API_LOADED:-}" ]]    && source "$(dirname "${BASH_SOURCE[0]}")/../lib/api.sh"

containers_start() {
  log_header "Phase 4 · Container starten"

  cd "$CLEZJELLY_ROOT"

  # .env mit JWT_SECRET für docker-compose schreiben (nicht sensible API-Keys)
  cat > .env <<EOF
TZ=Europe/Vienna
PUID=$(id -u)
PGID=$(id -g)
ALTMOUNT_JWT_SECRET=$ALTMOUNT_JWT_SECRET
EOF
  chmod 600 .env

  log_step "Images pullen"
  docker compose pull 2>&1 | sed 's/^/    /' | tail -10
  log_ok "Images aktuell"

  log_step "Container starten"
  docker compose up -d 2>&1 | sed 's/^/    /' | tail -10
  log_ok "docker compose up -d"

  log_step "Warte auf Services"
  wait_for_url "http://localhost:9696/ping"   120 || log_warn "Prowlarr antwortet nicht"
  wait_for_url "http://localhost:7878/ping"   120 || log_warn "Radarr antwortet nicht"
  wait_for_url "http://localhost:8989/ping"   120 || log_warn "Sonarr antwortet nicht"
  wait_for_url "http://localhost:8080"        120 || log_warn "AltMount antwortet nicht"
  wait_for_url "http://localhost:5055/api/v1/status" 120 || log_warn "Seerr antwortet nicht"
  wait_for_url "http://localhost:6767"        120 || log_warn "Bazarr antwortet nicht"
  log_ok "Alle Services erreichbar"
}
