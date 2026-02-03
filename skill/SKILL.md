---
name: star-gazer
description: "Track GitHub repositories with the most star gains. Reports top 5 repos that gained the most stars daily."
metadata:
  {
    "openclaw":
      {
        "emoji": "🌟",
        "requires": { "bins": ["curl", "python3"] },
        "install": [],
      },
  }
---

# Star Gazer Skill

Track GitHub repositories with the most star gains. Reports top 5 repos that gained the most stars daily.

## Usage

### Daily Star Gains Report

To see which repositories gained the most stars today:

```bash
# First, set your GitHub token
export GITHUB_TOKEN="your_github_token"

# Run the star tracker
clawdbot exec --command "bash /path/to/star-gazer.sh"
```

### Setup Environment

The skill requires `GITHUB_TOKEN` environment variable. Configure via Clawdbot:

```bash
clawdbot config set --key github.token --value "your_token"
```

## Configuration

- `GITHUB_TOKEN`: Personal Access Token with `repo` scope
- Data stored in `~/.clawdbot/star-tracker.json`

## Notes

- Tracks repos created in the last 14 days
- Requires network access to GitHub API
- Rate limits apply (60 requests/hour for unauthenticated, 5000 for authenticated)
