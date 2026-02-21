
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

This is a **ZeroClaw agent workspace** — not a traditional software project. There is no source code to build or test. The repository contains configuration, skill definitions, and deployment docs for a ZeroClaw-powered lead outreach agent that researches prospects and drafts personalized cold emails.

**Runtime:** ZeroClaw is a Rust-based AI assistant platform installed separately (`cargo install zeroclaw` or `brew install zeroclaw`). This workspace configures an instance of it.

## Common Commands

```bash
# Run locally (foreground, shows logs)
zeroclaw run

# Run as daemon (background)
zeroclaw daemon

# Validate config and set up connections
zeroclaw onboard

# Deploy to VPS
ssh root@VPS_IP 'bash -s' < scripts/setup_vps.sh
scp config.toml .env zeroclaw@VPS_IP:~/.zeroclaw/
scp -r workspace zeroclaw@VPS_IP:~/.zeroclaw/
ssh zeroclaw@VPS_IP 'zeroclaw onboard'
ssh root@VPS_IP 'systemctl start zeroclaw'
```

## Architecture

### Agent Pipeline (3 skills, executed sequentially)

1. **ingest-leads** (`workspace/skills/ingest-leads/SKILL.md`) — Fetches CSV from published Google Sheet, deduplicates against SQLite memory, stores new leads keyed as `lead:{email}`.

2. **research-and-draft** (`workspace/skills/research-and-draft/SKILL.md`) — For each new lead (max 5/run): visits company website via ZeroClaw browser tools, identifies pain points, drafts a personalized email. Checks `edit:*` memory entries to learn from past corrections. Stores drafts as `draft:{email}`.

3. **send-email** (`workspace/skills/send-email/SKILL.md`) — Presents each draft to Ari via Telegram. Waits for SEND/EDIT/SKIP reply. On SEND, delivers via Resend API with compliance footer. On EDIT, stores the correction in memory (`edit:{timestamp}`) for future voice calibration.

### Key Files

| File | Purpose |
|------|---------|
| `config.toml` | ZeroClaw runtime config: provider, model, channels, cron, autonomy limits |
| `.env` | Secrets: API keys, Telegram tokens, Google Sheet URL, email identity |
| `workspace/IDENTITY.md` | Agent persona, voice rules, service matching logic, constraints |
| `workspace/skills/*/SKILL.md` | Skill definitions (ZeroClaw's equivalent of code — Markdown-defined behavior) |
| `scripts/setup_vps.sh` | Hetzner CAX11 provisioning (Ubuntu 24.04 ARM, systemd service) |
| `docs/prd.md` | Product requirements and success criteria |
| `docs/deployment.md` | Step-by-step deployment guide |

### External Services

| Service | Purpose | Config Location |
|---------|---------|----------------|
| OpenRouter (Claude Sonnet) | LLM provider | `OPENROUTER_API_KEY` in `.env` |
| Telegram Bot | Human-in-the-loop approval channel | `TELEGRAM_BOT_TOKEN` / `TELEGRAM_OWNER_ID` in `.env` |
| Google Sheets (published CSV) | Lead data source | `GOOGLE_SHEET_CSV_URL` in `.env` |
| Resend | Email delivery (SPF/DKIM required) | `RESEND_API_KEY` in `.env` |

### Memory Schema (SQLite)

- `lead:{email}` — Lead record with status lifecycle: `new` → `drafted` → `sent` / `skipped` / `skipped_no_info`
- `draft:{email}` — Draft content, subject, research summary, Resend ID after sending
- `edit:{timestamp}` — Original vs. corrected email pairs (learning loop)

## Important Conventions

- Skills are **Markdown files**, not code. ZeroClaw interprets them as behavioral instructions. Edit SKILL.md files to change agent behavior.
- The agent **never sends email without explicit Telegram approval** (SEND/EDIT/SKIP flow).
- Cron runs daily at 9:00 AM Athens time (`Europe/Athens`). Change in `config.toml` under `[cron]`.
- Autonomy is capped: max 30 actions/hour, $5/day, only `curl` allowed as shell command.
- Email voice: direct, technically credible, under 150 words, no sales jargon. See `workspace/IDENTITY.md` for full rules.
