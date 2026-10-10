#!/usr/bin/env bash
# shellcheck disable=SC2034  # globals are consumed by other sourced files
# ──────────────────────────────────────────────────────────────────
# ClezJelly — terminal UI toolkit
# Palette, wordmark, phase headers, spinner, cards, toggle list.
# Pure bash 3.2 (macOS default). No dependencies.
# ──────────────────────────────────────────────────────────────────

[[ -n "${CLEZJELLY_UI_LOADED:-}" ]] && return 0
CLEZJELLY_UI_LOADED=1

CLEZJELLY_VERSION="2.0.0"

# ── Capability detection ──────────────────────────────────────────
# Colour only on a real terminal. NO_COLOR disables, CLEZ_FORCE_COLOR forces
# (handy for generating screenshots).
UI_COLOR=0
if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-dumb}" != "dumb" ]]; then UI_COLOR=1; fi
if [[ -n "${CLEZ_FORCE_COLOR:-}" ]]; then UI_COLOR=1; fi

if [[ "$UI_COLOR" == 1 ]]; then
  RESET=$'\033[0m'
  BOLD=$'\033[1m'
  DIM=$'\033[2m'
  C_VIOLET=$'\033[38;5;141m'   # Jellyfin-ish accent
  C_BLUE=$'\033[38;5;39m'
  C_PINK=$'\033[38;5;212m'
  C_OK=$'\033[38;5;78m'
  C_WARN=$'\033[38;5;214m'
  C_ERR=$'\033[38;5;203m'
  C_MUTE=$'\033[38;5;245m'
  C_TEXT=$'\033[38;5;255m'
else
  RESET="" BOLD="" DIM="" C_VIOLET="" C_BLUE="" C_PINK="" C_OK="" C_WARN="" C_ERR="" C_MUTE="" C_TEXT=""
fi

UI_WIDTH=64
UI_LOG="${UI_LOG:-/dev/null}"

# ── Small helpers ─────────────────────────────────────────────────
ui_hide_cursor() { [[ "$UI_COLOR" == 1 ]] && printf '\033[?25l' || true; }
ui_show_cursor() { [[ "$UI_COLOR" == 1 ]] && printf '\033[?25h' || true; }

# Repeat a string N times
ui_repeat() {
  local s="$1" n="$2" out="" i=0
  while [ "$i" -lt "$n" ]; do out="$out$s"; i=$((i + 1)); done
  printf '%s' "$out"
}

# ── Wordmark ──────────────────────────────────────────────────────
# Six-pixel-tall letters, rendered with half blocks (3 text rows).
_G_C=".####""#....""#....""#....""#...."".####"
_G_L="#....""#....""#....""#....""#....""#####"
_G_E="#####""#....""####.""#....""#....""#####"
_G_Z="#####""...##""..##."".##..""##...""#####"
_G_J="....#""....#""....#""....#""#...#"".###."
_G_Y="#...#""#...#"".#.#.""..#..""..#..""..#.."

_ui_glyph() {
  case "$1" in
    C) printf '%s' "$_G_C" ;;
    L) printf '%s' "$_G_L" ;;
    E) printf '%s' "$_G_E" ;;
    Z) printf '%s' "$_G_Z" ;;
    J) printf '%s' "$_G_J" ;;
    Y) printf '%s' "$_G_Y" ;;
  esac
}

