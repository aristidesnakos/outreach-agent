# ZeroClaw Lead Outreach Agent — PRD

**Project Owner:** Ari — The Auspicious Company
**Status:** Experiment / V1
**Runtime:** ZeroClaw (Rust, self-hosted)
**Primary Channel:** Telegram
**LLM Provider:** Anthropic Claude via OpenRouter

---

## Problem

Personalized outreach is the highest-leverage client acquisition activity — and the most neglected. Leads sit untouched because the friction of researching each contact, drafting a message, and sending it is too high relative to competing priorities.

## Hypothesis

If an autonomous agent handles research and drafting, and delivers ready-to-send emails via Telegram for one-tap approval, outreach volume increases 3–5x with no increase in time investment.

## Success Criteria

| Metric | Target |
|--------|--------|
| Activation | Agent processes at least 5 leads/week |
| Quality | 80%+ of drafts approved with zero or minor edits |
| Behavior change | 3x more outreach emails/week vs. manual baseline |
| Experiment signal | Within 30 days, decide: invest, pivot, or kill |

---

## System Architecture

| Component | Implementation |
|-----------|---------------|
| Runtime | ZeroClaw daemon (Rust binary, <5MB RAM) |
| LLM | Claude Sonnet via OpenRouter |
| Channel | Telegram Bot (private, allowlisted to Ari) |
| Data Source | Google Sheet (published as CSV) |
| Web Research | ZeroClaw browser + http_request tools |
| Email Sending | Resend API via http_request |
| Memory | SQLite hybrid search (built-in) |
| Scheduling | ZeroClaw cron (daily 9:00 AM Athens) |

---

## User Flow

1. Ari adds leads to Google Sheet (name, company, role, website, optional notes)
2. Every morning at 9:00 AM Athens, ZeroClaw fetches CSV and identifies unprocessed rows
3. For each lead: visit company website, read about page and news, build contact profile
4. Draft personalized email using Ari's voice, services, and research findings
5. Send draft to Telegram: recipient, subject, body, research summary
6. Ari replies: **SEND** (as-is), **EDIT** [instructions] (revise), or **SKIP** (move on)
7. On SEND: email sent via Resend, outcome logged in memory
8. Ari can query agent anytime: "Who did I contact this week?"

---

## Google Sheet Schema

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| name | String | Yes | Full name of the contact |
| company | String | Yes | Company or organization |
| role | String | No | Job title or role |
| email | String | Yes | Contact email address |
| website | String | No | Company website for research |
| notes | String | No | Custom context |
| status | String | Auto | Tracked in agent memory (not written to sheet) |
| sent_date | Date | Auto | Tracked in agent memory (not written to sheet) |

---

## Telegram Draft Format

```
OUTREACH DRAFT #14

To: Marcus Chen (CTO, BuildCorp)
Subject: AI-Powered Safety Compliance for NSW Sites

[Email body here]

Research: BuildCorp won 3 NSW tenders in Q4.
Recent DA filings suggest 2 new projects in Western Sydney.
No visible AI/compliance tooling on their site.

Reply: SEND | EDIT [paste corrected email] | SKIP
```

---

## Agent Voice

- Direct, technically credible, zero fluff
- Lead with a specific observation from research
- Reference "Physical Intelligence" thesis when relevant
- Emails under 150 words: one hook, one value prop, one soft CTA
- Peer-to-peer tone, never vendor-to-prospect

---

## Scope Boundaries

**In scope (V1):** Read Google Sheet, web research, draft emails, Telegram approval, send via Resend, log in memory.

**Out of scope (V1):** Reply tracking, multi-step sequences, automated follow-ups, CRM integration, LinkedIn messaging, writing back to the sheet.

---

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| Shallow web research | Supplement with notes column; iterate on research prompt |
| Email deliverability | Use existing domain with SPF/DKIM; warm up at low volume |
| Hallucinated contact details | Human approval gate; never auto-send; show sources |
| ZeroClaw instability | Pin to stable release; keep manual fallback workflow |
| Low usage after novelty | Morning cron nudge; track weekly volume; kill at 30 days |

---

## Environment Variables

```
OPENROUTER_API_KEY      — LLM provider
TELEGRAM_BOT_TOKEN      — Telegram bot
TELEGRAM_OWNER_ID       — Ari's Telegram user ID
GOOGLE_SHEET_CSV_URL    — Published Google Sheet CSV URL
RESEND_API_KEY          — Email delivery
FROM_EMAIL              — Sender email address
FROM_NAME               — Sender display name
REPLY_TO                — Reply-to address
BUSINESS_ADDRESS        — Physical address (compliance)
UNSUBSCRIBE_BASE_URL    — Unsubscribe link base URL
```

---

## Decision Gate (Day 30)

| Outcome | Action |
|---------|--------|
| **Invest** | Add follow-up sequences, reply tracking, CRM sync |
| **Pivot** | Repurpose ZeroClaw for different use case |
| **Kill** | Document learnings, move on. Sunk cost: 2 days + ~$5 API |
