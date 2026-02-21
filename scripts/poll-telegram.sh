#!/bin/bash
# Telegram reply poller — checks for SEND/EDIT/SKIP replies to draft messages.
# Runs every 2 minutes via launchd. No Claude tokens for SEND/SKIP.
# Only invokes Claude for EDIT (re-drafting).
#
# Usage: ./scripts/poll-telegram.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CLAUDE_BIN="$HOME/Library/pnpm/claude"
DRAFTS_DIR="$PROJECT_DIR/workspace/drafts"
EDITS_DIR="$PROJECT_DIR/workspace/edits"
STATE_FILE="$PROJECT_DIR/workspace/state.json"
OFFSET_FILE="$PROJECT_DIR/workspace/telegram-offset.txt"
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

BOT_TOKEN="$(load_env_var TELEGRAM_BOT_TOKEN)"
OWNER_ID="$(load_env_var TELEGRAM_OWNER_ID)"

if [ -z "$BOT_TOKEN" ] || [ -z "$OWNER_ID" ]; then
  echo "Error: TELEGRAM_BOT_TOKEN or TELEGRAM_OWNER_ID not set in .env"
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
BUSINESS_ADDRESS="$(load_config_var BUSINESS_ADDRESS)"
UNSUBSCRIBE_BASE_URL="$(load_config_var UNSUBSCRIBE_BASE_URL)"

# --- Telegram helpers ---
tg_api() {
  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/$1" \
    -H "Content-Type: application/json" \
    -d "$2"
}

send_telegram() {
  local text="$1"
  local payload
  payload=$(jq -n --arg chat_id "$OWNER_ID" --arg text "$text" \
    '{chat_id: $chat_id, text: $text}')
  tg_api "sendMessage" "$payload"
}

# --- Get Telegram updates ---
OFFSET=0
if [ -f "$OFFSET_FILE" ]; then
  OFFSET=$(cat "$OFFSET_FILE")
fi

UPDATES=$(curl -s "https://api.telegram.org/bot${BOT_TOKEN}/getUpdates?offset=${OFFSET}&timeout=5")

# Check if we got any updates
UPDATE_COUNT=$(echo "$UPDATES" | jq '.result | length')
if [ "$UPDATE_COUNT" = "0" ] || [ "$UPDATE_COUNT" = "null" ]; then
  exit 0
fi

