#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  ClezJelly — installer & control panel                           ║
# ║                                                                  ║
# ║  Jellyfin on your Mac, fed by Usenet, streamed instead of        ║
# ║  downloaded. Run it with no arguments for the menu, or:          ║
# ║                                                                  ║
# ║    ./install.sh install | components | credentials | relink      ║
# ║                 guide | german | rebuild | status | up | down    ║
# ║                 update | backup | restore | help                 ║
# ╚══════════════════════════════════════════════════════════════════╝

# No `set -u`: optional env vars may legitimately be unset (bash 3.2 on macOS).
set -eo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export CLEZJELLY_ROOT="$SCRIPT_DIR"
cd "$CLEZJELLY_ROOT"

mkdir -p "$CLEZJELLY_ROOT/logs"
UI_LOG="$CLEZJELLY_ROOT/logs/clezjelly.log"
export UI_LOG
: >> "$UI_LOG"
chmod 600 "$UI_LOG" 2>/dev/null || true

# ── Libraries & phases ────────────────────────────────────────────
source "$SCRIPT_DIR/scripts/lib/common.sh"
source "$SCRIPT_DIR/scripts/lib/crypto.sh"
source "$SCRIPT_DIR/scripts/lib/api.sh"
source "$SCRIPT_DIR/scripts/lib/guide.sh"
source "$SCRIPT_DIR/scripts/bootstrap/00-components.sh"
source "$SCRIPT_DIR/scripts/bootstrap/01-preflight.sh"
source "$SCRIPT_DIR/scripts/bootstrap/02-credentials.sh"
source "$SCRIPT_DIR/scripts/bootstrap/03-generate-configs.sh"
source "$SCRIPT_DIR/scripts/bootstrap/04-start-containers.sh"
source "$SCRIPT_DIR/scripts/bootstrap/05-link-services.sh"
source "$SCRIPT_DIR/scripts/bootstrap/06-trash-profiles.sh"
source "$SCRIPT_DIR/scripts/bootstrap/07-seerr-prewire.sh"

trap 'ui_show_cursor' EXIT

BACKUP_ROOT="$HOME/ClezJelly-backups"

# ══════════════════════════════════════════════════════════════════
#  Screens
# ══════════════════════════════════════════════════════════════════

# One-line state of the stack for the menu header
stack_status_line() {
  if [[ ! -f "$CREDS_FILE" ]]; then
    printf '%s·%s not installed yet' "$C_MUTE" "$RESET"; return
  fi
  if ! command -v docker &>/dev/null || ! docker info &>/dev/null; then
    printf '%s○%s container runtime is not running' "$C_WARN" "$RESET"; return
  fi
  components_load
  local want=4 up
  [[ "$ENABLE_SEERR" == "true" ]]  && want=$((want + 1))
  [[ "$ENABLE_BAZARR" == "true" ]] && want=$((want + 1))
  up="$(docker ps --filter 'name=clezjelly-' --filter 'status=running' -q 2>/dev/null | wc -l | tr -d ' ')"
  if   [ "$up" -ge "$want" ]; then printf '%s●%s running %s%s/%s services%s' "$C_OK" "$RESET" "$C_MUTE" "$up" "$want" "$RESET"
  elif [ "$up" -gt 0 ];       then printf '%s◐%s partly up %s%s/%s services%s' "$C_WARN" "$RESET" "$C_MUTE" "$up" "$want" "$RESET"
  else                             printf '%s○%s stopped' "$C_MUTE" "$RESET"; fi
}

_menu_item() {
  printf '   %s%-2s%s %s%-16s%s %s%s%s\n' "$BOLD$C_VIOLET" "$1" "$RESET" "$BOLD" "$2" "$RESET" "$C_MUTE" "$3" "$RESET"
}

is_installed() { [[ -f "$CREDS_FILE" ]]; }

# First visit: no numbers to puzzle over, just one clear next step
show_welcome() {
  printf '  %sTurn this Mac into your own streaming service.%s\n' "$BOLD" "$RESET"
  printf '  %sThe setup takes about 5 minutes and runs by itself.%s\n\n' "$C_MUTE" "$RESET"
  printf '  %sKeep these at hand:%s\n' "$C_MUTE" "$RESET"
  printf '   %s·%s your Usenet provider login %s(e.g. Eweka)%s\n' "$C_VIOLET" "$RESET" "$C_MUTE" "$RESET"
  printf '   %s·%s an indexer API key %s(e.g. NZBGeek)%s\n\n' "$C_VIOLET" "$RESET" "$C_MUTE" "$RESET"
  printf '  %s▸ Press Enter to begin%s\n\n' "$BOLD$C_PINK" "$RESET"
  printf '  %sm%s more options    %sq%s quit\n\n' "$BOLD" "$RESET" "$BOLD" "$RESET"
}

