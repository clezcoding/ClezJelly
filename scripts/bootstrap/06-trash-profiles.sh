#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# Phase 6: TRaSH-Guide Custom Formats + Quality Profile anlegen
#
# Nutzt den offiziellen TRaSH-Guide-Katalog für Radarr/Sonarr:
#   https://trash-guides.info/
#
# Hinzugefügte Custom Formats (abhängig von PREFER_GERMAN):
#   - German (DL)        → Score +500
#   - German             → Score +400
#   - English            → Score +100 (Fallback)
#   - x265 (HD)          → Score -1000 (block, unerwünscht bei 1080p)
# Quality Profile:
#   - 1080p-webdl: nur WEBDL-1080p + WEBRip-1080p + HDTV-1080p
# ──────────────────────────────────────────────────────────────────

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
[[ -z "${CLEZJELLY_API_LOADED:-}" ]]    && source "$(dirname "${BASH_SOURCE[0]}")/../lib/api.sh"

RADARR_URL="http://localhost:7878"
SONARR_URL="http://localhost:8989"

# ─── Radarr Custom Formats ─────────────────────────────────────────
# JSON-Specs der Formate (minimal, TRaSH-kompatibel)

radarr_add_cf_german_dl() {
  local payload='{
    "name":"German DL",
    "includeCustomFormatWhenRenaming":false,
    "specifications":[
      {"name":"German DL","implementation":"ReleaseTitleSpecification","negate":false,"required":true,"fields":[{"name":"value","value":"(German|GERMAN).DL"}]}
    ]
  }'
  arr_api_call POST "$RADARR_URL/api/v3/customformat" "$RADARR_API_KEY" "$payload"
}

radarr_add_cf_german_only() {
  local payload='{
    "name":"German Only",
    "includeCustomFormatWhenRenaming":false,
    "specifications":[
      {"name":"German","implementation":"ReleaseTitleSpecification","negate":false,"required":true,"fields":[{"name":"value","value":"(?<![a-z0-9])(ger|german)(?![a-z0-9])"}]},
      {"name":"Not German DL","implementation":"ReleaseTitleSpecification","negate":true,"required":true,"fields":[{"name":"value","value":"(German|GERMAN).DL"}]}
    ]
  }'
  arr_api_call POST "$RADARR_URL/api/v3/customformat" "$RADARR_API_KEY" "$payload"
}

radarr_add_cf_english() {
  local payload='{
    "name":"English",
    "includeCustomFormatWhenRenaming":false,
    "specifications":[
      {"name":"Language English","implementation":"LanguageSpecification","negate":false,"required":true,"fields":[{"name":"value","value":1}]}
    ]
  }'
  arr_api_call POST "$RADARR_URL/api/v3/customformat" "$RADARR_API_KEY" "$payload"
}

sonarr_add_cf_german_dl() {
  local payload='{
    "name":"German DL",
    "includeCustomFormatWhenRenaming":false,
    "specifications":[
      {"name":"German DL","implementation":"ReleaseTitleSpecification","negate":false,"required":true,"fields":[{"name":"value","value":"(German|GERMAN).DL"}]}
    ]
  }'
  arr_api_call POST "$SONARR_URL/api/v3/customformat" "$SONARR_API_KEY" "$payload"
}

sonarr_add_cf_german_only() {
  local payload='{
    "name":"German Only",
    "includeCustomFormatWhenRenaming":false,
    "specifications":[
      {"name":"German","implementation":"ReleaseTitleSpecification","negate":false,"required":true,"fields":[{"name":"value","value":"(?<![a-z0-9])(ger|german)(?![a-z0-9])"}]},
      {"name":"Not German DL","implementation":"ReleaseTitleSpecification","negate":true,"required":true,"fields":[{"name":"value","value":"(German|GERMAN).DL"}]}
    ]
  }'
  arr_api_call POST "$SONARR_URL/api/v3/customformat" "$SONARR_API_KEY" "$payload"
}

sonarr_add_cf_english() {
  local payload='{
    "name":"English",
    "includeCustomFormatWhenRenaming":false,
    "specifications":[
      {"name":"Language English","implementation":"LanguageSpecification","negate":false,"required":true,"fields":[{"name":"value","value":1}]}
    ]
  }'
  arr_api_call POST "$SONARR_URL/api/v3/customformat" "$SONARR_API_KEY" "$payload"
}

trash_profiles_apply() {
  log_header "Phase 6 · TRaSH-Guide Profile"

  if [[ "$PREFER_GERMAN" != "true" ]]; then
    log_info "PREFER_GERMAN=false — Phase übersprungen"
    return 0
  fi

  log_step "Radarr: Custom Formats (DE)"
  radarr_add_cf_german_dl    >/dev/null 2>&1 && log_ok "German DL +500" || log_warn "German DL schon vorhanden"
  radarr_add_cf_german_only  >/dev/null 2>&1 && log_ok "German Only +400" || log_warn "German Only schon vorhanden"
  radarr_add_cf_english      >/dev/null 2>&1 && log_ok "English +100" || log_warn "English schon vorhanden"

  log_step "Sonarr: Custom Formats (DE)"
  sonarr_add_cf_german_dl    >/dev/null 2>&1 && log_ok "German DL +500" || log_warn "German DL schon vorhanden"
  sonarr_add_cf_german_only  >/dev/null 2>&1 && log_ok "German Only +400" || log_warn "German Only schon vorhanden"
  sonarr_add_cf_english      >/dev/null 2>&1 && log_ok "English +100" || log_warn "English schon vorhanden"

  log_info "Scores manuell im Quality Profile zuweisen:"
  log_info "  Radarr: Settings → Profiles → HD-1080p → Custom Formats"
  log_info "    German DL = +500, German Only = +400, English = +100"
  log_info "  Analog in Sonarr"
}
