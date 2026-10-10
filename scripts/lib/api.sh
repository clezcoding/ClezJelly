#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# ClezJelly — API Helpers
# Wartet auf Services, curl-Wrapper mit Retry, JSON-Helfer
# ──────────────────────────────────────────────────────────────────

[[ -n "${CLEZJELLY_API_LOADED:-}" ]] && return 0
CLEZJELLY_API_LOADED=1

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Wartet bis URL einen 2xx/3xx/4xx HTTP code liefert (Service hoch)
# Args: url, timeout_seconds (default 60), accept_codes_regex (default "^[234]")
wait_for_url() {
  local url="$1"
  local timeout="${2:-60}"
  local pattern="${3:-^[234]}"
  local waited=0
  local code
  while (( waited < timeout )); do
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "$url" 2>/dev/null || echo 000)"
    if [[ "$code" =~ $pattern ]]; then
      return 0
    fi
    sleep 2
    waited=$((waited + 2))
  done
  return 1
}

# curl-Wrapper: Pretty print status + response
# Args: method, url, [data json], [headers...]
api_call() {
  local method="$1"; shift
  local url="$1"; shift
  local data=""
  local headers=()

  while (( $# > 0 )); do
    case "$1" in
      --data)   data="$2"; shift 2 ;;
      --header) headers+=("-H" "$2"); shift 2 ;;
      *) shift ;;
    esac
  done

  local curl_opts=(-sS -X "$method" --max-time 30 "${headers[@]}")
  [[ -n "$data" ]] && curl_opts+=(-H "Content-Type: application/json" --data "$data")

  curl "${curl_opts[@]}" "$url"
}

# Prowlarr/Radarr/Sonarr: API-Key setzen für Container
# Diese Services nehmen API-Key aus config.xml beim ersten Start
# Später wird er für API-Calls als X-Api-Key Header übergeben
arr_api_call() {
  local method="$1"
  local url="$2"
  local api_key="$3"
  local data="${4:-}"
  if [[ -n "$data" ]]; then
    api_call "$method" "$url" --header "X-Api-Key: $api_key" --data "$data"
  else
    api_call "$method" "$url" --header "X-Api-Key: $api_key"
  fi
}

# Prüft ob jq verfügbar — nötig für JSON-Manipulation
check_jq() {
  if ! command -v jq &>/dev/null; then
    log_warn "jq nicht installiert — manche API-Calls fallen auf grep zurück"
    return 1
  fi
  return 0
}

# Portable JSON-Field-Extraktion (jq oder grep-fallback)
json_get() {
  local field="$1"
  local json="$2"
  if command -v jq &>/dev/null; then
    echo "$json" | jq -r ".$field // empty"
  else
    # Simpel: "field":"value" oder "field":123
    echo "$json" | grep -oE "\"$field\":\"[^\"]*\"|\"$field\":[0-9]+" \
      | head -1 | sed -E 's/^"[^"]+":"?([^"]*)"?$/\1/'
  fi
}
