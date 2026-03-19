#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# acm — Antigravity Chat Monitor (compact)
# ════════════════════════════════════════════════════════════
#
# Shows the active conversation's ID, last modified time, and size
# with traffic-light status. Optionally runs every 15 minutes.
#
# USAGE:
#   acm              One-shot check
#   acm --watch      Run every 15 minutes (Ctrl+C to stop)
#
# TRAFFIC LIGHT:
#   🟢 < 10 MB    All clear
#   🟡 10–14 MB   Plan handoff
#   🔴 14+ MB     Hand off NOW
#
# ════════════════════════════════════════════════════════════

CONV_DIR="${HOME}/.gemini/antigravity/conversations"

check_once() {
  local NEWEST
  NEWEST=$(ls -t "$CONV_DIR"/*.pb 2>/dev/null | head -1)

  if [[ -z "$NEWEST" ]]; then
    echo "  (no conversations found)"
    return
  fi

  local ID BYTES MB SIZE ICON MODIFIED

  ID=$(basename "$NEWEST" .pb)

  # File size
  BYTES=$(stat -f%z "$NEWEST" 2>/dev/null || stat -c%s "$NEWEST" 2>/dev/null)

  # Size formatting
  if (( BYTES >= 1048576 )); then
    SIZE=$(echo "$BYTES" | awk '{ printf "%.1f MB", $1 / 1048576 }')
  elif (( BYTES >= 1024 )); then
    SIZE=$(echo "$BYTES" | awk '{ printf "%.0f KB", $1 / 1024 }')
  else
    SIZE="${BYTES} B"
  fi

  # Traffic light
  MB=$(( BYTES / 1048576 ))
  if (( MB >= 14 )); then
    ICON="🔴"
  elif (( MB >= 10 )); then
    ICON="🟡"
  else
    ICON="🟢"
  fi

  # Last modified (macOS BSD stat)
  MODIFIED=$(stat -f%Sm -t '%Y-%m-%d %H:%M:%S' "$NEWEST" 2>/dev/null \
    || stat -c%y "$NEWEST" 2>/dev/null | cut -d. -f1)

  echo "  File ID:   $ID"
  echo "  Modified:  $MODIFIED"
  echo "  Size:      $ICON   $SIZE"
}

# ── Main ─────────────────────────────────────────────────
if [[ "${1:-}" == "--watch" || "${1:-}" == "-w" ]]; then
  echo ""
  echo "  ╭─ ACM — Antigravity Chat Monitor (every 15 min) ─╮"
  echo "  │  Ctrl+C to stop                                  │"
  echo "  ╰──────────────────────────────────────────────────╯"
  echo ""

  while true; do
    echo "  ── $(date '+%H:%M') ──────────────────────────────"
    check_once
    echo ""
    sleep 900  # 15 minutes
  done
else
  echo ""
  check_once
  echo ""
fi
