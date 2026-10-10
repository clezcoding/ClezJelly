#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# Phase 1: Preflight — macOS, Homebrew, Docker, Jellyfin, Tools
# ──────────────────────────────────────────────────────────────────

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

preflight_run() {
  log_header "Phase 1 · Preflight Checks"

  # macOS
  log_step "macOS Check"
  if [[ "$(uname -s)" != "Darwin" ]]; then
    log_err "Dieses Script läuft nur auf macOS. Du bist auf $(uname -s)."
    return 1
  fi
  log_ok "macOS $(sw_vers -productVersion) auf $(uname -m)"

  # Homebrew
  log_step "Homebrew Check"
  if ! command -v brew &>/dev/null; then
    log_err "Homebrew fehlt."
    log_info "Installiere:  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    return 1
  fi
  log_ok "Homebrew $(brew --version | head -1 | awk '{print $2}')"

  # Docker (OrbStack / Docker Desktop / Colima)
  log_step "Docker/OrbStack Check"
  local runtime="unbekannt"
  if command -v orb &>/dev/null || [[ -d "/Applications/OrbStack.app" ]]; then
    runtime="OrbStack"
  elif [[ -d "/Applications/Docker.app" ]]; then
    runtime="Docker Desktop"
  elif command -v colima &>/dev/null; then
    runtime="Colima"
  fi
  if ! command -v docker &>/dev/null; then
    log_err "Kein Docker-CLI."
    log_info "Empfehlung macOS:  brew install --cask orbstack"
    return 1
  fi
  if ! docker info &>/dev/null; then
    log_err "Docker-Daemon läuft nicht ($runtime)."
    case "$runtime" in
      OrbStack)          log_info "Starten: open -a OrbStack" ;;
      "Docker Desktop")  log_info "Starten: open -a Docker" ;;
      Colima)            log_info "Starten: colima start" ;;
    esac
    return 1
  fi
  log_ok "$runtime läuft: $(docker --version)"

  # Jellyfin
  log_step "Jellyfin Check"
  if [[ -d "/Applications/Jellyfin.app" ]]; then
    log_ok "Jellyfin.app installiert"
  else
    log_warn "Jellyfin.app fehlt."
    if prompt_yes_no "Jetzt installieren (brew)?"; then
      brew install --cask jellyfin
      log_ok "Jellyfin installiert"
    fi
  fi

  # openssl, curl (Standard auf macOS)
  log_step "Tools"
  for tool in openssl curl envsubst; do
    if ! command -v $tool &>/dev/null; then
      if [[ "$tool" == "envsubst" ]]; then
        log_warn "envsubst fehlt — installiere via: brew install gettext && brew link --force gettext"
        if prompt_yes_no "Jetzt installieren?"; then
          brew install gettext && brew link --force gettext
        else
          return 1
        fi
      else
        log_err "$tool fehlt"
        return 1
      fi
    fi
  done
  log_ok "openssl, curl, envsubst OK"

  return 0
}
