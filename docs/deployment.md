# Lead Outreach Agent — Deployment Guide

**Target**: Local Mac first, then Hetzner VPS
**Runtime**: ZeroClaw (Rust agent runtime)

---

## Prerequisites Checklist

- [x] OpenRouter API key
- [x] Resend account (verified domain with SPF/DKIM)
- [x] Telegram bot + your user ID
- [x] Google Sheet published as CSV
- [x] ZeroClaw installed locally (built from source)
- [x] `.env` file created with real values

---

## Step 1: Create Telegram Bot (~2 min)

1. Open Telegram, search for **@BotFather**
2. Send `/newbot`
3. Name: e.g. "Ari Outreach Agent"
4. Username: e.g. `ari_outreach_bot`
5. Copy the **bot token** — looks like `123456789:ABCdefGHI...`

Then get your user ID:

6. Search for **@userinfobot** in Telegram
7. Send `/start`
8. Copy the number it returns

Put both values in `config.toml` under `[channels_config.telegram]`:
```toml
[channels_config.telegram]
bot_token = "your-bot-token"
allowed_users = ["your-user-id"]
```

---

## Step 2: Create & Publish Google Sheet (~3 min)

1. Create a new Google Sheet
2. Add these **exact headers** in Row 1:

| A | B | C | D | E | F |
|---|---|---|---|---|---|
| name | company | role | email | website | notes |

3. Add 2–3 test leads. **Use your own email as the recipient** so you can verify delivery:

| name | company | role | email | website | notes |
|------|---------|------|-------|---------|-------|
| Test Lead | Acme Corp | CTO | your@email.com | https://acme.com | Test lead for validation |

4. Publish as CSV:
   - **File** → **Share** → **Publish to web**
   - Select **Entire Document** and **Comma-separated values (.csv)**
   - Click **Publish**
5. Copy the URL — this is your `GOOGLE_SHEET_CSV_URL`

Verify it works by pasting the URL in a browser — you should see raw CSV text.

---

## Step 3: Install ZeroClaw (~15 min first time)

```bash
# Install Rust (skip if you already have it)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source ~/.cargo/env

# Clone and build ZeroClaw from source
git clone https://github.com/zeroclaw-labs/zeroclaw.git /tmp/zeroclaw
cd /tmp/zeroclaw
cargo install --path . --locked

# Verify
zeroclaw --version
```

---

## Step 4: Create `.env` File

```bash
cd /Users/ari/Documents/zeroclaw-outreach
cp .env.example .env
```

Open `.env` and fill in every value. See `.env.example` for the list.

> **Note**: Telegram bot token and owner ID go in `config.toml`, NOT in `.env`.
> ZeroClaw reads `OPENROUTER_API_KEY` directly as an env var. The rest are used by skill scripts via `http_request`.

---

## Step 5: Onboard ZeroClaw

```bash
cd /Users/ari/Documents/zeroclaw-outreach
./scripts/start.sh onboard
```

`start.sh` sources your `.env` and sets `ZEROCLAW_WORKSPACE` to point ZeroClaw at this project directory.

This will:
- Validate your config.toml
- Pair with your Telegram bot
- Verify the OpenRouter API connection
- Set up the local SQLite memory database

---

## Step 5b: Set Up Daily Cron Job

After onboarding, create the daily outreach cron:

```bash
./scripts/start.sh cron add '0 9 * * *' \
  'Run daily lead outreach: ingest leads from Google Sheet, research and draft emails, send to Telegram for approval' \
  --tz Europe/Athens
```

Verify it was created:
```bash
./scripts/start.sh cron list
```

---

## Step 6: Start the Agent

**Foreground mode** (recommended for first run — shows logs):
```bash
./scripts/start.sh run
```

**Daemon mode** (background, for ongoing use):
```bash
./scripts/start.sh daemon
```

**Single message** (test that agent responds):
```bash
./scripts/start.sh agent -m "Hello!"
```

