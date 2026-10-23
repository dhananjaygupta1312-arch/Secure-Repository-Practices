# Setup on Windows

Use **Git Bash** for everything except step 1, which uses PowerShell. Replace `YOUR_GITHUB_USERNAME` and `YOUR_REPO_NAME` throughout.

## 1. Install tools (PowerShell)

```powershell
winget install -e --id Git.Git
winget install -e --id Python.Python.3.12
winget install -e --id GitHub.cli
winget install -e --id Gitleaks.Gitleaks
```
If winget cannot find gitleaks, download `gitleaks_*_windows_x64.zip` from github.com/gitleaks/gitleaks/releases, put `gitleaks.exe` in a folder such as `C:\Tools`, and add that folder to PATH (Start, "Edit the system environment variables", Environment Variables, Path, New).

Close every terminal, then open **Git Bash** and check:
```bash
git --version && gh --version && gitleaks version
python --version      # if this fails, use: py --version
```

Install pre-commit:
```bash
py -m pip install --user pipx
py -m pipx ensurepath
```
Close and reopen Git Bash, then:
```bash
pipx install pre-commit
pre-commit --version
```

Turn on 2FA at GitHub (Settings, Password and authentication) and save the recovery codes offline. Then log in:
```bash
gh auth login         # GitHub.com, HTTPS, login with a web browser
```

## 2. Unpack and personalize

Unzip `secure-repo-starter.zip` (right-click, Extract All), then in Git Bash go into the folder, for example:
```bash
cd ~/Downloads/secure-repo-starter
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
If the gitleaks hook fails to build on Windows, tell me the error and I'll give you a local-hook version that uses your installed `gitleaks.exe`.

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

cd ~ && git clone --mirror https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git verify.git
cd verify.git && gitleaks detect --source . --redact -v   # newer versions: gitleaks git --redact -v .
cd ~ && rm -rf verify.git
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
rm ../replacements.txt
```
Branch protection blocks force pushes, so turn that rule off briefly and back on afterwards. Ask everyone to re-clone, and re-run the mirror scan.
