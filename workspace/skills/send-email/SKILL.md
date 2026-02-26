---
name: send-email
description: Presents drafts to Slack one at a time for approval, delivers via Resend on SEND
---

# Send Email

Process drafts ONE AT A TIME. Do NOT batch multiple drafts into one message.

Before starting, use file_read on operational-config.md. Copy all values exactly.

## Flow (repeat for each draft)

1. Send ONE draft to Slack using the exact format below.
2. STOP. Wait for Ari's reply.
3. Process the reply (SEND, EDIT, or SKIP).
4. Only AFTER processing, move to the next draft.

Never send the next draft until the current one is resolved.

## Slack Message Format

Plain text only. No markdown headers, no tables, no horizontal rules (---), no XML, no code blocks.

Copy this format exactly for each draft (fill in the bracketed parts):

OUTREACH DRAFT #[number]

To: [Name] ([Role], [Company])
Subject: [Subject line]

[Email body]

Research: [1-2 sentence summary of what you found]

Reply: SEND | EDIT [revision instructions] | SKIP

## Reply Handling

SEND (also: s, yes, y, go, approve)
1. Send via Resend API using this exact http_request call:
   url: https://api.resend.com/emails
   method: POST
   headers: {"Authorization": "Bearer [RESEND_API_KEY from operational-config.md]", "Content-Type": "application/json"}
   body: {"from": "[FROM_NAME] <[FROM_EMAIL]>", "to": ["[recipient_email]"], "reply_to": "[REPLY_TO]", "subject": "[subject]", "text": "[email body]\n\n---\n[BUSINESS_ADDRESS]\nUnsubscribe: [UNSUBSCRIBE_BASE_URL]?email=[recipient_email]"}
2. Update memory: lead:{email} status "sent", draft:{email} status "sent"
3. Confirm to Slack: "Sent to [name] at [email]"

EDIT (also: e, followed by revision instructions)
1. Recall the current draft from memory (draft:{email})
2. Treat the text after EDIT as revision instructions — NOT as the email body
3. Rewrite the draft by applying those instructions to the current draft body. Keep the structure, voice, and format. Only change what the instructions ask for.
4. BEFORE sending: verify the revised body reads like an email, not like instructions. If it contains phrases like "make it more...", "mention that...", "add a..." — you echoed the instructions instead of applying them. Fix it.
5. memory_store key edit:{timestamp}, value {original_body, revised_body, revision_instructions, lead_email}
6. Update draft:{email} with the revised body
7. Re-send the updated draft to Slack for another approval round (same format as original)

SKIP (also: no, n, pass, next)
1. Update memory: lead:{email} status "skipped", draft:{email} status "skipped"
2. Confirm to Slack: "Skipped [name] at [company]"

Unrecognized reply: "Didn't catch that. Reply SEND, EDIT [what to change], or SKIP."

## Errors

Resend API error: report to Slack, mark as "send_failed", do not retry.
