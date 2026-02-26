---
name: research-and-draft
description: Researches each new lead and drafts a personalized outreach email
---

# Research and Draft

For each lead with status "new", research their company and draft a personalized email. Max 5 leads per run.

## Research

1. Start with lead data from CSV (headline, summary, role, company, website).
2. If the lead has a website field, use browser to visit it. Look for recent projects, news, services.
3. If browser fails or no website, use web_search for "[company] [location]".
4. Record: what the company does (1 sentence), one specific detail, how it connects to Ari's services.
5. If research yields nothing usable, you may still draft from headline/summary if they are detailed. Only skip if there is truly nothing to reference. If skipping, set memory status to "skipped_no_info" and report to Slack.

NEVER fabricate research findings. If a tool fails, report the error.

## Email Structure

Every email has exactly 3 sentences plus a sign-off. No more, no less.

Subject: under 50 characters, specific to the lead's company or role.

Sentence 1: A specific observation about their company from your research. Reference a project, product, hire, or news item by name.

Sentence 2: Connect their situation to one of Ari's services. Be specific about what you could help with.

Sentence 3: A soft CTA. A question or offer of a 15-min call. Never a demand.

Sign-off: a line with just "-- Ari"

Total email body: under 150 words.

IMPORTANT: Each of the 3 elements above is ONE SENTENCE. Not a paragraph. Not multiple sentences. One sentence each, 3 sentences total.

## GOOD example (3 sentences)

Subject: WHS compliance for Acme's new Parramatta site

Your Parramatta commercial build has three subcontractors on-site, which means three different safety reporting systems to reconcile.

I'm building RapidSafeSystems, an AI-powered WHS tool that consolidates incident tracking and audit documentation across multi-sub sites.

Worth a 15-min call to see if it fits?

-- Ari

## BAD example (too many sentences, too wordy -- do NOT write like this)

Running WHS programs for Tier 2 builders in NSW gives you a clear picture of where compliance breaks down. Usually it's at the site level, between the system and the worker.

I'm building RapidSafeSystems, an AI-powered WHS compliance tool designed specifically for commercial construction. It's focused on reducing the manual overhead of incident tracking, risk documentation, and audit readiness.

Worth a 20-minute call to see if it fits what you're working on?

## Service Matching

- Construction, manufacturing, safety, logistics: RapidSafeSystems
- Data science, ML/AI, industrial analytics: SetianAI
- Product development, apps, LLM integration: Llanai
- Unclear / general tech: Fractional CTO offering

## Before Drafting

Use memory_recall with prefix "edit:" to check Ari's past corrections. Adjust voice based on patterns you find.

## After Drafting

1. memory_store key: draft:{email}, value: {to_name, to_email, to_company, to_role, subject, body, research_summary, status: "drafted", drafted_at: [now]}
2. memory_store update lead:{email} status to "drafted"
3. Proceed to send-email skill
