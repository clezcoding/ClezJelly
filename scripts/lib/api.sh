#!/usr/bin/env bash
# shellcheck disable=SC2034  # globals are consumed by other sourced files
# ──────────────────────────────────────────────────────────────────
# ClezJelly — API helpers
# Wait for services, talk to the *arr REST APIs, idempotent create.
# ──────────────────────────────────────────────────────────────────

[[ -n "${CLEZJELLY_API_LOADED:-}" ]] && return 0
CLEZJELLY_API_LOADED=1

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Return codes used by the link_* helpers
API_CREATED=0
API_EXISTS=10

# wait_for_url <url> [timeout_seconds] [accepted_code_regex]
wait_for_url() {
  local url="$1" timeout="${2:-60}" pattern="${3:-^[234]}" waited=0 code
  while [ "$waited" -lt "$timeout" ]; do
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "$url" 2>/dev/null || echo 000)"
    if [[ "$code" =~ $pattern ]]; then return 0; fi
    sleep 2
    waited=$((waited + 2))
  done
  return 1
}

# ui_wait <label> <url> [timeout]  — wait with a spinner and a verdict line
ui_wait() {
  local label="$1" url="$2" timeout="${3:-120}"
  local start=$SECONDS i=0 code frames=("◐" "◓" "◑" "◒")
  while [ $((SECONDS - start)) -lt "$timeout" ]; do
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 2 "$url" 2>/dev/null || echo 000)"
    if [[ "$code" =~ ^[234] ]]; then
      [[ "$UI_COLOR" == 1 ]] && printf '\r\033[K'
      printf '    %s✓%s %-10s %sready after %ss%s\n' "$C_OK" "$RESET" "$label" "$C_MUTE" "$((SECONDS - start))" "$RESET"
      ui_show_cursor
      return 0
    fi
    if [[ "$UI_COLOR" == 1 ]]; then
      ui_hide_cursor
      printf '\r    %s%s%s %-10s %swaiting… %ss%s\033[K' "$C_VIOLET" "${frames[$((i % 4))]}" "$RESET" "$label" "$C_MUTE" "$((SECONDS - start))" "$RESET"
    fi
    i=$((i + 1))
    sleep 0.5
  done
  [[ "$UI_COLOR" == 1 ]] && printf '\r\033[K'
  ui_show_cursor
  log_warn "$label did not answer within ${timeout}s (check: docker compose logs)"
  return 1
}

# arr_request <METHOD> <url> <api_key> [json_body]
# Prints the response body. Non-2xx → returns 22 and writes a note to $UI_LOG.
arr_request() {
  local method="$1" url="$2" key="$3" data="${4:-}" out code body
  if [[ -n "$data" ]]; then
    out="$(curl -sS --max-time 30 -X "$method" -H "X-Api-Key: $key" -H 'Content-Type: application/json' \
            --data "$data" -w $'\n%{http_code}' "$url" 2>>"$UI_LOG")" || return 7
  else
    out="$(curl -sS --max-time 30 -X "$method" -H "X-Api-Key: $key" \
            -w $'\n%{http_code}' "$url" 2>>"$UI_LOG")" || return 7
  fi
  code="${out##*$'\n'}"
  body="${out%$'\n'*}"
  printf '%s' "$body"
  if [[ ! "$code" =~ ^2 ]]; then
    printf 'HTTP %s from %s %s: %s\n' "$code" "$method" "$url" "$(printf '%s' "$body" | head -c 300)" >>"$UI_LOG"
    return 22
  fi
  return 0
}

# json_has_name <json_array> <name>  — is there an element with .name == name ?
json_has_name() {
  jq -e --arg n "$2" 'any(.[]; .name == $n)' <<<"$1" >/dev/null 2>&1
}
