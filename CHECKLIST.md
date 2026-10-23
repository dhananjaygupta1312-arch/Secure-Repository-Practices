# Repository Security Checklist

Copy into an issue or run through it when creating or auditing a repo. Mark each item `[x]` when done.

## Secret prevention
- [ ] `.gitignore` exists before the first commit and covers `.env*`, keys, certs, state files, dumps
- [ ] `.env.example` committed with placeholders only; real `.env` is ignored
- [ ] No credentials in code, config, tests, docs, notebooks, or CI files
- [ ] Pre-commit secret scan installed (gitleaks / detect-secrets)
- [ ] Host secret scanning and **push protection** enabled
- [ ] Secret scan runs in CI on every PR
- [ ] Secrets stored in a manager or CI secret store, not in the repo
- [ ] Credentials are scoped, per-environment, and rotated on a schedule
- [ ] Leak response runbook exists (revoke, rotate, purge, review logs)
- [ ] Full-history scan done (all branches and tags) with no findings

## Access control
- [ ] 2FA/MFA required for all members; SSO if available
- [ ] Default repo permission is Read
- [ ] Access granted via teams, not individuals
- [ ] Admin role limited to a small, named group
- [ ] Outside collaborators reviewed; stale accounts removed
- [ ] Deploy keys are read-only unless write is required; one per system
- [ ] Tokens are fine-grained, scoped, and expiring
- [ ] Installed Apps, OAuth apps, and webhooks reviewed
- [ ] CI `GITHUB_TOKEN` defaults to read-only permissions
- [ ] Access review calendared (quarterly)

## Branch protection
- [ ] PR required for `main` and release branches
- [ ] 1+ approvals required; stale approvals dismissed
- [ ] `CODEOWNERS` covers sensitive paths and code-owner review is required
- [ ] Required status checks (tests, lint, secret scan, dependency audit)
- [ ] Conversation resolution required
- [ ] Force pushes and branch deletion blocked
- [ ] Rules apply to admins (or bypass list is minimal and audited)
- [ ] Release tags protected
- [ ] Signed commits required (if your threat model needs it)

## Dependency hygiene
- [ ] Lockfiles committed
- [ ] Dependabot/Renovate enabled (including GitHub Actions)
- [ ] Dependency audit in CI, failing on high/critical
- [ ] New dependencies reviewed before adding
- [ ] Actions pinned to commit SHAs; base images pinned by digest
- [ ] Unused dependencies removed
- [ ] SBOM generated for releases

## Issue disclosure
- [ ] `SECURITY.md` published with contact, timelines, supported versions
- [ ] Private vulnerability reporting enabled
- [ ] Issue templates warn against posting secrets/vulnerabilities
- [ ] Triage owner named; response SLA stated
- [ ] Process exists for handling a secret posted in a public issue

## README quality
- [ ] Purpose, quick start, and configuration table present
- [ ] Quick start works from a clean clone using `.env.example`
- [ ] Security section links to `SECURITY.md`
- [ ] Contribution rules and required checks documented
- [ ] License included
- [ ] No real hostnames, internal URLs, IPs, emails, or account IDs

## Sample data
- [ ] All sample/test data is synthetic
- [ ] Reserved values used (`example.com`, `192.0.2.0/24`, etc.)
- [ ] No DB dumps, logs, pcaps, HARs, or unscrubbed screenshots
- [ ] File metadata (EXIF/author/paths) stripped
- [ ] Fixtures directory documented as synthetic
- [ ] Large/binary data handled via LFS or download script
