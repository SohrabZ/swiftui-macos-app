#!/usr/bin/env bash
#
# verify.sh — one-shot verification loop for LiquidGlassDemo.
#
#   build  ->  test  ->  render snapshot  ->  report
#
# Exits non-zero if any stage fails, so it works as a gate in an agentic loop:
# "make a change, run ./verify.sh, inspect the snapshot, repeat". The snapshot is
# the visual-confirmation artifact — an agent (or you) opens it to confirm the
# glass card actually rendered, which a green build/test can't prove on its own.
#
# The default snapshot is rendered in-process via SwiftUI's ImageRenderer: no
# window, no Screen Recording permission, deterministic — ideal for CI.
#
# Usage:
#   ./verify.sh                 # build + test + snapshot (default)
#   ./verify.sh --no-visual     # build + test only
#   ./verify.sh --live          # also grab a live window screenshot (needs
#                               #   Screen Recording permission; pixel-accurate,
#                               #   captures the real material blur + toggle)
#
set -euo pipefail
cd "$(dirname "$0")"

VISUAL=1
LIVE=0
for arg in "$@"; do
  case "$arg" in
    --no-visual) VISUAL=0 ;;
    --live)      LIVE=1 ;;
    *) echo "unknown flag: $arg" >&2; exit 2 ;;
  esac
done

ART_DIR="verify-artifacts"
SHOT="$ART_DIR/screenshot.png"
LIVE_SHOT="$ART_DIR/screenshot-live.png"
LOG="$ART_DIR/app.log"
mkdir -p "$ART_DIR"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
fail() { printf '\n\033[1;31mFAIL: %s\033[0m\n' "$1" >&2; exit 1; }

step "[1/4] Building"
swift build || fail "build failed"

step "[2/4] Testing"
swift test || fail "tests failed"

if [[ "$VISUAL" -eq 0 ]]; then
  printf '\n\033[1;32mPASS: build + tests green (visual step skipped)\033[0m\n'
  exit 0
fi

BIN="$(swift build --show-bin-path)/LiquidGlassDemo"
[[ -x "$BIN" ]] || fail "executable not found at $BIN"

step "[3/4] Rendering snapshot -> $SHOT"
"$BIN" --snapshot "$SHOT" --size 1180x760 || fail "snapshot render failed"
[[ -s "$SHOT" ]] || fail "snapshot is empty"

if [[ "$LIVE" -eq 1 ]]; then
  step "[4/4] Live window capture -> $LIVE_SHOT"
  "$BIN" >"$LOG" 2>&1 &
  APP_PID=$!
  trap 'kill "$APP_PID" 2>/dev/null || true; wait "$APP_PID" 2>/dev/null || true' EXIT
  sleep 3
  kill -0 "$APP_PID" 2>/dev/null || { echo "--- app.log ---"; cat "$LOG"; fail "app exited early"; }
  osascript -e 'tell application "System Events" to set frontmost of (first process whose name is "LiquidGlassDemo") to true' 2>/dev/null || true
  sleep 1
  if screencapture -x "$LIVE_SHOT" 2>/dev/null && [[ -s "$LIVE_SHOT" ]]; then
    echo "  Live screenshot: $LIVE_SHOT"
  else
    echo "  (live capture unavailable — grant Screen Recording permission in System Settings > Privacy)"
  fi
fi

printf '\n\033[1;32mPASS: build + tests green; snapshot rendered.\033[0m\n'
echo "  Snapshot: $SHOT"
echo
echo "Next (agentic loop): inspect $SHOT to confirm the glass card rendered,"
echo "then make a change and re-run ./verify.sh."
