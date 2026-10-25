# Technical Report: Git Repository Security Guide and Secure Repository Starter

| | |
|---|---|
| **Author** | Dhananjay Gupta |
| **Intern ID** | 2425 |
| **Organisation / programme** | RedKross research team, cybersecurity internship |
| **Date** | 25 October 2026 |
| **Repository** | https://github.com/dhananjaygupta1312-arch/Secure-Repository-Practices |
| **Explanatory video** | https://drive.google.com/file/d/1oH-TL3WVsl1W3kiZWXJXlVZqBoMVxcI6/view?usp=drive_link |

## 1. Executive summary

This project produced a practical security guide and a ready-to-use repository starter that address seven areas of Git repository security: secret prevention, least-privilege collaborator access, branch protection, dependency hygiene, issue disclosure, README quality and safe handling of sample data. The deliverables are a 2 to 3 page guide, a README, a checklist, an example `.gitignore`, safe configuration samples, a vulnerability-disclosure policy, CI and Dependabot configuration, helper scripts, and a step-by-step procedure for verifying that no secrets are committed. This report explains the research, design decisions, work performed, what was tested, and what was not.

## 2. Objective

Prepare a Git repository security guide covering the seven areas above, and submit a README, a repository checklist, an example `.gitignore`, a safe configuration sample and steps for checking that no secrets are committed, without ever committing real credentials.

## 3. Background research

**Why repositories leak.** Git stores full history, so a secret committed once persists in every clone and fork even after deletion. Hosting platforms therefore treat secret detection as both a detective control (scanning existing content) and a preventive one (blocking pushes) [1]. Secrets-management guidance recommends keeping credentials out of source code, centralising and rotating them, and limiting their scope [6].

**Access and change control.** Branch protection lets a repository require pull requests, approvals and passing status checks, and block force pushes and deletion [2]. Code-owner files route reviews of sensitive paths to designated people [3].

**Supply chain.** Using vulnerable or outdated components is a recognised risk category [7]. Automated dependency updates and audits reduce exposure [4].

**Process guidance.** NIST's Secure Software Development Framework describes practices for protecting code and managing vulnerabilities across the lifecycle [8]; the guide's controls map onto those themes (protect the codebase, verify, respond to vulnerabilities).

**Disclosure.** A security policy and a private reporting channel give researchers a safe way to report issues [5].

**Sample data.** Reserved domain names (RFC 2606) and documentation IP ranges (RFC 5737) cannot point at real systems, which makes them suitable for examples [12, 13].

## 4. Methodology

1. Researched official documentation and recognised guidance (section 14).
2. Defined the seven control areas and, for each, a small set of concrete controls.
3. Implemented each control as a file or script in a starter repository so it can be reused.
4. Wrote the guide, checklist and verification procedure.
5. Tested the helper scripts and recorded what was and was not tested (section 10).
6. Documented limitations and recommendations.

The approach was defence in depth: several independent layers, because any single control can fail or be bypassed.

## 5. Tools and technologies

Git; GitHub (branch protection, secret scanning, push protection, Dependabot, private vulnerability reporting, Actions); GitHub CLI (`gh`); gitleaks [9]; pre-commit [10]; git-filter-repo [11]; Bash; YAML and Markdown. An AI assistant (Claude) was used to help draft documentation and scripts; all content was reviewed by the author.

## 6. Work performed (deliverables)

| Deliverable | File | Purpose |
|---|---|---|
| README | `README.md` | Objective, quick start, configuration table, layout, scripts, video link |
| 2-3 page guide | `docs/SECURITY_GUIDE.md` | Concise guide with references |
| Full reference guide | `docs/GUIDE.md` | Extended guidance on all seven areas |
| Repository checklist | `docs/CHECKLIST.md` | Tick-box audit list |
| Example ignore rules | `.gitignore` | Blocks secrets, keys, state files, dumps |
| Safe configuration samples | `.env.example`, `config.example.yaml` | Placeholders and `${ENV}` references only |
| Verification steps | `docs/VERIFY_NO_SECRETS.md` | How to confirm nothing is committed |
| Disclosure policy | `SECURITY.md` | Reporting channel, timelines, safe harbor |
| Pre-commit config | `.pre-commit-config.yaml` | gitleaks and private-key detection |
| CI and automation | `.github/` | Secret-scan workflow, Dependabot, CODEOWNERS, templates |
| Scripts | `scripts/` | Check, canary test, personalise, apply protections, identity setup |
| Setup guides | `docs/SETUP_LINUX.md`, `docs/SETUP_WINDOWS.md` | Step-by-step setup |
| Presentation | (separate deck) | Summary for presenting the work |

