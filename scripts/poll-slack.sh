#!/bin/bash
# Slack reply poller — checks thread replies on pending drafts for SEND/EDIT/SKIP.
# Runs every 2 minutes via launchd. No Claude tokens for SEND/SKIP.
# Only invokes Claude for EDIT (re-drafting with instructions).
# Supports multiple pipelines: iterates workspace/*/drafts/*.json
#
# Usage: ./scripts/poll-slack.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_BIN="${CLAUDE_BIN:-$(which claude 2>/dev/null || echo "$HOME/Library/pnpm/claude")}"
EDITS_DIR="$PROJECT_DIR/workspace/edits"
CONFIG_FILE="$PROJECT_DIR/workspace/operational-config.md"
ENV_FILE="$PROJECT_DIR/.env"

# --- Load environment ---
if [ ! -f "$ENV_FILE" ]; then
  echo "Error: $ENV_FILE not found"
  exit 1
fi

load_env_var() {
  grep "^$1=" "$ENV_FILE" | head -1 | cut -d'=' -f2- | xargs
}

# Export API key for Claude CLI (if set in .env, overrides Max subscription)
_API_KEY="$(load_env_var ANTHROPIC_API_KEY)" || true
[ -n "${_API_KEY:-}" ] && export ANTHROPIC_API_KEY="$_API_KEY"

SLACK_BOT_TOKEN="$(load_env_var SLACK_BOT_TOKEN)"
DEFAULT_CHANNEL="$(load_env_var SLACK_CHANNEL_ID)"

if [ -z "$SLACK_BOT_TOKEN" ]; then
  echo "Error: SLACK_BOT_TOKEN not set in .env"
  exit 1
fi

# --- Load email config from operational-config.md ---
load_config_var() {
  grep "^$1 = " "$CONFIG_FILE" | head -1 | sed "s/^$1 = //"
}

RESEND_API_KEY="$(load_config_var RESEND_API_KEY)"
FROM_EMAIL="$(load_config_var FROM_EMAIL)"
FROM_NAME="$(load_config_var FROM_NAME)"
REPLY_TO="$(load_config_var REPLY_TO)"

# --- Slack helpers ---
slack_api() {
  curl -s -X POST "https://slack.com/api/$1" \
    -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$2"
}

send_slack() {
  local channel="$1"
  local text="$2"
  local thread_ts="${3:-}"
  local payload
  if [ -n "$thread_ts" ]; then
    payload=$(jq -n --arg channel "$channel" --arg text "$text" --arg ts "$thread_ts" \
      '{channel: $channel, text: $text, thread_ts: $ts}')
  else
    payload=$(jq -n --arg channel "$channel" --arg text "$text" \
      '{channel: $channel, text: $text}')
  fi
  slack_api "chat.postMessage" "$payload"
}

