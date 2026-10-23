#!/usr/bin/env bash
# Local secret hygiene check. Run from the repository root.
# Exit code is non-zero if any check fails.
set -uo pipefail

fail=0
say() { printf '\n== %s ==\n' "$1"; }

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not a git repository"; exit 2; }

say "1. Sensitive filenames tracked by git"
hits=$(git ls-files | grep -Ei '(^|/)(\.env(\..*)?|.*\.(pem|key|p12|pfx|jks|kdbx|tfstate|tfvars|dump|pcap|har))$' | grep -vi 'example' || true)
if [ -n "$hits" ]; then echo "$hits"; echo "FAIL: sensitive files are tracked"; fail=1; else echo "OK"; fi

say "2. Sensitive filenames ever present in history"
hist=$(git log --all --full-history --name-only --pretty=format: 2>/dev/null \
  | grep -Ei '(^|/)(\.env(\..*)?|.*\.(pem|key|p12|pfx|jks|kdbx|tfstate))$' | grep -vi 'example' | sort -u || true)
if [ -n "$hist" ]; then echo "$hist"; echo "FAIL: found in history"; fail=1; else echo "OK"; fi

say "3. Secret-shaped strings in history (regex)"
rx='(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|ghp_[A-Za-z0-9]{30,}|xox[baprs]-[A-Za-z0-9-]{10,})'
if git log --all -p -G"$rx" --oneline 2>/dev/null | grep -E "$rx" | grep -v 'AKIAIOSFODNN7EXAMPLE' | head -n 5 | grep -q .; then
  echo "FAIL: possible secret found in history (inspect with git log --all -p -G)"; fail=1
else echo "OK"; fi

say "4. Dedicated scanner"
if command -v gitleaks >/dev/null 2>&1; then
  if gitleaks detect --source . --log-opts="--all" --redact >/dev/null 2>&1; then echo "gitleaks: OK"
  else echo "FAIL: gitleaks reported findings (run: gitleaks detect --source . --log-opts=\"--all\" --redact -v)"; fail=1; fi
else
  echo "SKIP: gitleaks not installed (see VERIFY_NO_SECRETS.md)"
fi

say "5. .gitignore sanity"
for p in .env "*.pem" "*.key"; do
  git check-ignore -q "${p/\*/x}" 2>/dev/null && echo "ignored: $p" || { echo "WARN: $p not ignored"; }
done

echo
if [ "$fail" -eq 0 ]; then echo "RESULT: no issues found"; else echo "RESULT: issues found, rotate any exposed credentials first"; fi
exit "$fail"
