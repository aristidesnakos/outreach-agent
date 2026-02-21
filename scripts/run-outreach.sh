#!/bin/bash
# Morning outreach pipeline — runs claude -p headlessly
# Triggered by launchd daily at 9 AM Athens time.
#
# Usage: ./scripts/run-outreach.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_BIN="$HOME/Library/pnpm/claude"
LOG_DIR="$HOME/Library/Logs"

mkdir -p "$LOG_DIR"

echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') — Starting outreach pipeline"

cd "$PROJECT_DIR"

"$CLAUDE_BIN" -p "$(cat "$SCRIPT_DIR/outreach-prompt.md")" \
  --allowedTools "Read,Write,Bash(curl *),WebSearch,WebFetch,Glob,Grep" \
  --max-turns 40 \
  2>&1 | tee -a "$LOG_DIR/outreach-morning.log"

echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') — Outreach pipeline finished"
