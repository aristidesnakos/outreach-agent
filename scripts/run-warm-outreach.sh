#!/bin/bash
# Warm outreach pipeline — discovers contacts from websites, drafts relationship-building emails.
# Triggered by launchd or run manually.
#
# Usage: ./scripts/run-warm-outreach.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_BIN="${CLAUDE_BIN:-$(which claude 2>/dev/null || echo "$HOME/Library/pnpm/claude")}"
ENV_FILE="$PROJECT_DIR/.env"

# Export API key for Claude CLI (if set in .env, overrides Max subscription)
if [ -f "$ENV_FILE" ]; then
  _API_KEY="$(grep '^ANTHROPIC_API_KEY' "$ENV_FILE" 2>/dev/null | cut -d'=' -f2- | xargs)" || true
  [ -n "${_API_KEY:-}" ] && export ANTHROPIC_API_KEY="$_API_KEY"
fi

if [ "$(uname)" = "Darwin" ]; then
  LOG_DIR="${LOG_DIR:-$HOME/Library/Logs}"
else
  LOG_DIR="${LOG_DIR:-$HOME/logs}"
fi

mkdir -p "$LOG_DIR"

echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') — Starting warm outreach pipeline"

cd "$PROJECT_DIR"

"$CLAUDE_BIN" -p "$(cat "$SCRIPT_DIR/warm-outreach-prompt.md")" \
  --allowedTools "Read,Write,Bash(curl *),WebSearch,WebFetch,Glob,Grep" \
  --max-turns 40 \
  2>&1 | tee -a "$LOG_DIR/warm-outreach.log"

echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') — Warm outreach pipeline finished"