# After install: four everyday choices, everything else tucked away
show_home() {
  printf '   %s\n\n' "$(stack_status_line)"
  _menu_item 1 "Your guide"    "what's left to do, with a checklist"
  _menu_item 2 "Check health"  "is everything working?"
  _menu_item 3 "Start / stop"  "also: restart, update, logs"
  _menu_item 4 "More"          "settings, repair, backup"
  echo ""
  printf '   %sq%s quit\n\n' "$BOLD" "$RESET"
}

show_more() {
  printf '  %sMore%s\n\n' "$BOLD" "$RESET"
  _menu_item 1 "Components"     "choose what's included"
  _menu_item 2 "Credentials"    "change provider or indexers"
  _menu_item 3 "Repair"         "re-connect the services"
  _menu_item 4 "German formats" "prefer German releases"
  _menu_item 5 "Backup"         "secrets or a full snapshot"
  _menu_item 6 "Rebuild"        "reset config files (with backup)"
  echo ""
  printf '   %sb%s back\n\n' "$BOLD" "$RESET"
}

show_done() {
  local bad
  bad="$(grep -c -E '^(warn|err)' "$WIRING_RESULTS" 2>/dev/null || true)"; bad="${bad:-0}"

  echo ""
  ui_ticket "CLEZJELLY CINEMA" "Tonight: you pick the film"
  echo ""
  if [ "$bad" -gt 0 ]; then
    printf '  %s▲ Installed, but %s step(s) need a look:%s\n' "$C_WARN" "$bad" "$RESET"
    grep -E '^(warn|err)' "$WIRING_RESULTS" | cut -f2 | sed 's/ *(details in .*)//' | sed 's/^/     · /'
  else
    printf '  %s✓ Installed and connected.%s\n' "$C_OK" "$RESET"
  fi
  echo ""
  printf '  %sYour next steps are on a page that is opening in your browser.%s\n' "$BOLD" "$RESET"
  guide_open || true
  echo ""
  printf '  %sReopen it any time: ./install.sh guide  ·  Menu: ./install.sh%s\n\n' "$C_MUTE" "$RESET"
}

# ══════════════════════════════════════════════════════════════════
#  Actions
# ══════════════════════════════════════════════════════════════════

action_install() {
  ui_banner
  preflight_run || return 1

  ui_phase 2 5 "Setup"
  components_screen
  echo ""

  local fresh_creds=true
  if [[ -f "$CREDS_FILE" ]]; then
    if prompt_yes_no "Found saved credentials. Reuse them?"; then
      credentials_load || return 1
      fresh_creds=false
    fi
  fi
  if [[ "$fresh_creds" == "true" ]]; then
    components_load
    credentials_collect
  fi

  if [[ "$fresh_creds" == "true" ]]; then configs_generate altmount; else configs_generate seed; fi
  containers_start || return 1
  services_link || true

  if [[ "$OPEN_JELLYFIN" == "true" && -d "/Applications/Jellyfin.app" ]]; then
    open -a Jellyfin 2>/dev/null && log_ok "Jellyfin launched" || true
  fi
  show_done
}

action_components() {
  local before_host after_host
  before_host="$(sed -n "s|^  host: '\(.*\)' .*|\1|p" config/altmount/config.yaml 2>/dev/null || true)"
  components_screen
  echo ""
  [[ -f "$CREDS_FILE" ]] || { log_info "Saved. They take effect during the install."; return 0; }
  if prompt_yes_no "Apply to the running stack now? (needs your passphrase)"; then
    credentials_load || return 1
    # AltMount's stream address follows the "AltMount on LAN" switch
    configs_generate altmount
    containers_start || return 1
    services_link || true
    after_host="$PUBLIC_HOST"
    if [[ -n "$before_host" && "$before_host" != "$after_host" ]]; then
      log_warn "Titles imported earlier still point to $before_host — new ones use $after_host."
    fi
  fi
}

action_credentials() {
  ui_title "Credentials"
  components_load
  if [[ -f "$CREDS_FILE" ]]; then
    log_info "Your current internal keys are kept, so existing links keep working."
    credentials_load || return 1
    cp "$CREDS_FILE" "$CREDS_FILE.bak"; chmod 600 "$CREDS_FILE.bak"
    log_ok "Previous file saved as .env.local.bak"
    echo ""
  fi
  credentials_collect
  configs_generate altmount
  echo ""
  if docker info &>/dev/null && prompt_yes_no "Apply to the running stack now?"; then
    env_write
    ui_spin "Restarting AltMount" docker compose restart altmount || true
    ui_wait "AltMount" "http://localhost:8080" 90 || true
    services_link || true
  fi
}

action_guide() {
  ui_title "Your guide"
  components_load
  guide_open
}

