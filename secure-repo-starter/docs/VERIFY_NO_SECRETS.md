# Verifying That No Secrets Are Committed

Run these from the repository root. Use a clean clone for the most reliable result: `git clone --mirror <url>` covers all refs.

## Step 1: Check tracked file names

```bash
git ls-files | grep -Ei '(^|/)(\.env(\..*)?|.*\.(pem|key|p12|pfx|jks|kdbx|tfstate|tfvars|dump|pcap|har))$' \
  | grep -vi 'example'
```
Expected: no output. Anything listed should be removed from tracking (`git rm --cached <file>`) and added to `.gitignore`.

## Step 2: Confirm ignore rules work

```bash
git check-ignore -v .env secrets/test.key
git status --ignored --short
```
Expected: the sensitive paths are reported as ignored.

## Step 3: Scan the working tree and full history

Using **gitleaks** (check `gitleaks --help` for your version's exact subcommands):

```bash
# v8.x classic syntax: scans every commit on every branch
gitleaks detect --source . --log-opts="--all" --redact -v

# newer releases
gitleaks git --redact -v .
gitleaks dir --redact -v .
```

Using **TruffleHog** (verifies whether found secrets are still live):

```bash
trufflehog git file://. --only-verified
trufflehog filesystem . --only-verified
```

Expected: zero findings. Review every hit, including "unverified" ones, since expired-looking keys may still matter.

## Step 4: Targeted history searches

```bash
# Was a sensitive file ever committed, even if deleted later?
git log --all --full-history --oneline -- .env '*.pem' '*.key' '*.tfstate'

# Search all history for common secret shapes (pickaxe / regex)
git log --all -p -G'(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|ghp_[A-Za-z0-9]{30,}|xox[baprs]-[A-Za-z0-9-]{10,})' --oneline | head
```
Expected: no output. (These patterns are examples; extend them for the providers you use.)

## Step 5: Check staged changes before each commit

```bash
git diff --cached | grep -Ei '(password|secret|token|api[_-]?key)\s*[:=]\s*["'\'']?[A-Za-z0-9/+_-]{12,}'
pre-commit run --all-files     # if the pre-commit config is installed
```

## Step 6: Prove the scanner actually works (canary test)

A misconfigured scanner fails silently, so test it. The script generates a random, non-functional AWS-shaped key on a throwaway branch, tries to commit it, reports whether your hooks blocked it, then cleans up:

```bash
bash scripts/canary-test.sh
```
Requirements: at least one commit exists and the working tree is clean. Expected result: `PASS`. A `FAIL` means a secret-shaped string was committable, so re-run `pre-commit install` and check `.pre-commit-config.yaml`.

## Step 7: Verify server-side protection

- Repository **Settings → Code security**: secret scanning and push protection enabled
- Branch rules require the secret-scan status check
- Review **Security → Secret scanning** alerts and resolve all open ones
- Check forks, wikis, releases, and attached assets, which are not covered by a normal `git` history scan

## Step 8: If anything is found

1. **Revoke and rotate** the credential first
2. Review provider access logs for misuse
3. Purge from history:
   ```bash
   git filter-repo --replace-text replacements.txt   # replacements.txt lists the values to scrub
   git push --force --all && git push --force --tags
   ```
4. Have collaborators re-clone; invalidate old forks/caches where possible
5. Re-run Steps 3 and 4 to confirm a clean result
6. Document the incident and add a preventive control

Automate Steps 1, 3, and 4 with `scripts/check-secrets.sh`.
