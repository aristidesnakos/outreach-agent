# Demo Script: Slack Approval Flow

## Purpose

This script guides the recording of the demo video for the landing page.
The video is the single most important proof asset — it shows the full SEND/EDIT/SKIP
flow in a real Slack session.

Target length: **90–120 seconds**.

---

## Setup Before Recording

- [ ] Load 3 real (de-identified) leads into the agent
- [ ] Confirm agent is connected to Slack
- [ ] Use a clean Slack channel (#outreach-demo or similar)
- [ ] Close all unrelated Slack notifications
- [ ] Use a screen recorder that captures Slack + optionally terminal (Loom, OBS, or macOS screen record)
- [ ] Run the agent once beforehand (dry run) to confirm everything works

---

## Script (What to Show, In Order)

### Scene 1: Morning run (0:00–0:20)
- Terminal or Slack showing the agent starting its daily run
- Or: just the Slack channel showing 3 draft messages arriving from the bot
- Voiceover / caption: "Each morning, the agent researches up to 5 prospects and posts drafts to Slack."

### Scene 2: First draft — SKIP (0:20–0:40)
- Show one draft: subject line, 3-sentence body, "Research:" summary below
- User types `SKIP`
- Bot replies: "Marked as skipped. Moving to next."
- Caption: "Not the right fit? Skip it. The agent moves on."

### Scene 3: Second draft — EDIT (0:40–1:10)
- Show another draft
- User types `EDIT mention the acquisition they just made`
- Bot revises the email with the requested change and re-posts
- Caption: "Want to tweak it? Give one instruction. It revises and waits for another look."

### Scene 4: Revised draft — SEND (1:10–1:30)
- User reviews the revised draft
- User types `SEND`
- Bot replies: "Sent to [FirstName] at [Company]. Moving to next."
- Caption: "Nothing goes out without you. When you say SEND, it sends."

### Scene 5: End card (1:30–2:00)
- Static or text overlay: service name + tagline + "Book a demo" CTA URL

---

## Anonymization Checklist

Before recording, replace or blur:
- [ ] Prospect real name → "[FirstName]"
- [ ] Prospect email → "[firstname@company.com]"
- [ ] Company name → "[CompanyName]" (or use a fictional but plausible company name)
- [ ] Your Slack display name / avatar can stay visible — it humanizes the flow

---

## After Recording

- Export as MP4, max 10MB (compress if needed)
- Place in `public/demo.mp4` in the landing page repo
- Create a thumbnail screenshot for the landing page preview
- Optional: also create a GIF of just the EDIT → SEND sequence for the "How it works" section
