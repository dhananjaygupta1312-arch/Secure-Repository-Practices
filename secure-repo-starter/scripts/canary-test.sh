#!/usr/bin/env bash
# Checks that your secret-scanning hook really blocks a secret-shaped string.
# Creates a throwaway branch, tries to commit a random fake AWS-style key,
# reports PASS (blocked) or FAIL (committed), then cleans up.
set -uo pipefail

git rev-parse HEAD >/dev/null 2>&1 || { echo "Make at least one commit first."; exit 2; }
if [ -n "$(git status --porcelain)" ]; then
  echo "Working tree not clean. Commit or stash your changes first."; exit 2
fi

start=$(git rev-parse --abbrev-ref HEAD)
br="scanner-canary-$$"
git checkout -q -b "$br" || exit 2

key="AKIA$(LC_ALL=C tr -dc 'A-Z2-7' </dev/urandom | head -c 16)"
sec="$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 40)"
printf 'aws_access_key_id = %s\naws_secret_access_key = %s\n' "$key" "$sec" > canary.txt
git add canary.txt

if git commit -q -m "canary" >/dev/null 2>&1; then
  result=1; msg="FAIL: the canary was committed, so your scanner did not block it. Run: pre-commit install"
else
  result=0; msg="PASS: the commit was blocked."
fi

git reset --hard -q
git checkout -q "$start"
git branch -D "$br" >/dev/null 2>&1
echo "$msg"
exit $result