# --- Check each pending draft's thread for replies ---
# Iterate all pipeline draft directories: workspace/*/drafts/*.json
for draft_file in "$PROJECT_DIR"/workspace/*/drafts/*.json; do
  [ -f "$draft_file" ] || continue

  STATUS=$(jq -r '.status // empty' "$draft_file")
  SLACK_TS=$(jq -r '.slack_ts // empty' "$draft_file")

  # Only check pending drafts that have been posted to Slack
  if [ "$STATUS" != "pending" ] || [ -z "$SLACK_TS" ] || [ "$SLACK_TS" = "null" ]; then
    continue
  fi

  # Read draft data
  TO_NAME=$(jq -r '.to_name' "$draft_file")
  TO_EMAIL=$(jq -r '.to_email' "$draft_file")
  TO_COMPANY=$(jq -r '.to_company' "$draft_file")
  SUBJECT=$(jq -r '.subject' "$draft_file")
  BODY=$(jq -r '.body' "$draft_file")

  # Per-draft channel (fall back to default from .env)
  DRAFT_CHANNEL=$(jq -r '.slack_channel // empty' "$draft_file")
  if [ -z "$DRAFT_CHANNEL" ] || [ "$DRAFT_CHANNEL" = "null" ]; then
    DRAFT_CHANNEL="$DEFAULT_CHANNEL"
  fi

  # Derive campaign name from path: workspace/{campaign}/drafts/file.json
  CAMPAIGN_NAME="$(basename "$(dirname "$(dirname "$draft_file")")")"

  # Per-draft EDIT voice rules (fall back to default)
  EDIT_VOICE_RULES=$(jq -r '.edit_voice_rules // empty' "$draft_file")
  if [ -z "$EDIT_VOICE_RULES" ] || [ "$EDIT_VOICE_RULES" = "null" ]; then
    EDIT_VOICE_RULES="exactly 3 sentences + sign-off (-- Ari), under 150 words, direct and technically credible"
  fi

  # Get thread replies
  REPLIES=$(curl -s -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
    "https://slack.com/api/conversations.replies?channel=${DRAFT_CHANNEL}&ts=${SLACK_TS}")

  OK=$(echo "$REPLIES" | jq -r '.ok')
  if [ "$OK" != "true" ]; then
    continue
  fi

  # If the bot spoke last, skip — ball is in the user's court
  LAST_IS_BOT=$(echo "$REPLIES" | jq -r '.messages | last | if .bot_id then "yes" else "no" end')
  if [ "$LAST_IS_BOT" = "yes" ]; then
    continue
  fi

  # Find the latest non-bot reply
  REPLY_TEXT=$(echo "$REPLIES" | jq -r '
    [.messages[] | select(.bot_id == null and .ts != "'"$SLACK_TS"'")] | last | .text // empty
  ')

  if [ -z "$REPLY_TEXT" ]; then
    continue
  fi

  # Normalize: lowercase, first line only, trim
  COMMAND=$(echo "$REPLY_TEXT" | head -1 | tr '[:upper:]' '[:lower:]' | xargs)

  # --- SEND ---
  if echo "$COMMAND" | grep -qE '^(send|s|yes|y|go|approve)$'; then
    FULL_BODY="${BODY}

---
Reply STOP to opt out."

    EMAIL_PAYLOAD=$(jq -n \
      --arg from "$FROM_NAME <$FROM_EMAIL>" \
      --arg to "$TO_EMAIL" \
      --arg reply_to "$REPLY_TO" \
      --arg subject "$SUBJECT" \
      --arg text "$FULL_BODY" \
      '{from: $from, to: [$to], reply_to: $reply_to, subject: $subject, text: $text}')

    RESEND_RESPONSE=$(curl -s -X POST "https://api.resend.com/emails" \
      -H "Authorization: Bearer ${RESEND_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "$EMAIL_PAYLOAD")

    RESEND_ID=$(echo "$RESEND_RESPONSE" | jq -r '.id // empty')

    if [ -n "$RESEND_ID" ] && [ "$RESEND_ID" != "null" ]; then
      jq --arg id "$RESEND_ID" --arg now "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        '.status = "sent" | .resend_id = $id | .sent_at = $now' "$draft_file" > "${draft_file}.tmp" \
        && mv "${draft_file}.tmp" "$draft_file"
      send_slack "$DRAFT_CHANNEL" "Sent to ${TO_NAME} at ${TO_EMAIL}" "$SLACK_TS" > /dev/null
      echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') — SENT [$CAMPAIGN_NAME]: $TO_EMAIL (Resend ID: $RESEND_ID)"
    else
      ERROR=$(echo "$RESEND_RESPONSE" | jq -r '.message // .error // "Unknown error"')
      jq '.status = "send_failed"' "$draft_file" > "${draft_file}.tmp" \
        && mv "${draft_file}.tmp" "$draft_file"
      send_slack "$DRAFT_CHANNEL" "Failed to send to ${TO_NAME}: ${ERROR}" "$SLACK_TS" > /dev/null
      echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') — SEND FAILED [$CAMPAIGN_NAME]: $TO_EMAIL — $ERROR"
    fi

  # --- SKIP ---
  elif echo "$COMMAND" | grep -qE '^(skip|no|n|pass|next)$'; then
    jq --arg now "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
      '.status = "skipped" | .skipped_at = $now' "$draft_file" > "${draft_file}.tmp" \
      && mv "${draft_file}.tmp" "$draft_file"
    send_slack "$DRAFT_CHANNEL" "Skipped ${TO_NAME} at ${TO_COMPANY}" "$SLACK_TS" > /dev/null
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') — SKIPPED [$CAMPAIGN_NAME]: $TO_EMAIL"

  # --- EDIT ---
  elif echo "$COMMAND" | grep -qE '^(edit|e)'; then
    EDIT_TEXT=$(echo "$REPLY_TEXT" | sed 's/^[Ee][Dd][Ii][Tt]\s*//' | sed 's/^[Ee]\s*//')

    if [ -z "$EDIT_TEXT" ]; then
      send_slack "$DRAFT_CHANNEL" "Got EDIT but no instructions. Reply with: EDIT [what to change]" "$SLACK_TS" > /dev/null
      continue
    fi

    # Save edit for voice learning
    mkdir -p "$EDITS_DIR"
    EDIT_FILE="$EDITS_DIR/$(date -u '+%Y%m%dT%H%M%SZ').json"
    jq -n \
      --arg original "$BODY" \
      --arg edited "$EDIT_TEXT" \
      --arg lead_email "$TO_EMAIL" \
      --arg campaign "$CAMPAIGN_NAME" \
      --arg timestamp "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
      '{original: $original, edited: $edited, lead_email: $lead_email, campaign: $campaign, timestamp: $timestamp}' \
      > "$EDIT_FILE"

    # Always invoke Claude to revise — EDIT text is revision instructions, not a replacement body
    cd "$PROJECT_DIR"
    EDIT_PROMPT="Re-draft this email based on feedback.

