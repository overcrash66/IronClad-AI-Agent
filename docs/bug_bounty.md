# Security Defense & Bug Bounty Engine: Host Defense, Repo SAST & Ethical Recon

IronClad includes an autonomous, multi-layer security engine designed for **Blue Team host defense** (hardening the local OS, network interfaces, and file permissions), **Open Source Codebase & Repository Security Auditing** (SAST, secrets scanning, dependency hygiene, and CI/CD workflow security), and **Ethical Bug Bounty Reconnaissance** (strict scope validation, passive OSINT, and platform ROE compliance).

---

## 1. Operating Modes

The security engine provides three core modes:

### Mode 1: Blue Team Host Defense (`--mode blue_team`, default)
Protects the host OS, user machine, and local network where IronClad runs:
- **Host Network & Port Auditing**: Inspects active socket bindings (`netstat`/`ss`). Detects services bound to `0.0.0.0` (such as local LLM inference engines on port 11435, SMB port 445, RPC 135) that expose internal endpoints to LAN/WAN adversaries.
- **File Permissions & ACL Hardening**: Checks Windows ACLs (`icacls`) and POSIX file modes on sensitive files (`.env`, `settings.toml`, `ironclad_audit.db`, SSH/TLS keys) to ensure broad access groups like `BUILTIN\Users` or world-readability cannot leak secrets.
- **Git Exposure & Leak Prevention**: Audits `.gitignore` to ensure secrets, SQLite databases, and vulnerability reports are never committed to version control.
- **Configuration Hardening**: Validates `settings.toml` and `.env` flags to detect risky configurations (such as autonomous mode without path restrictions).
- **Host Firewall Status**: Inspects Windows Firewall / `ufw` status across Domain, Private, and Public profiles.
- **Automated Remediation (`--fix` / `auto_fix: true`)**: Safely tightens ACLs to restrict access strictly to the current user and SYSTEM, appends missing defensive patterns to `.gitignore`, and outputs targeted firewall isolation rules.

### Mode 2: Open Source Repository & Code Security Scanner (`--mode repo`)
Performs Static Application Security Testing (SAST), secrets detection, and supply-chain auditing across repositories, applications, and source code:
- **Secrets & Credential Detection**: High-entropy regex engine detecting AWS Access Keys (`AKIA...`), GitHub Personal Access Tokens (`ghp_...`), OpenAI keys (`sk-...`), Slack tokens, unencrypted private keys, JWTs, and generic passwords with false-positive filtering.
- **Multi-Language SAST**:
  - **Python**: CWE-78 Command Injection (`shell=True`, `os.system`), CWE-89 SQL Injection (f-strings/concatenation in queries), CWE-502 Insecure Deserialization (`pickle.loads`, unsafe YAML `yaml.load`), CWE-94 Dynamic Code Evaluation (`eval`, `exec`), CWE-295 Insecure TLS/SSL (`verify=False`).
  - **JavaScript / TypeScript**: CWE-79 XSS (`innerHTML`, `dangerouslySetInnerHTML`), CWE-94 `eval()`, CWE-78 `child_process.exec`.
  - **Rust**: CWE-242 Unsafe block auditing (`unsafe {}`), CWE-78 Subprocess shell invocation (`Command::new("sh"|"cmd")`).
  - **Shell**: CWE-494 Unverified remote script execution (`curl | bash`).
- **Software Composition Analysis (SCA)**:
  - Audits `requirements.txt` for unpinned packages (`pkg` without `==`) and insecure plaintext package index URLs (`http://`).
  - Audits `package.json` for wildcard (`*`) dependencies.
  - Audits `Cargo.toml` for unpinned git repositories.
- **CI/CD Pipeline Security**: Audits `.github/workflows/` for `pull_request_target` trigger misuse with untrusted checkouts and shell injection in `run:` blocks (`${{ github.event... }}`).
- **Automated Remediation (`--fix`)**:
  - Automatically generates `.env.example` templates masking real secrets.
  - Automatically upgrades plaintext `http://` pip indices to encrypted HTTPS (`https://pypi.org/simple`).

