#!/usr/bin/env bash
# Apply repository protections with the GitHub CLI.
# Usage: bash scripts/apply-github-protections.sh OWNER/REPO [--solo]
#   --solo : no required approvals / code-owner review (you cannot approve your own PR)
# Some calls fail on private repos if your plan does not include the feature.
set -uo pipefail
R="${1:-}"; MODE="${2:-}"
[ -n "$R" ] || { echo "Usage: bash scripts/apply-github-protections.sh OWNER/REPO [--solo]"; exit 2; }
command -v gh >/dev/null 2>&1 || { echo "GitHub CLI (gh) not installed"; exit 2; }

if [ "$MODE" = "--solo" ]; then APPROVALS=0; OWNERS=false; else APPROVALS=1; OWNERS=true; fi
BRANCH=$(gh api "repos/$R" --jq .default_branch 2>/dev/null || echo main)

report() { if [ "$1" -eq 0 ]; then echo "OK    $2"; else echo "FAIL  $2  (plan limit or permissions; see docs/GUIDE.md)"; fi; }

gh api -X PUT "repos/$R/vulnerability-alerts" >/dev/null 2>&1;            report $? "Dependabot alerts"
gh api -X PUT "repos/$R/automated-security-fixes" >/dev/null 2>&1;       report $? "Dependabot security updates"
gh api -X PUT "repos/$R/private-vulnerability-reporting" >/dev/null 2>&1; report $? "Private vulnerability reporting"

printf '%s' '{"security_and_analysis":{"secret_scanning":{"status":"enabled"},"secret_scanning_push_protection":{"status":"enabled"}}}' \
  | gh api -X PATCH "repos/$R" --input - >/dev/null 2>&1;                  report $? "Secret scanning + push protection"

gh api -X PUT "repos/$R/actions/permissions/workflow" -f default_workflow_permissions=read >/dev/null 2>&1
report $? "Actions token read-only"

cat <<JSON | gh api -X PUT "repos/$R/branches/$BRANCH/protection" --input - >/dev/null 2>&1
{
  "required_status_checks": {"strict": true, "contexts": ["gitleaks"]},
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": $APPROVALS,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": $OWNERS
  },
  "restrictions": null,
  "required_conversation_resolution": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
report $? "Branch protection on $BRANCH (approvals=$APPROVALS, code owners=$OWNERS)"

echo
echo "Still manual (browser): fork-PR workflow approval, tag ruleset for v*, 2FA."
echo "Note: the 'gitleaks' status check must have run once before it can be required."