Original draft (for ${TO_NAME} at ${TO_COMPANY}):
Subject: ${SUBJECT}

${BODY}

Feedback: ${EDIT_TEXT}

Rules: ${EDIT_VOICE_RULES}. Apply the feedback to the original draft — do NOT echo the feedback as the email body. Output ONLY the revised subject and body, nothing else. Format:
Subject: [new subject]

[new body]"

    REVISED=$("$CLAUDE_BIN" -p "$EDIT_PROMPT" --max-turns 3 2>/dev/null)

    NEW_SUBJECT=$(echo "$REVISED" | head -1 | sed 's/^Subject: //')
    NEW_BODY=$(echo "$REVISED" | tail -n +3)

    if [ -n "$NEW_BODY" ]; then
      jq --arg body "$NEW_BODY" --arg subject "${NEW_SUBJECT:-$SUBJECT}" \
        '.body = $body | .subject = $subject' \
        "$draft_file" > "${draft_file}.tmp" \
        && mv "${draft_file}.tmp" "$draft_file"

      REVISED_MSG="*Revised draft:*
*Subject:* ${NEW_SUBJECT:-$SUBJECT}

${NEW_BODY}

Reply: *SEND* | *EDIT* [what to change] | *SKIP*"

      send_slack "$DRAFT_CHANNEL" "$REVISED_MSG" "$SLACK_TS" > /dev/null
      echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') — EDIT [$CAMPAIGN_NAME]: $TO_EMAIL"
    else
      send_slack "$DRAFT_CHANNEL" "Couldn't process that edit. Try again with: EDIT [what to change]" "$SLACK_TS" > /dev/null
      echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') — EDIT FAILED [$CAMPAIGN_NAME]: $TO_EMAIL"
    fi

  # --- UNRECOGNIZED ---
  else
    send_slack "$DRAFT_CHANNEL" "Didn't catch that. Reply *SEND*, *EDIT* [what to change], or *SKIP*." "$SLACK_TS" > /dev/null
  fi
done
