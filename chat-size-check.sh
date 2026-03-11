#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════
# chat-size-check.sh — Antigravity IDE Conversation Size Monitor
# ════════════════════════════════════════════════════════════
#
# Monitors .pb conversation file sizes to prevent IDE slowdowns.
# Antigravity stores each chat as a Protocol Buffer (.pb) file.
# Files over ~15 MB cause slow loads, spinning, and UI freezes.
# Files over ~25 MB can lock the chat panel entirely.
#
# This script gives you early warning so you can hand off to a
# new conversation at a natural breaking point — not mid-crisis.
#
# USAGE:
#   ./chat-size-check.sh              List all conversations (sorted by size)
#   ./chat-size-check.sh <id>         Check a specific conversation
#   ./chat-size-check.sh --help       Show this help
#
# TRAFFIC LIGHT:
#   🟢  Under 10 MB — All clear
#   🟡  10–14 MB   — Wrap up current job, plan handoff
#   🔴  14+ MB     — Stop after current task, hand off NOW
#
# CONVERSATIONS DIRECTORY:
#   macOS/Linux: ~/.gemini/antigravity/conversations/
#
# COMPATIBILITY:
#   macOS (BSD stat) and Linux (GNU stat). Requires bash 4+.
#
# LICENSE: MIT (same as AG-Chat-Recovery)
# ════════════════════════════════════════════════════════════

set -euo pipefail

CONV_DIR="${HOME}/.gemini/antigravity/conversations"

# ── Help ──────────────────────────────────────────────────
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<'HELP'
chat-size-check.sh — Antigravity IDE Conversation Size Monitor

Monitors .pb conversation file sizes to prevent IDE slowdowns.
Antigravity stores each chat as a Protocol Buffer (.pb) file.
Files over ~15 MB cause slow loads, spinning, and UI freezes.

USAGE:
  ./chat-size-check.sh              List all conversations (sorted by size)
  ./chat-size-check.sh <id>         Check a specific conversation
  ./chat-size-check.sh --help       Show this help

TRAFFIC LIGHT:
  🟢  Under 10 MB — All clear
  🟡  10–14 MB   — Wrap up current job, plan handoff
  🔴  14+ MB     — Stop after current task, hand off NOW
HELP
    exit 0
fi

# ── Verify directory exists ──────────────────────────────
if [[ ! -d "$CONV_DIR" ]]; then
    echo "ERROR: Conversations directory not found: $CONV_DIR"
    echo "       Is Antigravity installed?"
    exit 1
fi

# ── Cross-platform file size (BSD stat vs GNU stat) ──────
get_file_size() {
    local file="$1"
    if stat -f%z "$file" 2>/dev/null; then
        return
    fi
    stat -c%s "$file" 2>/dev/null
}

# ── Human-readable size ──────────────────────────────────
format_size() {
    local bytes=$1
    if (( bytes >= 1048576 )); then
        # Use awk for portable float division (bash can't do float math)
        echo "${bytes}" | awk '{ printf "%.1f MB", $1 / 1048576 }'
    elif (( bytes >= 1024 )); then
        echo "${bytes}" | awk '{ printf "%.0f KB", $1 / 1024 }'
    else
        printf "%d B" "$bytes"
    fi
}

# ── Traffic light classification ─────────────────────────
traffic_light() {
    local bytes=$1
    local mb=$(( bytes / 1048576 ))
    if (( mb >= 14 )); then
        echo "🔴 STOP — Hand off after current task"
    elif (( mb >= 10 )); then
        echo "🟡 WRAP UP — Plan handoff at next good break"
    else
        echo "🟢 ALL CLEAR"
    fi
}

# ── Header ───────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════════════════════"
echo "  ANTIGRAVITY CHAT SIZE MONITOR"
echo "  $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "════════════════════════════════════════════════════════════"
echo ""

# ── Single conversation mode ─────────────────────────────
if [[ -n "${1:-}" ]]; then
    FILE="$CONV_DIR/$1.pb"
    if [[ ! -f "$FILE" ]]; then
        echo "  File not found: $1.pb"
        exit 1
    fi
    BYTES=$(get_file_size "$FILE")
    SIZE=$(format_size "$BYTES")
    LIGHT=$(traffic_light "$BYTES")
    echo "  Conversation: $1"
    echo "  Size:         $SIZE"
    echo "  Status:       $LIGHT"
else
    # ── List all conversations, sorted by size (largest first) ─
    printf "  %-8s  %-38s  %s\n" "SIZE" "CONVERSATION ID" "STATUS"
    echo "  ────────  ──────────────────────────────────────  ─────────────────────────────────────"

    # Count for summary
    total=0
    green=0
    yellow=0
    red=0

    for f in $(ls -S "$CONV_DIR"/*.pb 2>/dev/null); do
        ID=$(basename "$f" .pb)
        BYTES=$(get_file_size "$f")
        SIZE=$(format_size "$BYTES")
        LIGHT=$(traffic_light "$BYTES")
        printf "  %-8s  %-38s  %s\n" "$SIZE" "$ID" "$LIGHT"

        total=$((total + 1))
        mb=$((BYTES / 1048576))
        if (( mb >= 14 )); then
            red=$((red + 1))
        elif (( mb >= 10 )); then
            yellow=$((yellow + 1))
        else
            green=$((green + 1))
        fi
    done

    if (( total == 0 )); then
        echo "  (no conversations found)"
    else
        echo ""
        echo "  Summary: $total conversations — 🟢 $green  🟡 $yellow  🔴 $red"
    fi
fi

echo ""
echo "  Thresholds: 🟢 <10 MB  |  🟡 10-14 MB (plan handoff)  |  🔴 14+ MB (hand off NOW)"
echo ""
