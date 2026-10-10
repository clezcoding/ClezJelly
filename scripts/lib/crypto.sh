#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# ClezJelly — credential encryption
# AES-256-CBC with PBKDF2 (200k iterations) via the system openssl.
#
#   .env.local   encrypted, safe to back up, useless without the passphrase
#   plaintext    only ever lives in a temp file or in memory while in use
# ──────────────────────────────────────────────────────────────────

[[ -n "${CLEZJELLY_CRYPTO_LOADED:-}" ]] && return 0
CLEZJELLY_CRYPTO_LOADED=1

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CRYPTO_CIPHER="aes-256-cbc"
CRYPTO_ITER=200000

# crypto_encrypt_file <plain> <cipher> <passphrase>
crypto_encrypt_file() {
  local plain="$1" cipher="$2" pass="$3"
  CLEZ_PASS="$pass" openssl enc -"$CRYPTO_CIPHER" -pbkdf2 -iter "$CRYPTO_ITER" -salt \
    -in "$plain" -out "$cipher" -pass env:CLEZ_PASS
}

# crypto_decrypt_file <cipher> <passphrase>  → plaintext on stdout
crypto_decrypt_file() {
  local cipher="$1" pass="$2"
  CLEZ_PASS="$pass" openssl enc -"$CRYPTO_CIPHER" -pbkdf2 -iter "$CRYPTO_ITER" -d \
    -in "$cipher" -pass env:CLEZ_PASS 2>/dev/null
}

crypto_verify_passphrase() {
  crypto_decrypt_file "$1" "$2" >/dev/null 2>&1
}

# New passphrase with confirmation (min. 8 chars)
crypto_prompt_new_passphrase() {
  local p1 p2
  while true; do
    p1="$(prompt_secret 'Choose a passphrase')"
    if [ "${#p1}" -lt 8 ]; then
      log_warn "Use at least 8 characters." >&2
      continue
    fi
    p2="$(prompt_secret 'Repeat it')"
    if [[ "$p1" == "$p2" ]]; then
      printf '%s\n' "$p1"
      return 0
    fi
    log_warn "Those didn't match, try again." >&2
  done
}

# Ask for the passphrase to unlock an existing file (3 tries)
crypto_prompt_unlock() {
  local cipher="$1" pass tries=0
  while [ "$tries" -lt 3 ]; do
    pass="$(prompt_secret 'Passphrase')"
    if crypto_verify_passphrase "$cipher" "$pass"; then
      printf '%s\n' "$pass"
      return 0
    fi
    log_warn "Wrong passphrase." >&2
    tries=$((tries + 1))
  done
  log_err "Too many attempts." >&2
  return 1
}

# Decrypt and export every KEY=VALUE line into the current shell
crypto_source_envfile() {
  local cipher="$1" pass="$2" plain line
  [[ -f "$cipher" ]] || return 1
  plain="$(crypto_decrypt_file "$cipher" "$pass")" || return 2
  while IFS= read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    export "${line?}"
  done <<< "$plain"
  return 0
}
