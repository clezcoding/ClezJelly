#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  ClezJelly — quick install                                       ║
# ║                                                                  ║
# ║  Clones the repo to ~/Desktop/ClezJelly and starts the installer ║
# ║                                                                  ║
# ║    bash <(curl -fsSL https://raw.githubusercontent.com/\         ║
# ║          clezcoding/ClezJelly/main/scripts/quickstart.sh)        ║
# ║                                                                  ║
# ║  Optional environment variables:                                 ║
# ║    CLEZJELLY_TARGET_DIR   another folder (default: Desktop)      ║
# ║    CLEZJELLY_BRANCH       another branch (default: main)         ║
# ╚══════════════════════════════════════════════════════════════════╝

# No `set -u`: the optional variables above may be unset.
set -eo pipefail

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RESET=$'\033[0m'; BOLD=$'\033[1m'
  VIOLET=$'\033[38;5;141m'; PINK=$'\033[38;5;212m'; OK=$'\033[38;5;78m'
  WARN=$'\033[38;5;214m'; ERR=$'\033[38;5;203m'; MUTE=$'\033[38;5;245m'
else
  RESET=""; BOLD=""; VIOLET=""; PINK=""; OK=""; WARN=""; ERR=""; MUTE=""
fi

: "${HOME:?HOME is not set}"
REPO_URL="https://github.com/clezcoding/ClezJelly.git"
TARGET_DIR="${CLEZJELLY_TARGET_DIR:-$HOME/Desktop/ClezJelly}"
BRANCH="${CLEZJELLY_BRANCH:-main}"

step() { printf '  %s◆%s %s%s%s\n' "$VIOLET" "$RESET" "$BOLD" "$1" "$RESET"; }
ok()   { printf '    %s✓%s %s\n' "$OK" "$RESET" "$1"; }
warn() { printf '    %s▲ %s%s\n' "$WARN" "$1" "$RESET"; }
err()  { printf '    %s✗ %s%s\n' "$ERR" "$1" "$RESET" >&2; }
note() { printf '    %s· %s%s\n' "$MUTE" "$1" "$RESET"; }

echo ""
printf '  %s▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪%s\n' "$MUTE" "$RESET"
echo ""
printf '  %s%sClez%s%s%sJelly%s   %squick install%s\n' "$BOLD" "$VIOLET" "$RESET" "$BOLD" "$PINK" "$RESET" "$MUTE" "$RESET"
echo ""

# ── Checks ────────────────────────────────────────────────────────
step "Checking your Mac"
if [[ "$(uname -s)" != "Darwin" ]]; then
  err "ClezJelly targets macOS (you're on $(uname -s))."
  exit 1
fi
ok "macOS $(sw_vers -productVersion) · $(uname -m)"

if ! command -v brew &>/dev/null; then
  err "Homebrew is missing. Install it first:"
  note '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi
ok "Homebrew"

if ! command -v git &>/dev/null; then
  warn "git is missing — installing it with Homebrew"
  brew install git
fi
ok "git"

# ── Get the code ──────────────────────────────────────────────────
echo ""
step "Getting ClezJelly → $TARGET_DIR"
if [[ -d "$TARGET_DIR/.git" ]]; then
  note "Already cloned — updating"
  git -C "$TARGET_DIR" pull --ff-only || {
    err "Couldn't fast-forward. You have local changes in $TARGET_DIR."
    note "Commit or stash them, then run this again."
    exit 1
  }
  ok "Up to date"
elif [[ -e "$TARGET_DIR" ]]; then
  err "$TARGET_DIR exists but isn't a ClezJelly clone."
  note "Move it away, or pick another folder:"
  note "CLEZJELLY_TARGET_DIR=\$HOME/Desktop/ClezJelly2 bash <(curl -fsSL …)"
  exit 1
else
  mkdir -p "$(dirname "$TARGET_DIR")"
  git clone --quiet --branch "$BRANCH" "$REPO_URL" "$TARGET_DIR"
  ok "Cloned"
fi

cd "$TARGET_DIR"
chmod +x install.sh scripts/*.sh 2>/dev/null || true

echo ""
step "Starting the installer"
echo ""
exec ./install.sh install
