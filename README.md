# Secure Repository Starter

A ready-to-use Git repository baseline that keeps secrets out of version control, restricts access to what's needed, protects the main branch, keeps dependencies healthy, and makes vulnerability reporting safe and easy.

Maintainer: Dhananjay Gupta

> **Never commit real credentials.** Every key, token, and password in this repository is a placeholder. Real values live in a local `.env` (ignored by Git) or a secrets manager.

## What you get

- **Secret prevention:** `.gitignore`, `.env.example`, pre-commit scanning (gitleaks), a CI secret scan, and a verification script
- **Least-privilege access:** `CODEOWNERS` and a script that applies read-only Actions tokens and branch rules
- **Branch protection:** pull requests, reviews, required checks, no force pushes
- **Dependency hygiene:** Dependabot config and guidance
- **Disclosure:** `SECURITY.md` and an issue template that routes reports privately
- **Docs:** full guide, checklist and per-OS setup instructions in [`docs/`](docs/)

## Quick start

1. Follow the setup guide for your system:
   - Linux: [`docs/SETUP_LINUX.md`](docs/SETUP_LINUX.md)
   - Windows (Git Bash): [`docs/SETUP_WINDOWS.md`](docs/SETUP_WINDOWS.md)
2. Personalize with your GitHub details:
   ```bash
   bash scripts/personalize.sh YOUR_GITHUB_USERNAME YOUR_REPO_NAME
   ```
3. Create your local config (never committed):
   ```bash
   cp .env.example .env
   ```
4. Install the hooks:
   ```bash
   pre-commit install
   ```

## Configuration

| Variable | Secret? | Description | Placeholder |
|---|---|---|---|
| `APP_ENV` | no | runtime environment | `development` |
| `APP_PORT` | no | listen port | `8080` |
| `DATABASE_URL` | yes | database connection string | `postgres://USER:PASSWORD@localhost:5432/app_dev` |
| `EXAMPLE_API_KEY` | yes | third-party API key | `<paste-your-key-here>` |
| `JWT_SIGNING_SECRET` | yes | token signing secret | `<generate-a-random-value>` |

Edit `.env.example` so it lists the variables your project actually uses. Keep every value a placeholder.

## Repository layout

```
.github/            CODEOWNERS, Dependabot, secret-scan workflow, templates
docs/               GUIDE, CHECKLIST, VERIFY_NO_SECRETS, SETUP_LINUX, SETUP_WINDOWS
scripts/            check-secrets, canary-test, personalize, apply-github-protections, setup-git-identity
.env.example        safe configuration sample
config.example.yaml structured config sample
SECURITY.md         vulnerability disclosure policy
```

## Scripts

| Script | What it does |
|---|---|
| `scripts/setup-git-identity.sh` | Sets your global Git name, email and defaults |
| `scripts/personalize.sh USER REPO` | Fills in your GitHub username and repo name |
| `scripts/check-secrets.sh` | Checks tracked files and history for secrets |
| `scripts/canary-test.sh` | Proves your hooks block a secret-shaped string |
| `scripts/apply-github-protections.sh USER/REPO [--solo]` | Applies GitHub security settings and branch protection |

## Security

Report vulnerabilities privately; see [`SECURITY.md`](SECURITY.md). Do not open public issues for security problems.

## Sample data

All sample and test data in this repository must be synthetic: use `example.com`, `192.0.2.0/24` and clearly fake values, and never commit dumps, logs, captures or screenshots without scrubbing them.

## Contributing

1. Branch from `main` and open a pull request; direct pushes to `main` are blocked.
2. Install the hooks (`pre-commit install`) before your first commit.
3. Make sure required checks pass and use the pull request template.

## License

MIT, see [`LICENSE`](LICENSE).
