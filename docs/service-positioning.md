# Service Positioning: Managed Autonomous Outreach

## Context

This document captures the positioning strategy for the managed outreach service built on ZeroClaw.
It is intended as the source of truth for landing page copy, sales calls, and client onboarding.

The underlying agent in this repository is the proof-of-concept and production implementation.
The landing page lives in a separate repo (`[service-name]-web`).

---

## Buyer Profile

**Head of Sales / Founder at a 10–50 person B2B company.**

They want more pipeline but can't justify another SDR. They've tried Clay, Apollo, Instantly —
all feel like spam machines. They want quality, not volume. They are scared of three things:

1. Damaging their domain reputation with spam
2. Losing control to an AI that acts without authorization
3. Having their credentials or CRM data exposed

---

## Category

**Managed Autonomous Outreach** — not "AI email tool", not "SDR replacement", not "email automation".

- "Autonomous" signals capability (no manual writing required)
- "Managed" signals safety and retained control (someone is accountable)

---

## The Core Insight

Most outreach tools try to *remove* the human. This service keeps the human exactly where they
need to be — at the **approval gate** — and removes them from the tedious part: research and
first-draft writing.

This is not a limitation. It is the product.

---

## Recommended Tagline

> "Your AI researches. Your AI writes. You decide."

Alternatives:
- "Autonomous outreach, human-approved."
- "Research automated. Approval yours. Results real."

---

## One-Line Pitch

> "An AI agent that researches each prospect, drafts a personalized email, and sends it to your
> Slack for approval. You reply SEND, EDIT, or SKIP. Nothing goes out without you."

---

## Trust / Security Package

Address all three buyer fears as features, not disclaimers.

### 1. No spam / no domain damage
- Volume is hard-capped at 5 emails per day — not configurable, not a setting
- Every email has been read and approved by a human before sending
- Human judgment is baked into the architecture

**Proof point**: Show the Slack approval flow — the agent posts the draft and stops.
Nothing happens until the user replies.

### 2. No rogue agent / no unauthorized actions
- Agent operates in a sandboxed workspace with an explicit action allowlist
- Cannot access CRM, file system, or any external system beyond what is configured
- Max 30 actions/hour, max $5/day AI spend
- Human approval gate is structural — not a policy, not a prompt instruction

**Proof point**: Show the EDIT flow — user sends a revision instruction, agent
revises and re-posts for another approval round. The user can always course-correct
before anything sends.

### 3. No credential exposure
- Agent deployed on a dedicated server (Ari-hosted or client VPS — TBD per onboarding)
- Credentials stored in config files on that server, not relayed through any third-party middleware
- No Composio, no OAuth proxy
- Agent can only make HTTP requests to pre-approved domains (email API, lead source)

**Landing page copy**: "Your API keys stay on your server. They are never relayed through our systems."

**Note**: Finalize the hosting model (Ari-managed vs. client VPS) before going live with
this specific claim. See `docs/onboarding-client.md` for deployment options.

---

## How It Works (3 Steps)

1. **Research** — The agent visits each prospect's company website, identifies a specific hook
   (recent project, news item, tech stack, hire), and drafts an email around it.
   Not a template. Not variables. Real judgment.

2. **Draft** — You receive the draft on Slack. Subject line, 3-sentence email, research summary
   attached. Every detail is traceable to the source.

3. **You decide** — Reply SEND and it goes. Reply EDIT with your instruction and it revises
   and returns for another look. Reply SKIP and it marks the lead and moves on.
   Nothing ever sends without your explicit command.

---

## Differentiation from Clay / Apollo / Instantly

> Clay and Apollo are great for volume. This is for precision. The agent doesn't fill in
> variables — it reads the prospect's website and writes something specific. The result is a
> 3-sentence email that could only have been written for that person. You can't send 10,000 of
> those. You shouldn't. You should send 100 that get replies.

---

## Differentiation from SetupClaw (OpenClaw deployment)

| Dimension | SetupClaw | This service |
|-----------|-----------|--------------|
| Underlying runtime | OpenClaw (heavy, general) | ZeroClaw (5MB binary, sandboxed) |
| Use case | General agent (email, calendar, Slack) | Outreach-specific (focused, provable) |
| Delivery model | One-time setup, client owns after | Fully managed monthly retainer |
| Security middleware | Composio (third-party OAuth proxy) | No middleware — credentials on your server |
| Price | $3,000–$6,000 one-time | $1,500/mo (includes setup) |

---

## Pricing

**$1,500/month** — Managed Autonomous Outreach

Includes:
- Setup (first month)
- Up to 5 new drafts per business day
- Slack approval interface
- Monthly voice calibration and lead refresh
- Dedicated deployment (credentials on your server)

Optional: Teams integration for enterprise clients (+$500/mo)

**Cost basis**: ~$20–40/mo per client in AI spend. Gross margin ~97%.

---

## Landing Page Section Order

1. Hero (tagline + subhead + CTA → demo video)
2. The Problem (3 short paragraphs, no bullets)
3. How It Works (3 steps with visuals)
4. Demo / Proof Block (Slack screen recording + anonymized draft)
5. What You Get (Week 1, ongoing, monthly)
6. Security Block ("You stay in control. Every step.")
7. Why Not Clay/Apollo (1 paragraph)
8. Pricing (one tier + Teams add-on)
9. CTA / Pilot Offer (book a 30-min demo or 5-draft pilot)

---

## Pre-Launch Checklist

- [ ] Decide hosting model: Ari-managed vs. client VPS (affects security copy)
- [ ] Verify Slack SEND/EDIT/SKIP flow is fully operational in ZeroClaw
- [ ] Record demo video: Slack session with drafts, EDIT, re-post, SEND
- [ ] Create anonymized draft example (de-identify a real draft from workspace/memory/)
- [ ] Register domain for the service (see service name options below)
- [ ] Set up SPF/DKIM on sending domain before any client goes live
- [ ] Decide lead intake format for clients (CSV or shared Google Sheet)

---

## Service Name Options

The name should be ownable, 1–2 syllables, and evoke precision + craftsmanship.
Avoid "AI", "Agent", or "Outreach" in the name itself.

| Name | Rationale |
|------|-----------|
| **Flint** | Sparks a conversation; precision; strong sonic quality |
| **Pith** | "The essential part"; fits the 3-sentence ethos; unusual and memorable |
| Quill | Writing/drafting; elegant; but more common |
| Spire | Direction, ambition; decent but less distinctive |
| Glint | A flash of attention; softer brand feel |

**Recommendation**: Flint (broader brand-ability) or Pith (most conceptually tight).
