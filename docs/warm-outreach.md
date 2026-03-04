# Warm Outreach Pipeline

Discovers contacts from company websites and drafts relationship-building emails. Runs alongside the existing RapidSafeSystems cold outreach pipeline. Both share one Slack poller (`poll-slack.sh`) and the same Resend delivery.

## Quick start

```bash
# 1. Add target websites (one URL per line)
vi workspace/warm-outreach/leads/websites.txt

# 2. Set the Slack channel in .env
echo "WARM_SLACK_CHANNEL_ID=CXXXXXXXXXX" >> .env

# 3. Run manually
./scripts/run-warm-outreach.sh

# 4. Approve drafts in Slack (SEND / EDIT / SKIP)
# The poller (poll-slack.sh) handles this automatically every 2 min
```

## How it works

1. **Load websites** from `workspace/warm-outreach/leads/websites.txt`
2. **Discover contacts**: visits each site's contact/about/team pages, extracts names + emails
3. **Research**: WebSearch for company news, recent projects, industry context
4. **Draft**: warm, curiosity-driven email (2-3 sentences, no sales pitch)
5. **Post to Slack** for approval in the warm outreach channel
6. **SEND/EDIT/SKIP** flow — same as rapidsafesystems, handled by `poll-slack.sh`

## Files

| File | Purpose |
|------|---------|
| `workspace/warm-outreach/leads/websites.txt` | Input: one URL per line. Lines starting with `#` are ignored. |
| `workspace/warm-outreach/drafts/*.json` | Draft emails (pending/sent/skipped) |
| `workspace/warm-outreach/state.json` | Draft counter + processed URLs |
| `scripts/run-warm-outreach.sh` | Pipeline runner (invokes Claude) |
| `scripts/warm-outreach-prompt.md` | Claude system prompt (voice, research, drafting) |
| `scripts/com.warm-outreach.morning.plist` | Launchd: daily at 10 AM Athens |

## Scheduling (cron)

To run daily at 10 AM Athens time:

```bash
cp scripts/com.warm-outreach.morning.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.warm-outreach.morning.plist
```

The existing poller (`com.outreach.poller.plist`) already handles both pipelines — it iterates `workspace/*/drafts/` and reads the Slack channel from each draft JSON.

## Adding a new website

Just append a URL to `workspace/warm-outreach/leads/websites.txt`. Already-processed URLs are tracked in `state.json` and won't be re-run.

## Differences from rapidsafesystems pipeline

| | RapidSafeSystems | Warm Outreach |
|---|---|---|
| Lead source | CSV from Google Sheet | Website URLs |
| Contact discovery | Pre-loaded (name + email in CSV) | Agent discovers from website |
| Tone | Direct, technically credible, sales CTA | Warm, curious, no pitch |
| Email structure | 3 sentences + sign-off | 2-3 sentences + sign-off |
| Max per run | 5 | 3 |
| Slack channel | SLACK_CHANNEL_ID | WARM_SLACK_CHANNEL_ID |
| Schedule | 9 AM Athens | 10 AM Athens |
