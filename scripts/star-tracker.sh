#!/bin/bash
# Track GitHub repo star gains daily
# Usage: GITHUB_TOKEN=xxx ./star-tracker.sh

TOKEN="${GITHUB_TOKEN}"
DATA_FILE="${GITHUB_STAR_DATA_FILE:-$HOME/.clawdbot/star-tracker.json}"
TODAY=$(date +%Y-%m-%d)

if [ -z "$TOKEN" ]; then
    echo "Error: GITHUB_TOKEN not set. Export it or set GITHUB_TOKEN environment variable."
    exit 1
fi

# Calculate 14 days ago using Python (macOS compatible)
START_DATE=$(python3 -c "from datetime import datetime, timedelta; print((datetime.now() - timedelta(days=14)).strftime('%Y-%m-%d'))")

# Fetch trending repos (new repos this week, sorted by stars)
REPOS=$(curl -s -H "Authorization: token $TOKEN" \
  "https://api.github.com/search/repositories?q=created:>$START_DATE&sort=stars&per_page=20" 2>/dev/null)

# Get current star counts and append to data file
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

# If old data exists, calculate gains
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

if gains:
    print(f"📈 Top 5 Star Gains - {new_data['date']}")
    print("")
    for repo, gain, total in gains[:5]:
        print(f"+{gain} ⭐ {repo} (total: {total})")
else:
    print("No significant star gains today.")
PYEOF
fi

# Update data file
mv "$DATA_FILE.new" "$DATA_FILE"