## 7. Design decisions by area

**Secret prevention.** Four layers: ignore rules, local pre-commit scan, server push protection, CI scan. Rationale: local hooks can be skipped, so server-side and CI layers act as backstops [1]. A leak response order is documented: rotate first, then purge history.

**Least-privilege access.** Default Read role, teams over individuals, two-factor authentication, expiring fine-grained tokens, read-only deploy keys and a read-only default CI token, plus periodic review. A script sets the Actions token to read-only.

**Branch protection.** Pull request, approval, required checks, conversation resolution, no force push or deletion, administrators included [2]. A `--solo` mode exists because a person cannot approve their own pull request.

**Dependency hygiene.** Dependabot configuration for GitHub Actions with commented examples for other ecosystems (the stack is project-specific), lockfiles, CI audit guidance, and pinning of Actions to commit SHAs [4, 7].

**Issue disclosure.** `SECURITY.md` with supported versions, contact, response targets and safe harbor; an issue-template link to private reporting [5].

**README quality.** The README is treated as a security control: it contains a configuration table with a "secret?" column, a security section and no real hostnames or emails.

**Sample data.** Synthetic data only, reserved example domains and documentation IP ranges [12, 13], and ignore rules for dumps, logs, captures and HAR files.

## 8. Findings and implementation results

- A complete, reusable baseline was implemented as files and scripts, with every credential-like value being a placeholder.
- Controls were designed to overlap, so that a failure of one (for example a skipped hook) is covered by another (push protection or CI).
- Several controls depend on GitHub plan level or manual steps (see limitations).
- Practical issues found and handled during development: a solo maintainer cannot satisfy a required-approval rule on their own pull request; a fixed example key used in a canary test would be ignored by some scanners, so the final canary script generates a random key at run time; `.gitignore` rules for data files such as `*.sql` can hide legitimate files, so they were removed from the default.

## 9. Repository structure

```
README.md  SECURITY.md  LICENSE  .gitignore  .env.example  config.example.yaml
.pre-commit-config.yaml  .gitattributes
.github/   CODEOWNERS  dependabot.yml  pull_request_template.md
           ISSUE_TEMPLATE/config.yml  workflows/secret-scan.yml
docs/      SECURITY_GUIDE.md  TECHNICAL_REPORT.md  GUIDE.md  CHECKLIST.md
           VERIFY_NO_SECRETS.md  SETUP_LINUX.md  SETUP_WINDOWS.md  VIDEO_SCRIPT.md
           evidence/  (screenshots and test results)
scripts/   check-secrets.sh  canary-test.sh  personalize.sh
           apply-github-protections.sh  setup-git-identity.sh
```

## 10. Testing and evaluation

### 10.1 Tests performed during development

The following were run in a scratch Linux environment on a copy of the repository, not on the live GitHub repository:

| Test | Result |
|---|---|
| Shell syntax check (`bash -n`) of all scripts | No errors |
| `personalize.sh` in a scratch repository | Placeholders for username and repository name were replaced in the expected files |
| `check-secrets.sh` in a scratch repository (after one commit) | Filename, history and `.gitignore` checks reported OK; `.env` was not tracked; the gitleaks step was skipped because gitleaks was not installed there |
| `canary-test.sh` with no secret-scanning hook | Reported FAIL (the fake key was committable) and restored the repository to a clean state |
| `canary-test.sh` with a simple grep-based pre-commit hook | Reported PASS (commit blocked) and cleaned up the throwaway branch |

### 10.2 Not tested in that environment

gitleaks, the pre-commit framework, the GitHub Actions workflow, the GitHub API calls in `apply-github-protections.sh`, branch-protection behaviour on a real repository, and Dependabot. These require the live repository and network access to GitHub.

### 10.3 Live repository tests (complete before submitting)

Run each test on your own repository and record the actual result and evidence file. Do not submit this table with blanks or with results you did not observe.

