#!/bin/bash
# Star Gazer - Track GitHub repos with most star gains
# Usage: GITHUB_TOKEN=xxx ./star-gazer.sh [days_ago] [--dry-run]

set -e

TOKEN="${GITHUB_TOKEN}"
DATA_FILE="${GITHUB_STAR_DATA_FILE:-$HOME/.clawdbot/star-tracker.json}"
DAYS="${1:-14}"
TODAY=$(date +%Y-%m-%d)
DRY_RUN=false

# Check for --dry-run flag
for arg in "$@"; do
  if [ "$arg" = "--dry-run" ] || [ "$arg" = "-n" ]; then
    DRY_RUN=true
  fi
done

if [ -z "$TOKEN" ] && [ "$DRY_RUN" = false ]; then
    echo "Error: GITHUB_TOKEN not set"
    echo "Usage: GITHUB_TOKEN=xxx ./star-gazer.sh [--dry-run]"
    exit 1
fi

# Calculate date range
START_DATE=$(python3 -c "from datetime import datetime, timedelta; print((datetime.now() - timedelta(days=$DAYS)).strftime('%Y-%m-%d'))")

echo "📡 Fetching trending repos (created: >$START_DATE)..."

if [ "$DRY_RUN" = true ]; then
    echo "�Dry-run mode: Skipping API calls"
    echo ""
    echo "To run for real:"
    echo "  1. Set GITHUB_TOKEN environment variable"
    echo "  2. Run without --dry-run flag"
    exit 0
fi

# Fetch trending repos
REPOS=$(curl -s -H "Authorization: token $TOKEN" \
  "https://api.github.com/search/repositories?q=created:>$START_DATE&sort=stars&per_page=20" 2>/dev/null)

# Build today's data
echo "{\"date\": \"$TODAY\", \"repos\": [" > "$DATA_FILE.new"
first=true
echo "$REPOS" | grep '"full_name"' | head -10 | while read -r line; do
  REPO=$(echo "$line" | sed 's/.*"full_name": *"\([^"]*\)".*/\1/')
  STARS=$(curl -s -H "Authorization: token $TOKEN" \
    "https://api.github.com/repos/$REPO" 2>/dev/null | grep '"stargazers_count"' | head -1 | sed 's/.*: *\([0-9]*\).*/\1/')
  if [ "$first" = true ]; then
    first=false
  else
    echo "," >> "$DATA_FILE.new"
  fi
  printf "  {\"repo\": \"%s\", \"stars\": %s}" "$REPO" "$STARS" >> "$DATA_FILE.new"
done
echo "]}" >> "$DATA_FILE.new"

# Compare with previous day
if [ -f "$DATA_FILE" ]; then
  python3 << PYEOF
import json
import sys

with open("$DATA_FILE") as f:
    old_data = json.load(f)
with open("$DATA_FILE.new") as f:
    new_data = json.load(f)

old_repos = {r["repo"]: r["stars"] for r in old_data.get("repos", [])}
gains = []

for r in new_data.get("repos", []):
    old_stars = old_repos.get(r["repo"], 0)
    gain = r["stars"] - old_stars
    if gain > 0:
        gains.append((r["repo"], gain, r["stars"]))

gains.sort(key=lambda x: x[1], reverse=True)

print(f"\n📈 Top 5 Star Gains - {new_data['date']}")
print("-" * 50)

for repo, gain, total in gains[:5]:
    print(f"+{gain:>4} ⭐ {repo} (total: {total})")

if not gains:
    print("No significant star gains today.")

# Update stored data
import shutil
shutil.copy("$DATA_FILE.new", "$DATA_FILE")
PYEOF
else
  echo "📸 Baseline captured! Run again tomorrow to see gains."
  mv "$DATA_FILE.new" "$DATA_FILE"
fi

# Cleanup
rm -f "$DATA_FILE.new"
