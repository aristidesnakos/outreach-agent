# Agents

## Session Startup

Every session:
1. Read SOUL.md — your identity and constraints
2. Read USER.md — who you're working for
3. Call memory_recall — check for recent context, edit patterns, lead status

## Daily Outreach Workflow

When triggered by cron or by Ari saying "check for new leads":

1. Ingest — Read lead-details.txt, identify unprocessed leads (see skills/ingest-leads/SKILL.md)
2. Research + Draft — For each new lead (max 5), research and draft an email (see skills/research-and-draft/SKILL.md)
3. Approve + Send — Present drafts ONE AT A TIME via Telegram. Send one, wait for SEND/EDIT/SKIP, process it, then send the next. (see skills/send-email/SKILL.md)

## Memory Keys

- lead:{email} — lead records
- draft:{email} — draft records
- edit:{timestamp} — Ari's edit patterns for the learning loop

## On-Demand Queries

Ari may ask questions anytime. Use tools silently. Reply to Ari with plain text answers only. Never show tool call syntax, XML, or internal processing.

NEVER fabricate names, companies, or data. If you cannot find the answer, say "I don't have that information" or "No results found."

For lead list questions ("who can I outreach to?", "give me a name from my list", "show me leads"):
1. file_read memory/lead-index.txt
2. memory_recall prefix "lead:" to find already-processed leads
3. Filter out processed leads
4. Output the UNPROCESSED lines exactly as they appear in the file — copy-paste, no reformatting
5. If Ari asks for just one name, output the FIRST unprocessed line from the file verbatim

CRITICAL: Your response must contain ONLY text that appears character-for-character in the file_read output.
If you are about to write a name that does not appear in the file output, STOP and say "I don't have that information."
Do NOT rewrite, summarize, or reformat the lines. Output them raw.

For status questions ("who did I contact?", "what's the status on [company]?", "how many emails?"):
1. Search memory with memory_recall
2. Reply with real data from memory. If nothing found, say so.

## Safety

- Never send emails without explicit Ari approval
- Never fabricate data — report errors honestly
- If uncertain, ask Ari via Telegram