# --- Process each update ---
echo "$UPDATES" | jq -c '.result[]' | while IFS= read -r update; do
  UPDATE_ID=$(echo "$update" | jq -r '.update_id')
  # Advance offset past this update
  echo $((UPDATE_ID + 1)) > "$OFFSET_FILE"

  # Only process messages from the owner
  FROM_ID=$(echo "$update" | jq -r '.message.from.id // empty')
  if [ "$FROM_ID" != "$OWNER_ID" ]; then
    continue
  fi

  # Only process replies to bot messages
  REPLY_MSG_ID=$(echo "$update" | jq -r '.message.reply_to_message.message_id // empty')
  if [ -z "$REPLY_MSG_ID" ]; then
    continue
  fi

  REPLY_TEXT=$(echo "$update" | jq -r '.message.text // empty')
  if [ -z "$REPLY_TEXT" ]; then
    continue
  fi

  # Normalize reply: lowercase, trim whitespace
  COMMAND=$(echo "$REPLY_TEXT" | head -1 | tr '[:upper:]' '[:lower:]' | xargs)

  # --- Find the matching draft by telegram_message_id ---
  DRAFT_FILE=""
  for f in "$DRAFTS_DIR"/*.json; do
    [ -f "$f" ] || continue
    MSG_ID=$(jq -r '.telegram_message_id // empty' "$f")
    STATUS=$(jq -r '.status // empty' "$f")
    if [ "$MSG_ID" = "$REPLY_MSG_ID" ] && [ "$STATUS" = "pending" ]; then
      DRAFT_FILE="$f"
      break
    fi
  done

  if [ -z "$DRAFT_FILE" ]; then
    # Not a reply to a known pending draft — ignore
    continue
  fi

  # Read draft data
  TO_NAME=$(jq -r '.to_name' "$DRAFT_FILE")
  TO_EMAIL=$(jq -r '.to_email' "$DRAFT_FILE")
  TO_COMPANY=$(jq -r '.to_company' "$DRAFT_FILE")
  SUBJECT=$(jq -r '.subject' "$DRAFT_FILE")
  BODY=$(jq -r '.body' "$DRAFT_FILE")

  # --- SEND ---
  if echo "$COMMAND" | grep -qE '^(send|s|yes|y|go|approve)$'; then
    # Build email body with footer
    FULL_BODY="${BODY}

---
${BUSINESS_ADDRESS}
Unsubscribe: ${UNSUBSCRIBE_BASE_URL}?email=${TO_EMAIL}"

    # Send via Resend API
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
      # Update draft status
      jq --arg id "$RESEND_ID" --arg now "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
        '.status = "sent" | .resend_id = $id | .sent_at = $now' "$DRAFT_FILE" > "${DRAFT_FILE}.tmp" \
        && mv "${DRAFT_FILE}.tmp" "$DRAFT_FILE"
      send_telegram "Sent to ${TO_NAME} at ${TO_EMAIL}" > /dev/null
      echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') — SENT: $TO_EMAIL (Resend ID: $RESEND_ID)"
    else
      ERROR=$(echo "$RESEND_RESPONSE" | jq -r '.message // .error // "Unknown error"')
      jq '.status = "send_failed"' "$DRAFT_FILE" > "${DRAFT_FILE}.tmp" \
        && mv "${DRAFT_FILE}.tmp" "$DRAFT_FILE"
      send_telegram "Failed to send to ${TO_NAME}: ${ERROR}" > /dev/null
      echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') — SEND FAILED: $TO_EMAIL — $ERROR"
    fi

  # --- SKIP ---
  elif echo "$COMMAND" | grep -qE '^(skip|no|n|pass|next)$'; then
    jq --arg now "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
      '.status = "skipped" | .skipped_at = $now' "$DRAFT_FILE" > "${DRAFT_FILE}.tmp" \
      && mv "${DRAFT_FILE}.tmp" "$DRAFT_FILE"
    send_telegram "Skipped ${TO_NAME} at ${TO_COMPANY}" > /dev/null
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') — SKIPPED: $TO_EMAIL"

  # --- EDIT ---
  elif echo "$COMMAND" | grep -qE '^(edit|e)'; then
    # Extract the correction text (everything after the first word)
    EDIT_TEXT=$(echo "$REPLY_TEXT" | sed 's/^[Ee][Dd][Ii][Tt]\s*//' | sed 's/^[Ee]\s*//')

    if [ -z "$EDIT_TEXT" ]; then
      send_telegram "Got EDIT but no correction text. Reply with: EDIT [your corrected email]" > /dev/null
      continue
    fi

    # Save the edit for voice learning
    mkdir -p "$EDITS_DIR"
    EDIT_FILE="$EDITS_DIR/$(date -u '+%Y%m%dT%H%M%SZ').json"
    jq -n \
      --arg original "$BODY" \
      --arg edited "$EDIT_TEXT" \
      --arg lead_email "$TO_EMAIL" \
      --arg timestamp "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" \
      '{original: $original, edited: $edited, lead_email: $lead_email, timestamp: $timestamp}' \
      > "$EDIT_FILE"

    # Check if the edit text is a full replacement or instructions
    WORD_COUNT=$(echo "$EDIT_TEXT" | wc -w | xargs)

    if [ "$WORD_COUNT" -gt 20 ]; then
      # Likely a full replacement — use it directly
      jq --arg body "$EDIT_TEXT" '.body = $body | .telegram_message_id = null' \
        "$DRAFT_FILE" > "${DRAFT_FILE}.tmp" \
        && mv "${DRAFT_FILE}.tmp" "$DRAFT_FILE"

      # Re-read for Telegram
      RESEARCH=$(jq -r '.research_summary' "$DRAFT_FILE")
      DRAFT_NUM=$(jq -r '.draft_number // "?"' "$DRAFT_FILE")

      REVISED_MSG="REVISED DRAFT #${DRAFT_NUM}

