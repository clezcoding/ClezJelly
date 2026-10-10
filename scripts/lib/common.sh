#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# ClezJelly — common helpers
# Prompts, random keys, templating, small system probes.
# Pure bash 3.2 (macOS default): no ${var,,}, no associative arrays.
# ──────────────────────────────────────────────────────────────────

[[ -n "${CLEZJELLY_COMMON_LOADED:-}" ]] && return 0
CLEZJELLY_COMMON_LOADED=1

# shellcheck source=ui.sh
source "$(dirname "${BASH_SOURCE[0]}")/ui.sh"

# ── Prompts ───────────────────────────────────────────────────────
# All prompts write to stderr so they still show up inside $( ... ).

prompt_yes_no() {
  local prompt="$1" default="${2:-y}" hint answer answer_lc
  if [[ "$default" == "y" ]]; then hint="Y/n"; else hint="y/N"; fi
  while true; do
    read -r -p "  ${C_VIOLET}?${RESET} ${prompt} ${C_MUTE}[${hint}]${RESET} " answer
    answer="${answer:-$default}"
    answer_lc="$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')"
    case "$answer_lc" in
      y|yes|j|ja) return 0 ;;
      n|no|nein)  return 1 ;;
      *) printf '    %sPlease answer y or n.%s\n' "$C_MUTE" "$RESET" >&2 ;;
    esac
  done
}

# prompt_input "Question" ["default"]
prompt_input() {
  local prompt="$1" default="${2:-}" hint="" answer
  [[ -n "$default" ]] && hint=" ${C_MUTE}(${default})${RESET}"
  read -r -p "  ${C_VIOLET}?${RESET} ${prompt}${hint} ${BOLD}›${RESET} " answer
  printf '%s\n' "${answer:-$default}"
}

# prompt_required "Question" ["default"]  — re-asks until non-empty
prompt_required() {
  local v
  while true; do
    v="$(prompt_input "$@")"
    [[ -n "$v" ]] && { printf '%s\n' "$v"; return 0; }
    printf '    %sThis one is required.%s\n' "$C_WARN" "$RESET" >&2
  done
}

prompt_secret() {
  local prompt="$1" answer
  read -r -s -p "  ${C_VIOLET}?${RESET} ${prompt} ${C_MUTE}(hidden)${RESET} ${BOLD}›${RESET} " answer
  echo "" >&2
  printf '%s\n' "$answer"
}

prompt_secret_required() {
  local v
  while true; do
    v="$(prompt_secret "$1")"
    [[ -n "$v" ]] && { printf '%s\n' "$v"; return 0; }
    printf '    %sThis one is required.%s\n' "$C_WARN" "$RESET" >&2
  done
}

# prompt_secret_keep "Label" "$existing"  — Enter keeps the existing value
prompt_secret_keep() {
  local label="$1" cur="${2:-}" v
  if [[ -z "$cur" ]]; then prompt_secret_required "$label"; return; fi
  v="$(prompt_secret "$label — Enter keeps the current one")"
  printf '%s\n' "${v:-$cur}"
}

# prompt_choice "Question" default_index "Option A" "Option B" ...  →  prints the 1-based index
prompt_choice() {
  local prompt="$1" default="$2"; shift 2
  local i=1 opt answer
  printf '  %s?%s %s\n' "$C_VIOLET" "$RESET" "$prompt" >&2
  for opt in "$@"; do
    if [ "$i" -eq "$default" ]; then
      printf '      %s%s%s  %s%s%s %s(default)%s\n' "$BOLD" "$i" "$RESET" "$C_TEXT" "$opt" "$RESET" "$C_MUTE" "$RESET" >&2
    else
      printf '      %s%s%s  %s\n' "$BOLD" "$i" "$RESET" "$opt" >&2
    fi
    i=$((i + 1))
  done
  while true; do
    read -r -p "    ${BOLD}›${RESET} " answer
    answer="${answer:-$default}"
    if [[ "$answer" =~ ^[0-9]+$ ]] && [ "$answer" -ge 1 ] && [ "$answer" -le "$#" ]; then
      printf '%s\n' "$answer"
      return 0
    fi
    printf '    %sPick a number between 1 and %s.%s\n' "$C_MUTE" "$#" "$RESET" >&2
  done
}

# ── Project root ──────────────────────────────────────────────────
find_root() {
  local dir="${1:-$PWD}"
  while [[ "$dir" != "/" ]]; do
    [[ -f "$dir/docker-compose.yml" && -f "$dir/install.sh" ]] && { echo "$dir"; return 0; }
    dir="$(dirname "$dir")"
  done
  return 1
}

# ── Random secrets ────────────────────────────────────────────────
gen_api_key()    { openssl rand -hex 16; }                      # 32 hex chars (*arr style)
gen_api_key_33() { openssl rand -hex 16; }                      # legacy name: AltMount validates key_override at exactly 32 chars
gen_jwt_secret() { openssl rand -hex 32; }

# ── Templating (no gettext needed) ────────────────────────────────
# render_template <template> <output> VAR1 VAR2 ...
# Replaces ${VAR} placeholders with the value of the named variables.
render_template() {
  local tpl="$1" out="$2"; shift 2
  local content name val esc
  content="$(cat "$tpl")"
  for name in "$@"; do
    val="${!name}"
    esc="$(printf '%s' "$val" | sed -e 's/[\\&|]/\\&/g')"
    content="$(printf '%s\n' "$content" | sed -e "s|[$]{${name}}|${esc}|g")"
  done
  printf '%s\n' "$content" > "$out"
}

# Escape a value for use inside a YAML single-quoted string
yaml_squote() { printf '%s' "$1" | sed "s/'/''/g"; }

# ── System probes ─────────────────────────────────────────────────
lan_ip() {
  local ip=""
  ip="$(ipconfig getifaddr en0 2>/dev/null || true)"
  [[ -z "$ip" ]] && ip="$(ipconfig getifaddr en1 2>/dev/null || true)"
  [[ -z "$ip" ]] && ip="$(hostname -I 2>/dev/null | awk '{print $1}' || true)"
  printf '%s' "$ip"
}

# Is something listening on host:port?  (used for provider reachability)
port_open() {
  local host="$1" port="$2"
  if command -v nc &>/dev/null; then
    nc -z -G 4 "$host" "$port" >/dev/null 2>&1 || nc -z -w 4 "$host" "$port" >/dev/null 2>&1
  else
    (exec 3<>"/dev/tcp/$host/$port") >/dev/null 2>&1
  fi
}

# Read the value of KEY from a KEY=VALUE file (no sourcing, no eval)
env_get() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 1
  grep -E "^${key}=" "$file" | tail -n 1 | cut -d= -f2-
}
