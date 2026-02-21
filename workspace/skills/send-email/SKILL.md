---
name: send-email
description: Presents drafts to Telegram one at a time for approval, delivers via Resend on SEND
---

# Send Email

Process drafts ONE AT A TIME. Do NOT batch multiple drafts into one message.

Before starting, use file_read on operational-config.md. Copy all values exactly.

## Flow (repeat for each draft)

1. Send ONE draft to Telegram using the exact format below.
2. STOP. Wait for Ari's reply.
3. Process the reply (SEND, EDIT, or SKIP).
4. Only AFTER processing, move to the next draft.

Never send the next draft until the current one is resolved.

## Telegram Message Format

Plain text only. No markdown headers, no tables, no horizontal rules (---), no XML, no code blocks.

Copy this format exactly for each draft (fill in the bracketed parts):

OUTREACH DRAFT #[number]

To: [Name] ([Role], [Company])
Subject: [Subject line]

[Email body]

Research: [1-2 sentence summary of what you found]

Reply: SEND | EDIT [paste corrected email] | SKIP

## Reply Handling

SEND (also: s, yes, y, go, approve)
1. Send via Resend API using this exact http_request call:
   url: https://api.resend.com/emails
   method: POST
   headers: {"Authorization": "Bearer [RESEND_API_KEY from operational-config.md]", "Content-Type": "application/json"}
   body: {"from": "[FROM_NAME] <[FROM_EMAIL]>", "to": ["[recipient_email]"], "reply_to": "[REPLY_TO]", "subject": "[subject]", "text": "[email body]\n\n---\n[BUSINESS_ADDRESS]\nUnsubscribe: [UNSUBSCRIBE_BASE_URL]?email=[recipient_email]"}
2. Update memory: lead:{email} status "sent", draft:{email} status "sent"
3. Confirm to Telegram: "Sent to [name] at [email]"

EDIT (also: e, followed by corrected text)
1. memory_store key edit:{timestamp}, value {original_body, edited_body, lead_email}
2. Update draft:{email} with corrected body
3. Re-send the updated draft to Telegram for another approval round

SKIP (also: no, n, pass, next)
1. Update memory: lead:{email} status "skipped", draft:{email} status "skipped"
2. Confirm to Telegram: "Skipped [name] at [company]"

Unrecognized reply: "Didn't catch that. Reply SEND, EDIT [new text], or SKIP."

## Errors

Resend API error: report to Telegram, mark as "send_failed", do not retry.
