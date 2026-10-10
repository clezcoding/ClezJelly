#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# Phase 1 · Preflight — macOS, Homebrew, container runtime, Jellyfin, tools
# ──────────────────────────────────────────────────────────────────

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Ports the stack publishes (Jellyfin runs natively on 8096)
PREFLIGHT_PORTS="8080 9696 7878 8989 5055 6767 8096"

preflight_run() {
  ui_phase 1 5 "Preflight"

  # ── macOS ──
  log_step "System"
  if [[ "$(uname -s)" != "Darwin" ]]; then
    log_err "This installer targets macOS (you're on $(uname -s))."
    return 1
  fi
  log_ok "macOS $(sw_vers -productVersion) · $(uname -m)"

  # ── Homebrew ──
  if ! command -v brew &>/dev/null; then
    log_err "Homebrew is missing."
    log_info 'Install it:  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    return 1
  fi
  log_ok "Homebrew $(brew --version | head -1 | awk '{print $2}')"

  # ── Container runtime ──
  log_step "Container runtime"
  local runtime="unknown"
  if command -v orb &>/dev/null || [[ -d "/Applications/OrbStack.app" ]]; then
    runtime="OrbStack"
  elif [[ -d "/Applications/Docker.app" ]]; then
    runtime="Docker Desktop"
  elif command -v colima &>/dev/null; then
    runtime="Colima"
  fi
  if ! command -v docker &>/dev/null; then
    log_err "No docker CLI found."
    log_info "Recommended on macOS:  brew install --cask orbstack"
    return 1
  fi
  if ! docker info &>/dev/null; then
    log_err "The Docker daemon isn't running ($runtime)."
    case "$runtime" in
      OrbStack)         log_info "Start it:  open -a OrbStack" ;;
      "Docker Desktop") log_info "Start it:  open -a Docker" ;;
      Colima)           log_info "Start it:  colima start" ;;
    esac
    return 1
  fi
  if ! docker compose version &>/dev/null; then
    log_err "The 'docker compose' plugin is missing."
    return 1
  fi
  log_ok "$runtime · $(docker --version | sed 's/Docker version //; s/,.*//') · compose $(docker compose version --short 2>/dev/null)"

  # ── Jellyfin (native, for VideoToolbox transcoding) ──
  log_step "Jellyfin"
  if [[ -d "/Applications/Jellyfin.app" ]]; then
    log_ok "Jellyfin.app installed"
  else
    log_warn "Jellyfin.app not found (runs natively so the Mac can hardware-transcode)."
    if prompt_yes_no "Install it now with Homebrew?"; then
      brew install --cask jellyfin
      log_ok "Jellyfin installed"
    else
      log_info "Skipped. Install later:  brew install --cask jellyfin"
    fi
  fi

  # ── CLI tools ──
  log_step "Tools"
  local tool
  for tool in openssl curl jq; do
    if command -v "$tool" &>/dev/null; then continue; fi
    if [[ "$tool" == "jq" ]]; then
      log_warn "jq is missing (used to talk to the service APIs)."
      if prompt_yes_no "Install it with Homebrew?"; then
        brew install jq
      else
        return 1
      fi
    else
      log_err "$tool is missing."
      return 1
    fi
  done
  log_ok "openssl · curl · jq"

  # ── Port conflicts (only if our stack isn't already holding them) ──
  log_step "Ports"
  local ours busy="" p
  ours="$(docker ps --filter 'name=clezjelly-' -q 2>/dev/null | wc -l | tr -d ' ')"
  if [ "${ours:-0}" -gt 0 ]; then
    log_ok "Stack already running — skipping port check"
  else
    for p in $PREFLIGHT_PORTS; do
      if [ "$p" = "8096" ]; then continue; fi
      if lsof -nP -iTCP:"$p" -sTCP:LISTEN &>/dev/null; then busy="$busy $p"; fi
    done
    if [[ -n "$busy" ]]; then
      log_warn "Already in use:${busy}"
      log_info "Free them first, otherwise those containers won't start."
      prompt_yes_no "Continue anyway?" "n" || return 1
    else
      log_ok "All service ports are free"
    fi
  fi

  return 0
}
