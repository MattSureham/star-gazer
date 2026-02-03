# 🌟 star-gazer

Track GitHub repositories with the most star gains. Simple, lightweight, and effective.

## What it does

- Fetches trending repositories (created in the last 14 days)
- Tracks daily star counts
- Calculates which repos gained the most stars each day
- Reports top 5 gainers

## As a Clawdbot Skill

star-gazer is also available as a [Clawdbot skill](https://github.com/MattSureham/clawdbot/tree/main/skills/star-gazer):

```bash
# Available in Clawdbot fork at:
# /Users/matthew/clawd/clawdbot/skills/star-gazer/
```

### Clawdbot Usage

```bash
export GITHUB_TOKEN="your_token"
clawdbot exec --command "bash /path/to/star-gazer.sh"
```

## Standalone Usage

```bash
# First run - captures baseline
./scripts/star-tracker.sh

# Tomorrow - see gains
./scripts/star-report.sh
```

## Files

- `scripts/star-tracker.sh` - Captures current star counts
- `scripts/star-report.sh` - Compares with previous day and reports gains

## Requirements

- GitHub Personal Access Token (with repo scope)
- curl, python3

## Setup

1. Export your token (or edit the script):
   ```bash
   export GITHUB_TOKEN="your_token_here"
   ```

2. Or edit `scripts/star-tracker.sh` and replace the TOKEN variable.

## Automate Daily

Add to crontab for daily reports at 9 AM:
```bash
0 9 * * * /path/to/star-gazer/scripts/star-report.sh >> ~/.clawdbot/star-report.log 2>&1
```

## License

MIT
