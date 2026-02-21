---
name: ingest-leads
description: Reads leads from text file and stores new ones in memory
---

# Ingest Leads

Read the lead details file, identify new leads, and store them in memory for processing.

## When to Run

Daily at 9:00 AM (triggered by cron), or on-demand when Ari says "check for new leads".

## Steps

1. Read leads -- Use file_read to read memory/lead-details.txt

2. Parse records -- Each lead is separated by "=== LEAD ===" and has Key: Value fields:
   Name, Company, Role, Email, Website, Location, LinkedIn, Headline, Summary

3. Deduplicate -- For each lead:
   - Use memory_recall to check for key lead:{email}
   - If new: use memory_store to save with key lead:{email} and value {name, company, role, email, website, location, linkedin, headline, summary, status: "new", ingested_at: [today]}
   - If existing: skip (do not overwrite)

4. Report to Telegram (plain text, one line):
   Ingested [N] new leads, [M] already known.

## After Ingestion

Pass the list of new lead emails to the research-and-draft skill for processing. Process max 5 per run.

## Error Handling

- file_read fails: Report to Telegram "Failed to read lead file: [error]". Do NOT fabricate leads.
- File empty or missing: Report to Telegram "Lead file not found or empty. Run: python3 scripts/prepare-leads.py"
- NEVER fabricate lead data. If you cannot read or parse the file, say so.
