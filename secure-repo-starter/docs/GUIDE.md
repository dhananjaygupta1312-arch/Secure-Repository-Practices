# Git Repository Security Guide (full reference)

A practical guide to keeping a Git repository free of secrets, tightly access-controlled, and safe to share. Examples use GitHub terminology; GitLab and Bitbucket have equivalents.

> **Golden rule:** never commit real credentials. Every key, token, and password in this guide is a placeholder. Treat anything that ever touched a commit as compromised.

## Where things are in this repository

| File | Purpose |
|---|---|
| `README.md` | Project overview and quick start |
| `docs/GUIDE.md` | This guide |
| `docs/CHECKLIST.md` | Tick-box repository checklist |
| `docs/VERIFY_NO_SECRETS.md` | Steps to confirm no secrets are committed |
| `docs/SETUP_LINUX.md`, `docs/SETUP_WINDOWS.md` | Step-by-step setup per operating system |
| `.gitignore` | Starter ignore rules for secrets, keys, state files, dumps |
| `.env.example`, `config.example.yaml` | Safe configuration samples (placeholders only) |
| `SECURITY.md` | Vulnerability disclosure policy |
| `.pre-commit-config.yaml` | Local secret-scan hooks |
| `.github/` | CODEOWNERS, Dependabot, secret-scan workflow, templates |
| `scripts/` | Check, canary test, personalize and protection scripts |

---

## 1. Secret prevention

**Principle:** secrets live outside the repository. The repo contains only *names* of settings, never *values*.

1. **Keep secrets out of code.** Load them at runtime from environment variables or a secrets manager (Vault, AWS Secrets Manager, GCP Secret Manager, Azure Key Vault, 1Password CLI, Doppler, SOPS-encrypted files).
2. **Commit templates, not values.** Ship `.env.example` with placeholders; ignore the real `.env`.
3. **Ignore sensitive file types** up front (see `.gitignore`): `.env*`, `*.pem`, `*.key`, `*.p12`, `*.kdbx`, `terraform.tfstate`, `*.tfvars`, cloud credential files, SSH keys, database dumps.
4. **Block secrets before they land.** Install a pre-commit scanner (gitleaks or detect-secrets) and enable your host's server-side protection (GitHub *Secret scanning* + *Push protection*).
5. **Use short-lived credentials** where possible: OIDC federation from CI to cloud instead of stored cloud keys; expiring tokens; separate keys per environment.
6. **Scope every credential** to the minimum permission and a single purpose, so a leak has small blast radius.
7. **Never paste secrets** into issues, PR descriptions, commit messages, CI logs, screenshots, or test fixtures. Mask them in CI (`::add-mask::` on GitHub Actions).

### If a secret is committed anyway

Order matters:

1. **Revoke / rotate the credential immediately.** This is the only step that actually fixes the exposure. Deleting the commit does not.
2. Check provider logs for misuse during the exposure window.
3. Remove it from history (`git filter-repo --replace-text`, or BFG Repo-Cleaner), then force-push and ask collaborators to re-clone. Also purge forks/caches where you can, and contact host support for cached views if needed.
4. Add a scanner rule or `.gitignore` entry so it can't recur.
5. Record a short post-incident note: how it got in, how long exposed, what changed.

---

## 2. Least-privilege collaborator access