action_relink() {
  ui_title "Re-link services"
  components_load
  components_derive
  credentials_load || return 1
  services_link || true
  guide_generate && log_info "Guide page updated. Open it with: ./install.sh guide"
}

action_german() {
  ui_title "German formats"
  components_load
  ENABLE_GERMAN=true
  components_save
  credentials_load || return 1
  cd "$CLEZJELLY_ROOT"
  german_formats_apply
}

action_rebuild() {
  ui_title "Rebuild config files"
  log_info "Re-seeds every service config from config-templates/."
  log_info "Your current files are copied to config/.backups/ first. Databases, history and"
  log_info "library are untouched, but settings you changed inside the apps' UIs are reset."
  echo ""
  prompt_yes_no "Continue?" "n" || return 0
  components_load
  credentials_load || return 1
  configs_generate all
  if docker info &>/dev/null; then
    ui_spin "Restarting the stack" docker compose restart || true
  fi
}

action_status() {
  ui_title "Status"
  components_load
  cd "$CLEZJELLY_ROOT"

  _row() {   # name  url  probe_url  container  enabled
    local name="$1" url="$2" probe="$3" cont="$4" enabled="$5" code health dot state
    if [[ "$enabled" != "true" ]]; then
      printf '    %s○ %-10s%s %s%s%s\n' "$C_MUTE" "$name" "$RESET" "$C_MUTE" "switched off" "$RESET"; return
    fi
    code="$(curl -s -o /dev/null -w '%{http_code}' --max-time 3 "$probe" 2>/dev/null || echo 000)"
    health=""
    if [[ -n "$cont" ]]; then
      health="$(docker inspect --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$cont" 2>/dev/null || true)"
    fi
    if [[ "$code" =~ ^[234] ]]; then dot="${C_OK}●"; state="${C_OK}up${RESET}"
    else dot="${C_ERR}●"; state="${C_ERR}down${RESET}"; fi
    printf '    %s %-10s%s %-28s %s %s%s%s\n' "$dot" "$name" "$RESET" "$url" "$state" "$C_MUTE" "${health:+($health)}" "$RESET"
  }

  _row "Jellyfin" "http://localhost:8096" "http://localhost:8096/health"       ""                    true
  _row "AltMount" "http://localhost:8080" "http://localhost:8080"               clezjelly-altmount    true
  _row "Prowlarr" "http://localhost:9696" "http://localhost:9696/ping"          clezjelly-prowlarr    true
  _row "Radarr"   "http://localhost:7878" "http://localhost:7878/ping"          clezjelly-radarr      true
  _row "Sonarr"   "http://localhost:8989" "http://localhost:8989/ping"          clezjelly-sonarr      true
  _row "Seerr"    "http://localhost:5055" "http://localhost:5055/api/v1/status" clezjelly-seerr       "$ENABLE_SEERR"
  _row "Bazarr"   "http://localhost:6767" "http://localhost:6767"               clezjelly-bazarr      "$ENABLE_BAZARR"

  echo ""
  local movies tv strm
  movies="$(find data/library/movies -name '*.strm' 2>/dev/null | wc -l | tr -d ' ')"
  tv="$(find data/library/tv -name '*.strm' 2>/dev/null | wc -l | tr -d ' ')"
  strm="$(find data/strm -name '*.strm' 2>/dev/null | wc -l | tr -d ' ')"
  ui_kv "Movies"  "${movies} in library"
  ui_kv "Episodes" "${tv} in library"
  ui_kv "Waiting" "${strm} staged in data/strm"
  ui_kv "Disk"    "$(du -sh data 2>/dev/null | awk '{print $1}') in data/  (STRM files only, no media)"
}

action_stack() {
  ui_title "Stack"
  local c
  c="$(prompt_choice 'What do you want to do?' 1 \
        'Start' 'Stop' 'Restart' 'Update images' 'Follow logs (Ctrl+C to leave)')"
  case "$c" in
    1) stack_up ;;
    2) stack_down ;;
    3) stack_down && stack_up ;;
    4) stack_update ;;
    5) docker compose logs -f --tail 50 ;;
  esac
}

