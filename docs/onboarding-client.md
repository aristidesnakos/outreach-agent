# Client Onboarding Runbook

## Overview

This document covers setting up a new client's autonomous outreach agent.
Each client gets a dedicated ZeroClaw instance with isolated credentials.

Status: **Draft** — to be completed once hosting model is finalized.

---

## Hosting Model Decision (Required Before Client 1)

Two options:

### Option A: Ari-Managed VPS (Simpler)
- Ari provisions a Hetzner CAX11 (~$5/mo) per client
- Client provides their Resend API key and email identity
- Ari holds and manages credentials on client's behalf
- Pro: Faster onboarding, no client technical knowledge needed
- Con: Ari is custodian of client API keys — requires trust and clear ToS

### Option B: Client-Owned VPS (Cleaner Security Story)
- Client provisions their own VPS (Ari provides setup script)
- Credentials never leave client's infrastructure
- Pro: Strongest security claim — "your keys never leave your server"
- Con: Requires client to have (or provision) a VPS; more setup friction

**Recommendation**: Start with Option A for first 2–3 clients to validate the product,
then migrate to Option B once the setup script is polished.

---

## Onboarding Steps (Option A: Ari-Managed)

### Step 1 — Discovery Call (30 min)
Gather:
- [ ] Client email sending domain (must have SPF/DKIM configured)
- [ ] Resend API key (or offer to set up Resend account)
- [ ] Lead source: CSV or Google Sheet URL
- [ ] Client's service description (what they sell, to whom)
- [ ] 2–3 example emails they've sent previously (for voice calibration)
- [ ] Slack workspace invite (will install the approval bot)

### Step 2 — Infrastructure Setup
- [ ] Provision Hetzner CAX11 (Ubuntu 24.04 ARM)
- [ ] Run `scripts/setup_vps.sh` on new server
- [ ] Configure `config.toml` with client's model preferences
- [ ] Set `config.toml` Slack channel credentials
- [ ] Populate `.env` with client's Resend key and email identity
- [ ] Set `workspace/operational-config.md` with client values
- [ ] Load client's IDENTITY/SOUL equivalent (their voice, services, vertical)

### Step 3 — Voice Calibration (3 test drafts)
- [ ] Load 5 sample leads from client's list
- [ ] Run `research-and-draft` skill manually
- [ ] Send 3 drafts to client via Slack
- [ ] Ask client to EDIT at least 2 to calibrate voice
- [ ] Review edit corrections — adjust IDENTITY.md if needed
- [ ] Run 2 more test drafts to confirm voice is correct

### Step 4 — Go-Live
- [ ] Enable cron schedule (9 AM client's timezone)
- [ ] Load full lead batch
- [ ] Confirm Slack approval flow works end-to-end (SEND one test email to a safe address)
- [ ] Brief client on the SEND/EDIT/SKIP commands
- [ ] Set up monthly check-in calendar invite

### Step 5 — Monthly Maintenance
- [ ] Load new lead batch
- [ ] Review edit corrections from prior month — update IDENTITY.md voice notes
- [ ] Send pipeline report (leads contacted, replies if tracked, upcoming queue)
- [ ] Collect client feedback on draft quality

---

## Lead Intake Format

Clients provide leads as a CSV with the following columns:

```
Name, Company, Role, Email, Website, Location, LinkedIn, Headline, Summary
```

- `Website` is required for research
- `Email` is required for sending
- `Summary` is optional (agent will research from website if blank)

Template: `workspace/memory/lead-template.csv` (to be created)

---

## Per-Client File Structure (on VPS)

```
~/.zeroclaw/
  config.toml              ← Runtime config (provider, model, channels)
  .env                     ← Secrets (Resend key, Slack tokens)
  workspace/
    IDENTITY.md            ← Client's persona and voice
    SOUL.md                ← Client's service descriptions
    operational-config.md  ← Email identity (FROM_EMAIL, FROM_NAME)
    email-template.md      ← Email format rules (3 sentences, sign-off)
    skills/                ← Same skills as this repo
    memory/
      lead-details.txt     ← Client's lead list
      lead-index.txt       ← Quick reference (name|company|role|email)
```
