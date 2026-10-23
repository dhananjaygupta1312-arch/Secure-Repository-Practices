# Setup on Linux (Ubuntu / Debian)

On Fedora use `dnf install`, on Arch `pacman -S`. Replace `YOUR_GITHUB_USERNAME` and `YOUR_REPO_NAME` throughout.

## 1. Install tools

```bash
sudo apt update
sudo apt install -y git curl python3 pipx unzip
pipx ensurepath            # then close and reopen the terminal
pipx install pre-commit
sudo apt install -y gh     # if not found, follow the install steps at cli.github.com
```

Gitleaks (use `linux_arm64` instead of `linux_x64` if `uname -m` shows `aarch64`):
```bash
VER=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
curl -sSL "https://github.com/gitleaks/gitleaks/releases/download/v${VER}/gitleaks_${VER}_linux_x64.tar.gz" | tar -xz gitleaks
sudo mv gitleaks /usr/local/bin/
```

Check everything:
```bash
git --version && pre-commit --version && gh --version && gitleaks version
```

Turn on 2FA at GitHub (Settings, Password and authentication) and save the recovery codes offline. Then log in:
```bash
gh auth login              # GitHub.com, HTTPS, login with browser
```

## 2. Unpack and personalize

```bash
unzip secure-repo-starter.zip && cd secure-repo-starter
bash scripts/setup-git-identity.sh
bash scripts/personalize.sh YOUR_GITHUB_USERNAME YOUR_REPO_NAME
```

## 3. Initialize, install hooks, first commit

```bash
git init -b main
cp .env.example .env               # real local values go in .env only
git check-ignore -v .env           # must print a matching .gitignore rule
git add .
git status                         # .env must NOT be listed
pre-commit install
pre-commit run --all-files         # first run downloads tools; may take a minute
git commit -m "Initial commit: security baseline"
bash scripts/check-secrets.sh
bash scripts/canary-test.sh        # expect PASS
```

## 4. Publish

```bash
gh repo create YOUR_REPO_NAME --private --source=. --push
gh run list                        # wait until the secret-scan workflow has run once
```

## 5. Apply GitHub protections

```bash
bash scripts/apply-github-protections.sh YOUR_GITHUB_USERNAME/YOUR_REPO_NAME --solo
```
Use `--solo` if you are the only contributor (GitHub does not let you approve your own pull request). Leave it off if you have a second reviewer.

Then in the browser:
- Settings, Actions, General: require approval for workflows from outside contributors
- Settings, Rules, Rulesets, New tag ruleset: pattern `v*`, block deletion and updates

## 6. Verify

```bash
git checkout -b test-branch
echo "test" >> README.md
git commit -am "test change" && git push -u origin test-branch
gh pr create --fill
gh pr checks                       # secret-scan should appear
gh pr close --delete-branch
git checkout main

cd /tmp && git clone --mirror https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git verify.git
cd verify.git && gitleaks detect --source . --redact -v   # newer versions: gitleaks git --redact -v .
cd /tmp && rm -rf verify.git
```
Pushing directly to `main` should now be rejected. Then work through `docs/CHECKLIST.md`.

## 7. Ongoing

```bash
R=YOUR_GITHUB_USERNAME/YOUR_REPO_NAME
gh pr list --search "author:app/dependabot"
gh api repos/$R/dependabot/alerts --jq '.[] | select(.state=="open") | {pkg: .dependency.package.name, sev: .security_advisory.severity}'
gh api repos/$R/secret-scanning/alerts --jq '.[] | select(.state=="open") | {number, secret_type}'
gh api repos/$R/collaborators --jq '.[] | {login, role: .role_name}'
gh api repos/$R/keys --jq '.[] | {title, read_only}'
gh api repos/$R/hooks --jq '.[] | {id, url: .config.url}'
```
Weekly: review Dependabot PRs and the Security tab. Quarterly: audit collaborators, deploy keys, tokens, Apps and webhooks. Before each release: `bash scripts/check-secrets.sh`.

## If a secret leaks

Rotate or revoke it at the provider first. Then purge history:
```bash
pipx install git-filter-repo
git clone https://github.com/$R.git ~/purge && cd ~/purge
printf 'literal:THE_LEAKED_VALUE==>REMOVED\n' > ../replacements.txt
git filter-repo --replace-text ../replacements.txt
git remote add origin https://github.com/$R.git
git push --force --all && git push --force --tags
shred -u ../replacements.txt
```
Branch protection blocks force pushes, so turn that rule off briefly and back on afterwards. Ask everyone to re-clone, and re-run the mirror scan.
