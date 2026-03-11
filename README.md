# AG Chat Monitor

A lightweight shell script that monitors Antigravity IDE conversation sizes so you can hand off to a new chat **before** things get slow — not in the middle of a crisis.

## The Problem

Antigravity stores each chat as a `.pb` (Protocol Buffer) file that grows without limit. At **~15 MB**, the IDE starts lagging. At **~25 MB**, the chat panel can freeze entirely. There's no built-in warning, so you don't notice until it's too late.

This script gives you a traffic light so you can plan a clean handoff:

```
════════════════════════════════════════════════════════════
  ANTIGRAVITY CHAT SIZE MONITOR
  2026-03-11 19:36:53 EDT
════════════════════════════════════════════════════════════

  SIZE      CONVERSATION ID                         STATUS
  ────────  ──────────────────────────────────────  ─────────────────────────────────
  13.9 MB   e99f1fec-8a22-49ee-b14a-5af1e3b8ae9e    🟡 WRAP UP — Plan handoff at next good break
  8.6 MB    eefed551-edf7-4f6f-99f7-2aded15eb3b2    🟢 ALL CLEAR
  515 KB    eaccd6a5-ae2c-40f0-8fd1-fcb7b5880709    🟢 ALL CLEAR

  Summary: 3 conversations — 🟢 2  🟡 1  🔴 0

  Thresholds: 🟢 <10 MB  |  🟡 10-14 MB (plan handoff)  |  🔴 14+ MB (hand off NOW)
```

## Installation

```bash
# Clone the repo
git clone https://github.com/JeanScottHomes/ag-chat-monitor.git

# Make it executable
chmod +x ag-chat-monitor/chat-size-check.sh

# (Optional) Copy to a folder on your PATH
cp ag-chat-monitor/chat-size-check.sh /usr/local/bin/
```

## Usage

```bash
# List all conversations sorted by size
./chat-size-check.sh

# Check a specific conversation
./chat-size-check.sh <conversation-id>

# Show help
./chat-size-check.sh --help
```

## Traffic Light System

| Status | Size | What To Do |
|--------|------|------------|
| 🟢 ALL CLEAR | Under 10 MB | Keep working |
| 🟡 WRAP UP | 10–14 MB | Finish your current task, then start a new chat |
| 🔴 STOP | 14+ MB | Hand off immediately after the current task |

## When To Run It

- **Start of each session** — know where you stand
- **After big tasks** — multiple file edits, deploys, debugging sessions
- **Before handoffs** — confirm the outgoing chat is worth retiring

You don't need a cron job. Just run it when you think about it, or ask your AI agent to check periodically.

## How It Works

The script scans `~/.gemini/antigravity/conversations/` for `.pb` files, reads their size, and classifies each one. It's **read-only** — it never modifies, moves, or deletes anything.

## Compatibility

- **macOS** (BSD `stat`) ✅
- **Linux** (GNU `stat`) ✅
- Requires **bash 4+**
- Windows users: see [AG-Chat-Recovery](https://github.com/Artemis43/AG-Chat-Recovery) for a Windows-native tool that recovers conversations after they've already become corrupted.

## Related

- [AG-Chat-Recovery](https://github.com/Artemis43/AG-Chat-Recovery) — recovers corrupted/blocked Antigravity conversations. Our script is a **complement**: they fix the problem after it happens; we help you avoid it in the first place.

## License

[MIT](LICENSE)