action_backup() {
  ui_title "Backup & restore"
  local c ts dir
  c="$(prompt_choice 'Choose' 1 \
        'Back up secrets          (.env.local + component choices — tiny, do this one)' \
        'Full snapshot            (all service configs + library, tar.gz)' \
        'Restore secrets from a backup')"
  ts="$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BACKUP_ROOT"; chmod 700 "$BACKUP_ROOT"
  case "$c" in
    1)
      [[ -f "$CREDS_FILE" ]] || { log_err "No .env.local yet."; return 1; }
      dir="$BACKUP_ROOT/secrets-$ts"
      mkdir -p "$dir"
      cp "$CREDS_FILE" "$dir/.env.local"
      [[ -f "$COMPONENTS_FILE" ]] && cp "$COMPONENTS_FILE" "$dir/.clezjelly.conf"
      chmod -R go-rwx "$dir"
      log_ok "Saved to $dir"
      log_info "It is encrypted, but keep the passphrase somewhere else (password manager)."
      ;;
    2)
      if docker info &>/dev/null && prompt_yes_no "Pause the stack for a consistent snapshot? (recommended)"; then
        ui_spin "Stopping the stack" docker compose stop || true
        local paused=true
      fi
      local out="$BACKUP_ROOT/snapshot-$ts.tar.gz"
      ui_spin "Packing snapshot" tar -czf "$out" --exclude='config/.backups' config data/library data/strm .env.local .clezjelly.conf || true
      chmod 600 "$out"
      log_ok "Saved to $out"
      if [[ "${paused:-}" == "true" ]]; then ui_spin "Starting the stack" docker compose start || true; fi
      ;;
    3)
      local latest choice
      latest="$(ls -1d "$BACKUP_ROOT"/secrets-* 2>/dev/null | tail -n 1 || true)"
      choice="$(prompt_input 'Backup folder' "$latest")"
      if [[ ! -f "$choice/.env.local" ]]; then log_err "No .env.local in that folder."; return 1; fi
      cp "$choice/.env.local" "$CREDS_FILE"; chmod 600 "$CREDS_FILE"
      [[ -f "$choice/.clezjelly.conf" ]] && cp "$choice/.clezjelly.conf" "$COMPONENTS_FILE"
      log_ok "Restored. Next: ./install.sh install (it will offer to reuse these)."
      ;;
  esac
}

action_help() {
  ui_banner
  cat <<EOF
  ${BOLD}Usage${RESET}  ./install.sh [command]

  ${C_MUTE}no command${RESET}   interactive menu
  install      full guided setup
  components   choose optional services and LAN exposure
  credentials  change provider, indexers or keys
  relink       repair the connections between services
  guide        open the "what now?" page in your browser
  german       apply the German release formats
  rebuild      re-seed config files from templates (with backup)
  status       health of every service
  up | down    start or stop the stack
  update       pull newer images and recreate
  backup       secrets or full snapshot
  restore      same menu as backup (option 3)

EOF
}

# ══════════════════════════════════════════════════════════════════
#  Entry
# ══════════════════════════════════════════════════════════════════

pause() { read -r -p "  ${C_MUTE}Press Enter to return to the menu…${RESET}" _; }

run() {
  "$@" || log_err "That didn't finish cleanly. Details: logs/clezjelly.log"
}

more_menu() {
  local choice
  while true; do
    ui_banner
    show_more
    read -r -p "  ${BOLD}›${RESET} " choice
    case "$choice" in
      1) run action_components;  pause ;;
      2) run action_credentials; pause ;;
      3) run action_relink;      pause ;;
      4) run action_german;      pause ;;
      5) run action_backup;      pause ;;
      6) run action_rebuild;     pause ;;
      b|B|"") return 0 ;;
      *) log_warn "Pick a number, or b to go back."; sleep 1 ;;
    esac
  done
}

main_menu() {
  local choice
  while true; do
    ui_banner
    components_load
    if is_installed; then
      show_home
      read -r -p "  ${BOLD}›${RESET} " choice
      case "$choice" in
        1|"") run action_guide;  pause ;;
        2) run action_status;    pause ;;
        3) run action_stack;     pause ;;
        4) more_menu ;;
        q|Q) echo ""; printf '  %sEnjoy the show.%s\n\n' "$C_MUTE" "$RESET"; exit 0 ;;
        *) log_warn "Pick a number from the menu."; sleep 1 ;;
      esac
    else
      show_welcome
      read -r -p "  ${BOLD}›${RESET} " choice
      case "$choice" in
        ""|1|y|Y) run action_install; pause ;;
        m|M) more_menu ;;
        q|Q) echo ""; printf '  %sSee you.%s\n\n' "$C_MUTE" "$RESET"; exit 0 ;;
        *) log_warn "Press Enter to begin, m for more, q to quit."; sleep 1 ;;
      esac
    fi
  done
}

components_load

case "${1:-}" in
  "")          main_menu ;;
  install)     run action_install ;;
  components)  run action_components ;;
  credentials) run action_credentials ;;
  relink)      run action_relink ;;
  guide)       run action_guide ;;
  german)      run action_german ;;
  rebuild)     run action_rebuild ;;
  status)      run action_status ;;
  up)          run stack_up ;;
  down)        run stack_down ;;
  update)      run stack_update ;;
  backup|restore) run action_backup ;;
  help|-h|--help) action_help ;;
  *)           action_help; exit 1 ;;
esac
