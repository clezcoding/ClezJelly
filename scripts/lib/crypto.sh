#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────
# ClezJelly — Credentials Encryption
# Verschlüsselt Secrets in .env.local mit openssl aes-256-cbc + PBKDF2
# ──────────────────────────────────────────────────────────────────
#
# Format der Datei:
#   .env.local       → verschlüsselt (binary, mit "Salted__" Header)
#   .env.local.plain → nur temporär im Memory beim Entschlüsseln
#
# Verwendung:
#   source scripts/lib/crypto.sh
#   crypto_encrypt_file .env.local.plain .env.local <passphrase>
#   crypto_decrypt_file .env.local        <passphrase>  → gibt Content auf stdout
#   crypto_prompt_passphrase               → fragt Passphrase, bestätigt
#   crypto_prompt_unlock                   → fragt zum Entschlüsseln
#
# ──────────────────────────────────────────────────────────────────

[[ -n "${CLEZJELLY_CRYPTO_LOADED:-}" ]] && return 0
CLEZJELLY_CRYPTO_LOADED=1

[[ -z "${CLEZJELLY_COMMON_LOADED:-}" ]] && source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

CRYPTO_CIPHER="aes-256-cbc"
CRYPTO_KDF_OPTS="-pbkdf2 -iter 200000"

crypto_check_openssl() {
  if ! command -v openssl &>/dev/null; then
    log_err "openssl ist nicht installiert"
    return 1
  fi
  return 0
}

# Verschlüsselt eine Plaintext-Datei → Ciphertext-Datei
crypto_encrypt_file() {
  local plain="$1"
  local cipher="$2"
  local pass="$3"
  openssl enc -$CRYPTO_CIPHER $CRYPTO_KDF_OPTS -salt \
    -in "$plain" -out "$cipher" -pass "pass:$pass"
}

# Entschlüsselt eine Ciphertext-Datei → stdout
crypto_decrypt_file() {
  local cipher="$1"
  local pass="$2"
  openssl enc -$CRYPTO_CIPHER $CRYPTO_KDF_OPTS -d \
    -in "$cipher" -pass "pass:$pass" 2>/dev/null
}

# Prüft ob die Passphrase die Datei entschlüsseln kann
crypto_verify_passphrase() {
  local cipher="$1"
  local pass="$2"
  crypto_decrypt_file "$cipher" "$pass" >/dev/null 2>&1
}

# Fragt Passphrase + Bestätigung (für Erst-Erstellung)
crypto_prompt_new_passphrase() {
  local p1 p2
  while true; do
    p1="$(prompt_secret 'Passphrase für Credentials-Verschlüsselung')"
    if [[ ${#p1} -lt 8 ]]; then
      log_warn "Passphrase sollte min. 8 Zeichen haben" >&2
      continue
    fi
    p2="$(prompt_secret 'Passphrase wiederholen')"
    if [[ "$p1" == "$p2" ]]; then
      echo "$p1"
      return 0
    fi
    log_warn "Passphrasen stimmen nicht überein" >&2
  done
}

# Fragt Passphrase zum Entschlüsseln (mit Retry)
crypto_prompt_unlock() {
  local cipher="$1"
  local pass tries=0
  while (( tries < 3 )); do
    pass="$(prompt_secret 'Passphrase zum Entschlüsseln')"
    if crypto_verify_passphrase "$cipher" "$pass"; then
      echo "$pass"
      return 0
    fi
    log_warn "Falsche Passphrase" >&2
    (( tries++ ))
  done
  log_err "Zu viele Fehlversuche" >&2
  return 1
}

# Lädt .env.local in current shell env (Export aller Variablen)
# Returns 0 wenn erfolgreich, 1 wenn Datei fehlt, 2 wenn passphrase falsch
crypto_source_envfile() {
  local cipher="$1"
  local pass="$2"
  [[ ! -f "$cipher" ]] && return 1
  local plain
  plain="$(crypto_decrypt_file "$cipher" "$pass")" || return 2
  # Export aller KEY=VAL Zeilen (ohne Kommentare)
  while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    export "$line"
  done <<< "$plain"
  return 0
}