---

## Step 7: Test End-to-End

### 7a. Verify Telegram connection
```bash
./scripts/start.sh channel doctor
```

Then send `/start` to your bot in Telegram. The agent should respond.

### 7b. Trigger ingestion
Tell the agent: **"Check for new leads"**

Expected: Agent fetches your Google Sheet CSV and reports something like:
> "Ingested 2 new leads, 0 already known, 0 skipped"

### 7c. Verify research + drafting
The agent should automatically research each lead's company website and send you a draft in this format:

```
OUTREACH DRAFT #1

To: Test Lead (CTO, Acme Corp)
Subject: [personalized subject]

[Email body — under 150 words]

Research: [1-2 sentence summary]

Reply: SEND | EDIT [paste corrected email] | SKIP
```

### 7d. Test SEND
Reply **SEND** to a draft. Verify:
- Agent confirms "Sent to Test Lead at your@email.com"
- Email actually arrives in your inbox via Resend

### 7e. Test SKIP
Reply **SKIP** to another draft. Verify:
- Agent confirms "Skipped [name] at [company]"

### 7f. Test EDIT
Reply **EDIT Here is the corrected email body text** to a draft. Verify:
- Agent re-sends the updated draft for another round of approval
- Reply SEND to confirm the edited version

---

## Step 8: Deploy to VPS (when ready)

Once local testing works end-to-end:

### 8a. Provision the VPS
```bash
# Create a Hetzner CAX11 (ARM, Ubuntu 24.04, ~$3.79/mo)
# Then run the setup script:
scp scripts/setup_vps.sh root@YOUR_VPS_IP:/tmp/
ssh root@YOUR_VPS_IP 'bash /tmp/setup_vps.sh'
```

### 8b. Copy files to VPS
```bash
scp config.toml .env scripts/start.sh zeroclaw@YOUR_VPS_IP:~/outreach/
scp -r workspace zeroclaw@YOUR_VPS_IP:~/outreach/
scp -r scripts zeroclaw@YOUR_VPS_IP:~/outreach/
```

### 8c. Onboard and start
```bash
ssh zeroclaw@YOUR_VPS_IP 'cd ~/outreach && ./scripts/start.sh onboard'
ssh zeroclaw@YOUR_VPS_IP 'cd ~/outreach && ./scripts/start.sh cron add "0 9 * * *" "Run daily lead outreach" --tz Europe/Athens'
ssh root@YOUR_VPS_IP 'systemctl start zeroclaw'
```

### 8d. Verify it's running
```bash
ssh root@YOUR_VPS_IP 'systemctl status zeroclaw'
```

Send `/start` to your Telegram bot — it should now respond from the VPS.

---

## Ongoing Operations

| Task | How |
|------|-----|
| Add new leads | Add rows to Google Sheet — agent picks them up at 9 AM |
| Check status | Ask in Telegram: "Who did I contact this week?" |
| View logs | `journalctl -u zeroclaw -f` (on VPS) |
| Stop agent | `systemctl stop zeroclaw` (on VPS) or Ctrl+C (local) |
| Update skills | Edit SKILL.md files, `scp` to VPS, restart service |

## Cost Estimate

| Service | Monthly Cost |
|---------|-------------|
| Hetzner CAX11 VPS | ~$3.79 |
| OpenRouter (Claude Sonnet) | ~$30–50 |
| Resend (free tier: 3k emails/mo) | $0 |
| **Total** | **~$35–55** |

## Tips

- **Email warmup**: Start with 2–3 real emails/day for the first week to build sender reputation. The 5 leads/day cap helps with this.
- **Learning loop**: The more you use EDIT, the better drafts get. The agent stores your corrections in memory and references them before writing future emails.
- **Kill criteria**: Per the PRD, evaluate at 30 days. If draft approval rate is below 80% or you're not sending 3x more emails, consider pivoting or killing.