| # | Test | Command or action | Expected | Actual result | Evidence |
|---|---|---|---|---|---|
| 1 | `.env` is ignored | `git check-ignore -v .env` | Prints the matching rule | [fill in] | 02 |
| 2 | Pre-commit hooks run | `pre-commit run --all-files` | Hooks pass | [fill in] | 03 |
| 3 | Canary blocked | `bash scripts/canary-test.sh` | PASS | [fill in] | 04 |
| 4 | Secret check script | `bash scripts/check-secrets.sh` | No issues found | [fill in] | 05 |
| 5 | CI secret scan runs | Open Actions tab after push | `secret-scan` run succeeds | [fill in] | 06 |
| 6 | Full-history scan | `gitleaks detect` on a mirror clone | No leaks found | [fill in] | 14 |
| 7 | Branch protection | `git push origin main` with a new local commit | Push rejected | [fill in] | 09 |
| 8 | PR gating | Open a test PR; `gh pr checks` | Secret-scan check appears and gates the merge | [fill in] | 10 |
| 9 | Protections applied | `bash scripts/apply-github-protections.sh <user>/<repo> --solo` | OK for each line your plan supports | [fill in] | 08 |
| 10 | Dependabot active | Check Insights, Dependency graph, Dependabot | Enabled | [fill in] | 11 |
| 11 | Security policy visible | Repository Security tab | Policy and private reporting shown | [fill in] | 12, 13 |

## 11. Limitations

- Scanners such as gitleaks detect known patterns and can miss custom or low-entropy secrets; they are one layer, not a guarantee.
- Several GitHub features depend on plan: protected branches are available for public repositories on GitHub Free and for private repositories on paid plans [2]; push protection and secret scanning availability also varies by repository type and plan [1].
- Some settings (fork-pull-request approval, tag rulesets, two-factor authentication) are manual.
- Pre-commit hooks are local and can be bypassed; CI and server-side controls are the backstop.
- The starter does not choose a language ecosystem; Dependabot and audit steps must be adapted.
- The guide addresses repository hygiene, not application-level or infrastructure security.
- Items in section 10.2 had not been tested at the time of writing and are only evaluated once section 10.3 is completed.

## 12. Recommendations

1. Enable all server-side protections available on your plan before the first push of real work.
2. Rotate any credential that ever touched a commit before cleaning history.
3. Pin GitHub Actions to commit SHAs and update hook versions to current releases.
4. Add language-specific dependency audits to CI.
5. Review access, tokens, deploy keys and webhooks quarterly.
6. Run the canary test whenever hooks or scanner configuration change.
7. Use a secrets manager and short-lived credentials (for example OIDC from CI) in real deployments.

## 13. Conclusion

A layered, file-based baseline can make a repository substantially harder to leak from and easier to review, report on and maintain. The deliverables provide that baseline together with documentation and scripts to apply and verify it. The sandbox tests confirmed that the helper scripts behave as designed; the live-repository tests in section 10.3 provide the evidence that the full setup works on GitHub.

## 14. References

[1] GitHub Docs, "About push protection": https://docs.github.com/en/code-security/concepts/secret-security/about-push-protection
[2] GitHub Docs, "About protected branches": https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches
[3] GitHub Docs, "About code owners": https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners
[4] GitHub Docs, "About Dependabot security updates": https://docs.github.com/en/code-security/dependabot/dependabot-security-updates/about-dependabot-security-updates
[5] GitHub Docs, "Adding a security policy to your repository": https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository
[6] OWASP, "Secrets Management Cheat Sheet": https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
[7] OWASP Top 10:2021, "A06 Vulnerable and Outdated Components": https://owasp.org/Top10/A06_2021-Vulnerable_and_Outdated_Components/
[8] NIST SP 800-218, "Secure Software Development Framework (SSDF) Version 1.1": https://csrc.nist.gov/pubs/sp/800/218/final
[9] Gitleaks: https://github.com/gitleaks/gitleaks
[10] pre-commit: https://pre-commit.com
[11] git-filter-repo: https://github.com/newren/git-filter-repo
[12] IETF RFC 5737, "IPv4 Address Blocks Reserved for Documentation": https://datatracker.ietf.org/doc/html/rfc5737
[13] IETF RFC 2606, "Reserved Top Level DNS Names": https://datatracker.ietf.org/doc/html/rfc2606
