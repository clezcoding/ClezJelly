#!/usr/bin/env bash
# shellcheck disable=SC2034
# ──────────────────────────────────────────────────────────────────
# The "what now?" page. Builds ClezJelly-Guide.html from a template,
# filled with this Mac's paths, IP, chosen components and the result
# of the last wiring run, then opens it in the browser.
# The file contains no secrets and is gitignored.
# ──────────────────────────────────────────────────────────────────

GUIDE_FILE="${CLEZJELLY_ROOT:-.}/ClezJelly-Guide.html"
GUIDE_TEMPLATE="${CLEZJELLY_ROOT:-.}/scripts/lib/guide.template.html"

# Escape a string for use inside a JSON/JS double-quoted string
_json_str() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\//\\\//g' | tr -d '\r\n\t'
}

WIRING_RESULTS="${CLEZJELLY_ROOT:-.}/logs/last-wiring.tsv"

guide_generate() {
  local ip root seerr bazarr results="" line s m first=1 cfg
  ip="$(lan_ip)"; [[ -z "$ip" ]] && ip="your-mac-ip"
  root="$CLEZJELLY_ROOT"
  seerr=false;  [[ "${ENABLE_SEERR:-true}"  == "true" ]] && seerr=true
  bazarr=false; [[ "${ENABLE_BAZARR:-true}" == "true" ]] && bazarr=true

  if [[ -f "$WIRING_RESULTS" ]]; then
    while IFS="$(printf '\t')" read -r s m; do
      [[ -z "$s" || -z "$m" ]] && continue
      m="$(printf '%s' "$m" | sed $'s/\x1b\\[[0-9;?]*[A-Za-z]//g')"
      [[ $first -eq 0 ]] && results="$results,"
      results="$results{\"s\":\"$s\",\"m\":\"$(_json_str "$m")\"}"
      first=0
    done < "$WIRING_RESULTS"
  fi

  cfg="window.CFG={root:\"$(_json_str "$root")\",ip:\"$(_json_str "$ip")\",seerr:$seerr,bazarr:$bazarr,results:[$results]};"

  [[ -f "$GUIDE_TEMPLATE" ]] || return 1
  # Swap the /*CFG*/ marker line for the generated config
  # ENVIRON, not -v: awk -v would interpret the backslash escapes in the JSON
  GUIDE_CFG="$cfg" awk '$0 == "/*CFG*/" { print ENVIRON["GUIDE_CFG"]; next } { print }' "$GUIDE_TEMPLATE" > "$GUIDE_FILE"
  chmod 600 "$GUIDE_FILE" 2>/dev/null || true
}

guide_open() {
  guide_generate || { log_warn "Couldn't build the guide page"; return 1; }
  if command -v open &>/dev/null; then
    open "$GUIDE_FILE" 2>/dev/null && log_ok "Opened your guide in the browser" && return 0
  fi
  log_info "Open this file in your browser: $GUIDE_FILE"
}