ui_wordmark() {
  local word="CLEZJELLY"
  local grad=(213 212 177 141 105 69 39 45 44)
  local total=$((${#word} * 6))
  local row ch i col top bot g pix idx line colour
  for row in 0 1 2; do
    line="  "
    col=0
    for ((i = 0; i < ${#word}; i++)); do
      ch="${word:$i:1}"
      g="$(_ui_glyph "$ch")"
      local x
      for x in 0 1 2 3 4; do
        top="${g:$((row * 10 + x)):1}"
        bot="${g:$((row * 10 + 5 + x)):1}"
        if   [[ "$top" == "#" && "$bot" == "#" ]]; then pix="█"
        elif [[ "$top" == "#" ]]; then pix="▀"
        elif [[ "$bot" == "#" ]]; then pix="▄"
        else pix=" "; fi
        if [[ "$UI_COLOR" == 1 && "$pix" != " " ]]; then
          idx=$((col * ${#grad[@]} / total))
          colour=$'\033[38;5;'"${grad[$idx]}"'m'
          line="$line$colour$pix"
        else
          line="$line$pix"
        fi
        col=$((col + 1))
      done
      line="$line "
      col=$((col + 1))
    done
    printf '%s%s\n' "$line" "$RESET"
  done
}

UI_TAGLINES=(
  "Usenet in, Sunday movie out."
  "Your own streaming service. No monthly fee, no ads."
  "Popcorn not included."
  "Nothing is downloaded. Everything is streamed."
  "Because the TV deserves better than a spinner."
  "Set it up once, then just press play."
)

ui_tagline() {
  local n=${#UI_TAGLINES[@]}
  printf '%s' "${UI_TAGLINES[$((RANDOM % n))]}"
}

# Film-strip edge, purely decorative
ui_filmstrip() {
  local cells=$((UI_WIDTH / 2))
  printf '  %s%s%s\n' "$C_MUTE$DIM" "$(ui_repeat '▪ ' "$cells")" "$RESET"
}

ui_banner() {
  [[ "$UI_COLOR" == 1 ]] && printf '\033[2J\033[H' || true
  echo ""
  ui_wordmark
  echo ""
  printf '  %sJellyfin · Usenet · zero downloads%s   %sv%s%s\n' "$C_TEXT" "$RESET" "$C_MUTE" "$CLEZJELLY_VERSION" "$RESET"
  echo ""
}

# ── Headers & log lines ───────────────────────────────────────────
# ui_phase 2 5 "Setup"  →  ━━ 2/5 ━━ Setup ━━━━━━━━━━━━━━  ■■□□□
ui_phase() {
  local n="$1" total="$2" title="$3" bar_done bar_todo fill head rule bar
  bar_done="$(ui_repeat '■' "$n")"
  bar_todo="$(ui_repeat '□' $((total - n)))"
  fill=$((UI_WIDTH - ${#title} - 11 - 1 - total))
  [ "$fill" -lt 2 ] && fill=2
  head="${C_VIOLET}━━${RESET} ${BOLD}${n}/${total}${RESET} ${C_VIOLET}━━${RESET} ${BOLD}${C_TEXT}${title}${RESET} "
  rule="${C_VIOLET}$(ui_repeat '━' "$fill")${RESET}"
  bar=" ${C_VIOLET}${bar_done}${C_MUTE}${bar_todo}${RESET}"
  echo ""
  printf '  %s%s%s\n' "$head" "$rule" "$bar"
  echo ""
}

# Plain title (for menu sub-screens)
ui_title() {
  local title="$1"
  echo ""
  printf '  %s╭─%s %s%s%s\n' "$C_VIOLET" "$RESET" "$BOLD$C_TEXT" "$title" "$RESET"
  echo ""
}

log_header() { ui_title "$1"; }
log_step()   { printf '  %s◆%s %s%s%s\n' "$C_VIOLET" "$RESET" "$BOLD" "$1" "$RESET"; }
_ui_result() { [[ -n "${UI_RESULTS:-}" ]] && printf '%s\t%s\n' "$1" "$2" >> "$UI_RESULTS" 2>/dev/null || true; }
log_ok()     { printf '    %s✓%s %s\n' "$C_OK" "$RESET" "$1"; _ui_result ok "$1"; }
log_err()    { printf '    %s✗ %s%s\n' "$C_ERR" "$1" "$RESET" >&2; _ui_result err "$1"; }
log_warn()   { printf '    %s▲ %s%s\n' "$C_WARN" "$1" "$RESET"; _ui_result warn "$1"; }
log_info()   { printf '    %s· %s%s\n' "$C_MUTE" "$1" "$RESET"; }
log_dim()    { printf '    %s%s%s\n' "$C_MUTE" "$1" "$RESET"; }

# key / value row for summaries
ui_kv() { printf '    %s%-16s%s %s\n' "$C_MUTE" "$1" "$RESET" "$2"; }

# ── Spinner ───────────────────────────────────────────────────────
# ui_spin "Pulling images" docker compose pull
# Output of the command goes to $UI_LOG. Returns the command's exit code.
ui_spin() {
  local msg="$1"; shift
  local rc=0 pid i=0 start=$SECONDS
  local frames=("◐" "◓" "◑" "◒")

  if [[ "$UI_COLOR" != 1 ]]; then
    printf '  - %s ...\n' "$msg"
    "$@" >>"$UI_LOG" 2>&1 || rc=$?
    if [ "$rc" -eq 0 ]; then log_ok "$msg"; else log_err "$msg (exit $rc, see $UI_LOG)"; fi
    return "$rc"
  fi

  "$@" >>"$UI_LOG" 2>&1 &
  pid=$!
  ui_hide_cursor
  while kill -0 "$pid" 2>/dev/null; do
    printf '\r    %s%s%s %s %s%ss%s\033[K' "$C_VIOLET" "${frames[$((i % 4))]}" "$RESET" "$msg" "$C_MUTE" "$((SECONDS - start))" "$RESET"
    i=$((i + 1))
    sleep 0.12
  done
  wait "$pid" || rc=$?
  printf '\r\033[K'
  ui_show_cursor
  if [ "$rc" -eq 0 ]; then
    printf '    %s✓%s %s %s%ss%s\n' "$C_OK" "$RESET" "$msg" "$C_MUTE" "$((SECONDS - start))" "$RESET"
  else
    printf '    %s✗ %s (exit %s)%s\n' "$C_ERR" "$msg" "$rc" "$RESET" >&2
    if [[ -f "$UI_LOG" ]]; then
      tail -n 6 "$UI_LOG" | sed "s/^/      ${C_MUTE}│ /; s/\$/${RESET}/" >&2
      printf '      %sfull log: %s%s\n' "$C_MUTE" "$UI_LOG" "$RESET" >&2
    fi
  fi
  return "$rc"
}

# ── Cards ─────────────────────────────────────────────────────────
# Left-rail card: no right border, so ANSI colours never break alignment.
ui_card_open()  { printf '  %s╭─%s %s%s%s\n' "$C_VIOLET" "$RESET" "$BOLD$C_TEXT" "$1" "$RESET"; }
ui_card_sep()   { printf '  %s├─%s %s%s%s\n' "$C_VIOLET" "$RESET" "$C_MUTE" "$1" "$RESET"; }
ui_card_line()  { printf '  %s│%s  %s\n' "$C_VIOLET" "$RESET" "$1"; }
ui_card_blank() { printf '  %s│%s\n' "$C_VIOLET" "$RESET"; }
ui_card_close() { printf '  %s╰─%s\n' "$C_VIOLET" "$RESET"; }

# A little cinema ticket for the finish line
ui_ticket() {
  local a="$1" b="$2"
  printf '  %s╭──────────────────────────────────────┬─────────╮%s\n' "$C_PINK" "$RESET"
  printf '  %s│%s  %s%-35s%s %s│%s %s%-7s%s %s│%s\n' "$C_PINK" "$RESET" "$BOLD$C_TEXT" "$a" "$RESET" "$C_PINK" "$RESET" "$C_PINK" "ADMIT" "$RESET" "$C_PINK" "$RESET"
  printf '  %s│%s  %s%-35s%s %s│%s %s%-7s%s %s│%s\n' "$C_PINK" "$RESET" "$C_MUTE" "$b" "$RESET" "$C_PINK" "$RESET" "$C_PINK" "  ONE" "$RESET" "$C_PINK" "$RESET"
  printf '  %s╰──────────────────────────────────────┴─────────╯%s\n' "$C_PINK" "$RESET"
}

# ── Toggle list ───────────────────────────────────────────────────
# Expects these parallel arrays to exist in the caller:
#   TOGGLE_KEYS   variable names holding "true"/"false"
#   TOGGLE_LABELS short names
#   TOGGLE_HINTS  one-line explanations
# Prints the list and loops until the user presses Enter on an empty line.
ui_toggle_list() {
  local i n=${#TOGGLE_KEYS[@]} answer tok val
  while true; do
    for ((i = 0; i < n; i++)); do
      local k="${TOGGLE_KEYS[$i]}"
      val="${!k}"
      if [[ "$val" == "true" ]]; then
        ui_card_line "${BOLD}$((i + 1))${RESET}  ${C_OK}[x]${RESET} $(printf '%-17s' "${TOGGLE_LABELS[$i]}") ${C_MUTE}${TOGGLE_HINTS[$i]}${RESET}"
      else
        ui_card_line "${BOLD}$((i + 1))${RESET}  ${C_MUTE}[ ]${RESET} $(printf '%-17s' "${TOGGLE_LABELS[$i]}") ${C_MUTE}${TOGGLE_HINTS[$i]}${RESET}"
      fi
    done
    ui_card_close
    read -r -p "  ${BOLD}›${RESET} toggle numbers (e.g. 2 5), Enter to continue: " answer
    [[ -z "$answer" ]] && return 0
    for tok in $answer; do
      if [[ "$tok" =~ ^[0-9]+$ ]] && [ "$tok" -ge 1 ] && [ "$tok" -le "$n" ]; then
        local key="${TOGGLE_KEYS[$((tok - 1))]}"
        if [[ "${!key}" == "true" ]]; then printf -v "$key" '%s' "false"; else printf -v "$key" '%s' "true"; fi
      fi
    done
    # redraw in place
    if [[ "$UI_COLOR" == 1 ]]; then
      printf '\033[%sA\033[J' $((n + 2))
    fi
  done
}