### Mode 3: Ethical Bug Bounty Reconnaissance (`--mode recon`)
Performs policy-compliant reconnaissance against authorized targets:
- **Strict Scope Enforcement**: Validates targets against `scope.allowed_domains` in `tools/bug_bounty_config.yaml`. Unauthorized external targets are blocked by default unless explicit written authorization is confirmed via `--authorized`.
- **Passive-First Reconnaissance (`--passive`)**: Zero packets sent to target. Leverages public Certificate Transparency logs (`crt.sh`) for passive subdomain discovery, audits RFC 9116 `security.txt` vulnerability disclosure policies, and inspects HTTP security headers (HSTS, CSP, X-Frame-Options, Referrer-Policy).
- **Researcher Identification**: Automatically injects researcher tracking headers (`X-HackerOne-Research: <username>`, `X-BugBounty-Hunter: <username>`, `User-Agent: IronClad-Security-Research/...`) into web requests to comply with bug bounty platform transparency requirements.
- **Safe Scan Profiles**: Replaced unthrottled port sweeps (`-p-`) with polite, rate-limited profiles (`passive`, `quick`, `safe_web`, `stealth`).

---

## 2. Usage Examples

### Via IronClad Agent (Natural Language)
- *"Audit the security of this open source repository for vulnerabilities and hardcoded secrets"*
- *"Run a blue team security scan on the local system with auto-fix enabled"*
- *"Perform passive bug bounty reconnaissance on target https://example.com"*

### Via Skill Tool Call (`bug_bounty_scan_py`)
```json
{
  "mode": "repo",
  "target": ".",
  "auto_fix": false,
  "notify_telegram": true
}
```

```json
{
  "mode": "blue_team",
  "target": "system",
  "auto_fix": true,
  "notify_telegram": true
}
```

```json
{
  "mode": "recon",
  "target": "example.com",
  "passive_only": true,
  "authorized": true
}
```

### Via CLI Directly
```powershell
# 1. Audit Open Source Repository / Codebase
.\venv\Scripts\python.exe tools\bug_bounty_manager.py --mode repo --target . --json

# 2. Audit Repo with Auto-Remediation (.env.example, HTTPS pip indices)
.\venv\Scripts\python.exe tools\bug_bounty_manager.py --mode repo --target . --fix --json

# 3. Run Host OS Defense Audit
.\venv\Scripts\python.exe tools\bug_bounty_manager.py --mode blue_team --target system --json

# 4. Perform Passive External Reconnaissance (Zero Port Sweep Packets)
.\venv\Scripts\python.exe tools\bug_bounty_manager.py --mode recon --target example.com --passive --json

# 5. External Active Recon (Requires Authorization)
.\venv\Scripts\python.exe tools\bug_bounty_manager.py --mode recon --target scanme.nmap.org --profile quick --authorized
```

---

## 3. Configuration (`tools/bug_bounty_config.yaml`)

```yaml
scope:
  enforce_scope: true
  allowed_domains:
    - "localhost"
    - "127.0.0.1"
    - "system"
    - "scanme.nmap.org"
    - "example.com"

researcher:
  hackerone_username: "ironclad_researcher"
  contact_email: "security@example.com"
  custom_headers:
    User-Agent: "IronClad-Security-Research/1.0 (hackerone.com/{username})"
    X-HackerOne-Research: "{username}"
    X-BugBounty-Hunter: "{username}"
```

---

## 4. Reports

All findings and remediation records are saved in the `bug_bounty_reports/` directory:
- `repo_security_report_<target>_<timestamp>.md` for source code SAST, secret, and dependency audits.
- `system_defense_report_<timestamp>.md` for host OS defense & remediation logs.
- `<target>_<timestamp>.md` for external bug bounty reconnaissance reports.
