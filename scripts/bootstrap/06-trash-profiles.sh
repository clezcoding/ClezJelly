#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# German formats — TRaSH-style custom formats + scores
#
# Creates three custom formats in Radarr and Sonarr and scores them in the
# quality profile you picked, so German releases win automatically:
#
#     German DL     +500   dual-language (German + original audio)
#     German Only   +400   German audio only
#     English       +100   fallback when no German release exists
#
# Specs are cloned from each app's /customformat/schema endpoint, so the
# payload shape always matches the installed version.
# ──────────────────────────────────────────────────────────────────

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
[[ -z "${CLEZJELLY_API_LOADED:-}" ]]    && source "$(dirname "${BASH_SOURCE[0]}")/../lib/api.sh"

RE_GERMAN_DL='(?<![a-z0-9])(german|ger)[ ._-]*(dl|dual)(?![a-z0-9])'
RE_GERMAN='(?<![a-z0-9])(german|ger)(?![a-z0-9])'

# _spec <schema_json> <implementation> <spec_name> <negate> <required> <value_json>
_spec() {
  jq -c --arg impl "$2" --arg name "$3" --argjson neg "$4" --argjson req "$5" --argjson val "$6" '
      [.[] | select(.implementation == $impl)] | first
      | .name = $name | .negate = $neg | .required = $req
      | .fields |= map(if .name == "value" then .value = $val else . end)' <<<"$1"
}

# _ensure_cf <base_url> <api_key> <name> <specs_json_array>
_ensure_cf() {
  local base="$1" key="$2" name="$3" specs="$4" existing payload
  existing="$(arr_request GET "$base/api/v3/customformat" "$key")" || return 1
  json_has_name "$existing" "$name" && return $API_EXISTS
  payload="$(jq -nc --arg name "$name" --argjson specs "$specs" \
      '{name: $name, includeCustomFormatWhenRenaming: false, specifications: $specs}')" || return 1
  arr_request POST "$base/api/v3/customformat" "$key" "$payload" >/dev/null || return 1
}

# _score_profile <base_url> <api_key> <profile_name>
_score_profile() {
  local base="$1" key="$2" wanted="$3" profiles cfs profile id payload
  profiles="$(arr_request GET "$base/api/v3/qualityprofile" "$key")" || return 1
  cfs="$(arr_request GET "$base/api/v3/customformat" "$key")" || return 1

  profile="$(jq -c --arg n "$wanted" '(first(.[] | select(.name == $n))) // .[0]' <<<"$profiles")"
  [[ -n "$profile" && "$profile" != "null" ]] || return 1
  id="$(jq -r '.id' <<<"$profile")"

  payload="$(jq -c --argjson cfs "$cfs" '
      .formatItems as $old
      | .formatItems = [ $cfs[] | . as $cf | {
          format: $cf.id,
          name:   $cf.name,
          score: (
            if   $cf.name == "German DL"   then 500
            elif $cf.name == "German Only" then 400
            elif $cf.name == "English"     then 100
            else (first($old[]? | select(.format == $cf.id) | .score) // 0) end)
        } ]' <<<"$profile")" || return 1

  arr_request PUT "$base/api/v3/qualityprofile/$id" "$key" "$payload" >/dev/null || return 1
}

# german_formats_apply — run for Radarr and Sonarr
german_formats_apply() {
  log_step "German formats"
  local app base key schema rc profile_name specs

  case "${QUALITY_PROFILE:-1080p-webdl}" in
    2160p-webdl) profile_name="Ultra-HD" ;;
    720p-webdl)  profile_name="HD-720p" ;;
    *)           profile_name="HD-1080p" ;;
  esac

  for app in Radarr Sonarr; do
    if [[ "$app" == "Radarr" ]]; then base="$RADARR_URL"; key="$RADARR_API_KEY"; else base="$SONARR_URL"; key="$SONARR_API_KEY"; fi

    schema="$(arr_request GET "$base/api/v3/customformat/schema" "$key")" || { log_warn "$app: couldn't read the format schema"; continue; }

    specs="[$(_spec "$schema" ReleaseTitleSpecification "German DL" false true "$(jq -Rn --arg v "$RE_GERMAN_DL" '$v')")]"
    rc=0; _ensure_cf "$base" "$key" "German DL" "$specs" || rc=$?
    _report "$app · German DL" "$rc"

    specs="[$(_spec "$schema" ReleaseTitleSpecification "German" false true "$(jq -Rn --arg v "$RE_GERMAN" '$v')"),$(_spec "$schema" ReleaseTitleSpecification "Not DL" true true "$(jq -Rn --arg v "$RE_GERMAN_DL" '$v')")]"
    rc=0; _ensure_cf "$base" "$key" "German Only" "$specs" || rc=$?
    _report "$app · German Only" "$rc"

    specs="[$(_spec "$schema" LanguageSpecification "English" false true 1)]"
    rc=0; _ensure_cf "$base" "$key" "English" "$specs" || rc=$?
    _report "$app · English" "$rc"

    rc=0; _score_profile "$base" "$key" "$profile_name" || rc=$?
    if [ "$rc" -eq 0 ]; then
      log_ok "$app · scores set on \"$profile_name\"  (DL +500 · German +400 · English +100)"
    else
      log_warn "$app · couldn't set scores — assign them in Settings → Profiles (details in $UI_LOG)"
    fi
  done
}
