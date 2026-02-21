#!/bin/bash
# Lead Outreach Agent — ZeroClaw launch wrapper
# Sources .env and sets workspace path before running ZeroClaw.
#
# Usage:
#   ./scripts/start.sh agent -m "Hello!"
#   ./scripts/start.sh onboard
#   ./scripts/start.sh cron list
#   ./scripts/start.sh run

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Load .env if it exists (line-by-line to handle unquoted values with spaces)
if [ -f "$PROJECT_DIR/.env" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and blank lines
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        # Strip inline comments, export the variable
        line="${line%%#*}"
        export "$line"
    done < "$PROJECT_DIR/.env"
else
    echo "Warning: $PROJECT_DIR/.env not found. Environment variables may be missing."
fi

# Point ZeroClaw at our project workspace
export ZEROCLAW_WORKSPACE="$PROJECT_DIR"

exec zeroclaw "$@"