To: ${TO_NAME} (${TO_COMPANY})
Subject: ${SUBJECT}

${EDIT_TEXT}

Research: ${RESEARCH}

Reply: SEND | EDIT [paste corrected email] | SKIP"

      TG_RESPONSE=$(send_telegram "$REVISED_MSG")
      NEW_MSG_ID=$(echo "$TG_RESPONSE" | jq -r '.result.message_id // empty')
      if [ -n "$NEW_MSG_ID" ]; then
        jq --arg mid "$NEW_MSG_ID" '.telegram_message_id = ($mid | tonumber)' \
          "$DRAFT_FILE" > "${DRAFT_FILE}.tmp" \
          && mv "${DRAFT_FILE}.tmp" "$DRAFT_FILE"
      fi
      echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') — EDIT (replacement): $TO_EMAIL"
    else
      # Short text — likely instructions. Invoke Claude to re-draft.
      cd "$PROJECT_DIR"
      EDIT_PROMPT="Re-draft this email based on Ari's feedback.

Original draft (from $(cat "$DRAFT_FILE" | jq -r '.to_name') at $(cat "$DRAFT_FILE" | jq -r '.to_company')):
Subject: ${SUBJECT}

${BODY}

Ari's feedback: ${EDIT_TEXT}

Rules: exactly 3 sentences + sign-off (-- Ari), under 150 words, direct and technically credible. Output ONLY the revised subject and body, nothing else. Format:
Subject: [new subject]

[new body]"

      REVISED=$("$CLAUDE_BIN" -p "$EDIT_PROMPT" --max-turns 3 2>/dev/null)

      # Parse revised subject and body
      NEW_SUBJECT=$(echo "$REVISED" | grep -m1 '^Subject:' | sed 's/^Subject: //')
      NEW_BODY=$(echo "$REVISED" | sed '1,/^Subject:/d' | sed '/^$/d')

      if [ -n "$NEW_BODY" ]; then
        jq --arg body "$NEW_BODY" --arg subject "${NEW_SUBJECT:-$SUBJECT}" \
          '.body = $body | .subject = $subject | .telegram_message_id = null' \
          "$DRAFT_FILE" > "${DRAFT_FILE}.tmp" \
          && mv "${DRAFT_FILE}.tmp" "$DRAFT_FILE"

        RESEARCH=$(jq -r '.research_summary' "$DRAFT_FILE")
        DRAFT_NUM=$(jq -r '.draft_number // "?"' "$DRAFT_FILE")

        REVISED_MSG="REVISED DRAFT #${DRAFT_NUM}

To: ${TO_NAME} (${TO_COMPANY})
Subject: ${NEW_SUBJECT:-$SUBJECT}

${NEW_BODY}

Research: ${RESEARCH}

Reply: SEND | EDIT [paste corrected email] | SKIP"

        TG_RESPONSE=$(send_telegram "$REVISED_MSG")
        NEW_MSG_ID=$(echo "$TG_RESPONSE" | jq -r '.result.message_id // empty')
        if [ -n "$NEW_MSG_ID" ]; then
          jq --arg mid "$NEW_MSG_ID" '.telegram_message_id = ($mid | tonumber)' \
            "$DRAFT_FILE" > "${DRAFT_FILE}.tmp" \
            && mv "${DRAFT_FILE}.tmp" "$DRAFT_FILE"
        fi
        echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') — EDIT (Claude re-draft): $TO_EMAIL"
      else
        send_telegram "Couldn't process that edit. Try again with: EDIT [full corrected email]" > /dev/null
        echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') — EDIT FAILED: $TO_EMAIL"
      fi
    fi

  # --- UNRECOGNIZED ---
  else
    send_telegram "Didn't catch that. Reply SEND, EDIT [new text], or SKIP." > /dev/null
  fi
done
