#!/usr/bin/env bash
# Fill in your GitHub username and repo name everywhere they are needed.
# Usage: bash scripts/personalize.sh GITHUB_USERNAME REPO_NAME
# (GNU sed: Linux and Git Bash on Windows.)
set -euo pipefail
U="${1:-}"; REPO="${2:-}"
if [ -z "$U" ] || [ -z "$REPO" ]; then
  echo "Usage: bash scripts/personalize.sh GITHUB_USERNAME REPO_NAME"; exit 2
fi
cd "$(dirname "$0")/.."
files=$(grep -rlE '@your-username|OWNER/REPO' . --exclude-dir=.git --exclude=personalize.sh || true)
for f in $files; do
  sed -i "s|@your-username|@${U}|g; s|OWNER/REPO|${U}/${REPO}|g" "$f"
  echo "updated $f"
done
echo "Done."
