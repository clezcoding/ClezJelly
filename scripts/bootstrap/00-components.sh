#!/usr/bin/env bash
# shellcheck disable=SC2034  # globals are consumed by other sourced files
# ──────────────────────────────────────────────────────────────────
# Components — what gets installed, and how widely it is exposed.
#
# Core (always on):  AltMount · Prowlarr · Radarr · Sonarr · Jellyfin
# Optional toggles are stored in .clezjelly.conf (plain text, no secrets)
# and translated into docker compose profiles + port bindings.
# ──────────────────────────────────────────────────────────────────

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

COMPONENTS_FILE="${CLEZJELLY_ROOT}/.clezjelly.conf"
COMPONENT_KEYS_ALL="ENABLE_SEERR ENABLE_BAZARR ENABLE_GERMAN SEERR_LAN ALTMOUNT_LAN OPEN_JELLYFIN LAN_IP"

components_defaults() {
  ENABLE_SEERR=true
  ENABLE_BAZARR=true
  ENABLE_GERMAN=true
  SEERR_LAN=true
  ALTMOUNT_LAN=false
  OPEN_JELLYFIN=true
  LAN_IP=""
}

components_load() {
  components_defaults
  [[ -f "$COMPONENTS_FILE" ]] || return 0
  local k v
  while IFS='=' read -r k v; do
    case " $COMPONENT_KEYS_ALL " in
      *" $k "*) printf -v "$k" '%s' "$v" ;;
    esac
  done < "$COMPONENTS_FILE"
  return 0
}

components_save() {
  {
    echo "# ClezJelly component selection (no secrets). Edit via ./install.sh components"
    local k
    for k in $COMPONENT_KEYS_ALL; do
      printf '%s=%s\n' "$k" "${!k}"
    done
  } > "$COMPONENTS_FILE"
}

# Translate toggles into values docker compose and the config templates need
components_derive() {
  local profiles=""
  if [[ "$ENABLE_SEERR" == "true" ]];  then profiles="seerr"; fi
  if [[ "$ENABLE_BAZARR" == "true" ]]; then profiles="${profiles:+$profiles,}bazarr"; fi
  COMPOSE_PROFILES="$profiles"

  SEERR_BIND="127.0.0.1"
  if [[ "$SEERR_LAN" == "true" ]]; then SEERR_BIND="0.0.0.0"; fi

  ALTMOUNT_BIND="127.0.0.1"
  PUBLIC_HOST="localhost"
  if [[ "$ALTMOUNT_LAN" == "true" ]]; then
    ALTMOUNT_BIND="0.0.0.0"
    if [[ -z "$LAN_IP" ]]; then LAN_IP="$(lan_ip)"; fi
    if [[ -z "$LAN_IP" ]]; then
      LAN_IP="$(prompt_required 'LAN IP of this Mac (could not detect it)')"
    fi
    PUBLIC_HOST="$LAN_IP"
  fi
  export COMPOSE_PROFILES SEERR_BIND ALTMOUNT_BIND PUBLIC_HOST
}

components_summary() {
  local on="${C_OK}on${RESET}" off="${C_MUTE}off${RESET}"
  ui_kv "Seerr"            "$([[ $ENABLE_SEERR == true ]] && echo "$on" || echo "$off")"
  ui_kv "Bazarr"           "$([[ $ENABLE_BAZARR == true ]] && echo "$on" || echo "$off")"
  ui_kv "German formats"   "$([[ $ENABLE_GERMAN == true ]] && echo "$on" || echo "$off")"
  ui_kv "Seerr on LAN"     "$([[ $SEERR_LAN == true ]] && echo "$on ${C_MUTE}(0.0.0.0:5055)${RESET}" || echo "${C_MUTE}localhost only${RESET}")"
  ui_kv "AltMount on LAN"  "$([[ $ALTMOUNT_LAN == true ]] && echo "$on ${C_MUTE}(${LAN_IP}:8080)${RESET}" || echo "${C_MUTE}localhost only${RESET}")"
}

components_screen() {
  components_load

  ui_card_open "Components"
  ui_card_line "${C_MUTE}Always included${RESET}  AltMount · Prowlarr · Radarr · Sonarr · Jellyfin"
  ui_card_blank

  TOGGLE_KEYS=(ENABLE_SEERR ENABLE_BAZARR ENABLE_GERMAN SEERR_LAN ALTMOUNT_LAN OPEN_JELLYFIN)
  TOGGLE_LABELS=("Seerr" "Bazarr" "German formats" "Seerr on LAN" "AltMount on LAN" "Launch Jellyfin")
  TOGGLE_HINTS=(
    "request UI for phones and tablets"
    "subtitles, fetched automatically"
    "prefer German DL releases"
    "reachable from other devices"
    "only if a player opens stream URLs itself"
    "open the app when setup is done"
  )
  ui_toggle_list

  if [[ "$ALTMOUNT_LAN" == "true" && -z "$LAN_IP" ]]; then
    local detected
    detected="$(lan_ip)"
    LAN_IP="$(prompt_input 'LAN IP of this Mac' "$detected")"
  fi
  components_save
  components_derive
  echo ""
  components_summary
}