- **Prefer teams/groups over individuals**, and org-owned repos over personal ones.
- **Default role = Read.** Grant Write only to people who merge or push regularly; Maintain/Admin to the smallest possible group (aim for 2+ admins so there's no single point of failure, but not many more).
- **Require 2FA/MFA** for every member; prefer hardware keys or passkeys for admins.
- **Use SSO** for organizations when available, and remove access on offboarding the same day.
- **Review access quarterly:** members, outside collaborators, deploy keys, GitHub/OAuth Apps, webhooks, and personal access tokens.
- **Deploy keys:** read-only unless a pipeline truly must push; one key per system.
- **Tokens:** use fine-grained PATs or GitHub Apps with repo-scoped, minimal permissions and an expiry. Avoid classic tokens with broad `repo` scope.
- **CI permissions:** set `permissions: contents: read` at the top of workflows and elevate per job only when needed. Restrict who can approve workflow runs from forks.
- **Separate duties:** the person who writes a change shouldn't be the only one who can approve and deploy it.

---

## 3. Branch protection

Apply to `main` (and release branches) using branch protection rules or Rulesets:

- Require a **pull request** before merging (no direct pushes).
- Require **at least 1 approval** (2 for sensitive repos); **dismiss stale approvals** on new commits.
- Require **review from code owners** via a `CODEOWNERS` file covering security-sensitive paths (`/.github/`, auth code, infra, dependency manifests).
- Require **status checks to pass** (tests, lint, secret scan, dependency audit, SAST) and branches to be up to date.
- Require **conversation resolution** before merge.
- Require **signed commits** (GPG, SSH, or Sigstore/gitsign) where your threat model warrants it.
- Require **linear history** if you want clean, auditable history.
- **Block force pushes and branch deletion.**
- **Apply rules to administrators** too ("do not allow bypass"), or keep the bypass list tiny and audited.
- Protect **tags** (`v*`) so releases can't be rewritten.

Example `CODEOWNERS`:

```
# Security-sensitive paths need review from the security team
/.github/            @your-org/security-team
/infra/              @your-org/platform-team
/package.json        @your-org/maintainers
/package-lock.json   @your-org/maintainers
```

---

## 4. Dependency hygiene

- **Commit lockfiles** (`package-lock.json`, `poetry.lock`, `Cargo.lock`, `go.sum`, etc.) for reproducible builds.
- **Automate updates:** enable Dependabot (or Renovate) for security *and* version updates; group low-risk updates to reduce noise.
- **Audit in CI** and fail on high/critical findings: `npm audit --omit=dev`, `pip-audit`, `cargo audit`, `govulncheck`, or the language-agnostic `osv-scanner`.
- **Vet new dependencies** before adding: maintenance activity, maintainers, download history, license, and whether the standard library already does the job. Watch for typosquats and recently transferred packages.
- **Pin build tooling:** pin GitHub Actions to full commit SHAs (not mutable tags); pin base images by digest.
- **Install safely:** use `npm ci` / `pip install --require-hashes` in CI; consider disabling install scripts (`--ignore-scripts`) where you can.
- **Use a private registry/proxy** with allow-listing for larger teams.
- **Generate an SBOM** (CycloneDX or SPDX via `syft`) for releases.
- **Remove unused dependencies** regularly; fewer packages means a smaller attack surface.
- Enable the host's **dependency graph and advisories** alerts so you're notified when a used package gets a CVE.

Minimal `dependabot.yml`:

```yaml
version: 2
updates:
  - package-ecosystem: "npm"        # change per ecosystem
    directory: "/"
    schedule:
      interval: "weekly"
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

---

## 5. Issue disclosure (vulnerability reporting)

- Publish a **`SECURITY.md`** (template included) at the repo root or `.github/`.
- Enable **private vulnerability reporting** (GitHub Security Advisories) so reporters never need to file a public issue.
- State **supported versions**, a **contact channel**, an expected **response timeline**, and your **disclosure policy** (coordinated disclosure, typically 90 days).
- Add a **public issue template** warning: "Do not post vulnerabilities, credentials, or personal data here."
- **If someone posts a secret or exploit in a public issue:** hide/delete the content, rotate anything exposed, and move the conversation to a private channel.
- Triage fast, acknowledge reports, fix privately in a temporary private fork/advisory branch, publish a CVE/advisory with credit (if the reporter wants it), then release.
- Consider a safe-harbor statement so good-faith researchers know they won't face legal action.

---

## 6. README quality

A good README is also a security control: it prevents misconfiguration. Include:

1. **What it is** and who it's for, in two sentences.
2. **Quick start** that works from a clean clone, using `.env.example`.
3. **Configuration table:** every variable, what it does, whether it's secret, and a placeholder value.
4. **Security section:** link to `SECURITY.md`, state "never commit `.env`", and describe where real secrets come from (vault, CI secrets).
5. **Supported versions and requirements.**
6. **Contributing guidelines:** branch/PR flow, required checks, signed commits if enforced.
7. **Sample data policy:** state that all sample data is synthetic.
8. **License** and a **badge row** (build, scanner status) if useful.
9. **No real hostnames, internal URLs, IPs, emails, or account IDs** in examples. Use `example.com`, `192.0.2.x`, and obviously fake values.

Skeleton:

```markdown
# Project Name
One-line description.

## Quick start
cp .env.example .env      # then fill in values locally; never commit .env
make run

## Configuration
| Variable | Secret? | Description | Example |
|---|---|---|---|
| APP_ENV | no | runtime environment | development |
| DATABASE_URL | yes | DB connection string | postgres://USER:PASSWORD@localhost:5432/app |

## Security
Report vulnerabilities via SECURITY.md. Never commit credentials.

## Contributing / License
```

---

## 7. Safe handling of sample data

- **Use synthetic data only.** Generate it (Faker, factory libraries, seed scripts) instead of copying production, even "just a few rows".
- **Use reserved, non-routable values:** emails `user@example.com`; domains `example.com/.org/.test`; IPs from `192.0.2.0/24`, `198.51.100.0/24`, `203.0.113.0/24`; documentation-only phone numbers; obviously fake names.
- **Never commit** database dumps, packet captures, log files, HAR files, or screenshots without scrubbing. They routinely contain tokens, cookies, session IDs, internal hostnames, and PII.
- **Strip metadata** from files and images (EXIF, document author fields, embedded paths): `exiftool -all= file`.
- **Anonymize if you must derive from real data:** irreversible masking or tokenization, not reversible hashing of low-entropy values (emails, phone numbers, IDs are easy to brute-force).
- **For security-testing and pentest repos:** keep client names, targets, scope details, findings, and captured credentials out of the repository. Use lab targets and placeholder values in write-ups, and store engagement evidence in an access-controlled, encrypted location.
- **Mark fixtures clearly** (e.g. `tests/fixtures/synthetic/`) and add a README line stating they're fake.
- **Watch size and licensing:** don't commit large binaries; use Git LFS or a download script, and make sure public datasets allow redistribution.
- **Scan fixtures too.** Don't exclude test directories from secret scanning; fake keys that look real cause false alarms, so use clearly-fake values or add targeted allow-list entries.

---

## 8. Verifying no secrets are committed

See **`docs/VERIFY_NO_SECRETS.md`** for the full procedure and **`scripts/check-secrets.sh`** to automate it. In short: check tracked filenames, scan the working tree, scan full history across all branches and tags, scan staged changes before commit, then confirm server-side protection is on.

---

## Quick reference: recommended baseline

1. `.gitignore` + `.env.example` in place before the first commit
2. Pre-commit secret scan + server-side push protection
3. Protected `main`, PR + review + passing checks, no force pushes
4. 2FA for all, least-privilege roles, quarterly access review
5. Lockfiles + automated dependency updates + CI audit
6. `SECURITY.md` + private vulnerability reporting
7. Synthetic sample data only
8. Documented rotation procedure for any leaked credential
