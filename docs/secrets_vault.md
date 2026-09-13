# Secrets Vault — Secure Credential & Database Management

IronClad includes an encrypted, zero-trust **Secrets Vault** subsystem designed to store sensitive credentials (API tokens, bearer keys, HTTP Basic auth, and database connection strings) safely on disk and in memory. 

The Vault ensures the agent can interact with external APIs, databases, and remote services **without ever exposing raw credentials to the Large Language Model or leaking them into prompt logs**.

---

## 🏛️ Architecture & Cryptography

```
┌────────────────────────────────────────────────────────────────────────┐
│                        IronClad Secrets Vault                          │
│                                                                        │
│   Master Key Derivation:                                               │
│   IRONCLAD_MASTER_KEY / OS Keyring / .ironclad/vault.key               │
│               │                                                        │
│               ▼                                                        │
│   PBKDF2 (100k rounds) + HKDF-SHA256 ──> 256-bit Key                  │
│                                           │                            │
│   ┌───────────────────────────────────────┼────────────────────────┐   │
│   │                                       ▼                        │   │
│   │    AES-256-GCM Authenticated Encryption at Rest                │   │
│   │    • 96-bit CSPRNG Nonces                                      │   │
│   │    • Additional Authenticated Data (AAD) Secret ID Binding     │   │
│   │    • Zeroized Memory Buffers on Drop                           │   │
│   │    • Persistent Encrypted SQLite: ironclad_vault.db            │   │
│   └────────────────────────────────────────────────────────────────┘   │
│                                           │                            │
│   ┌───────────────────────────────────────▼────────────────────────┐   │
│   │               Dynamic Aho-Corasick Scrubber                    │   │
│   │    Automatically masks all active secrets in LLM reasoning,   │   │
│   │    tool arguments, tool outputs, and audit log streams.        │   │
│   └────────────────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────────────────┘
```

### 1. Cryptographic Primitives (`CryptoEngine`)
- **Encryption Algorithm**: **AES-256-GCM** (Galois/Counter Mode) providing both confidentiality and cryptographic integrity verification.
- **Key Derivation**: Salted **PBKDF2-HMAC-SHA256** (100,000 rounds) combined with **HKDF-SHA256** expansion.
- **Nonce Generation**: 96-bit cryptographically secure random nonces generated per encryption operation via `rand::thread_rng()`.
- **AAD Binding**: The secret's unique ID is bound as Additional Authenticated Data (AAD), preventing ciphertext substitution attacks between records.
- **Memory Safety**: Raw keys and decrypted payloads implement the `zeroize` trait, scrubbing memory buffers when dropped.

### 2. Master Key Resolution Order
The Vault resolves the master encryption key automatically in the following priority order:
1. **Environment Variable**: `IRONCLAD_MASTER_KEY` (ideal for headless servers and CI/CD).
2. **OS Keyring**: System credential store (`keyring` crate) under service `ironclad_agent` and user `master_vault_key`.
3. **Key File Fallback**: `.ironclad/vault.key` in the workspace root. If missing, a 256-bit CSPRNG key is automatically generated and saved with strict file permissions (POSIX `0600` or Windows restricted ACLs).

### 3. Persistent Storage (`VaultStorage`)
Secrets metadata and encrypted ciphertexts are persisted in a dedicated SQLite database located at:
```
<workspace_root>/ironclad_vault.db
```
Raw secrets are never stored in plaintext in the database or config files.

---

## 🔒 Dynamic Vault Scrubber (`DynamicVaultScrubber`)

To prevent accidental secret leakage into LLM reasoning chains or prompt history, the Vault maintains an in-memory **Aho-Corasick** multi-pattern string search automaton:
- Every active secret string (longer than 4 characters) is registered in the scrubber.
- All LLM system prompts, tool inputs, tool execution outputs, and log messages pass through the scrubber.
- Any matching secret text is automatically replaced with `[REDACTED_SECRET:<name>]`.

---

## 📦 Supported Secret Types

| Secret Type | Description | Masking / Safety Features |
|---|---|---|
| `ApiKey` | Standard bearer or header API keys | Value redacted; header name preserved |
| `BearerToken` | OAuth / JWT tokens for HTTP Bearer authentication | Header injected as `Bearer <token>` |
| `BasicAuth` | Username and password pairs | Automatically encoded to Base64 HTTP Basic header |
| `Database` | Connection URIs / DSNs (PostgreSQL, MySQL, SQLite, MongoDB, Redis) | Credentials masked in logs (`postgres://***:***@host:5432/db`); supports live TCP port connectivity probing |
| `Custom` | Key-value pairs for custom tools and environment injection | Injected safely into subprocesses via `IRONCLAD_VAULT_*` env vars |

---

## 🛠️ Agent-Facing Skills

The agent never receives raw secrets in prompt text. Instead, it references secrets by their unique identifier (`secret_id`):

### 1. `list_vault_secrets`
Allows the agent to discover available credentials without reading their plaintext values.
- **Returns**: Secret ID, friendly name, secret type, and allowed domain scope.
- **Does NOT return**: Passwords, API keys, or raw connection strings.

### 2. `http_request` (Authenticated HTTP Client)
Executes HTTP requests with automatic injection of Vault secrets:
- The agent supplies `vault_secret_id` and the target URL.
- The skill validates the target URL against **SSRF protections** (blocking localhost, private IP ranges, AWS/cloud metadata services, and DNS rebinding).
- The skill verifies that the target host matches the secret's configured `allowed_domains`.
- The secret is injected into the outbound HTTP request headers directly in Rust. The response is returned to the agent with sensitive header values redacted.

### 3. `web_scrape` (Authenticated Web Scraping)
Similar to `http_request`, allows scraping authenticated web pages using a Vault credential while enforcing SSRF filters and domain matching.

### 4. Shell & Subprocess Environment Injection
When executing commands via `shell_execute` or `subprocess_manager`:
- Configured database secrets or API tokens can be mapped into the subprocess environment as `IRONCLAD_VAULT_<NAME>`.
- The command output stream is filtered through the dynamic scrubber before being stored in audit logs or returned to the LLM.

---

## 🌐 Web Dashboard & REST API

The Web Dashboard features a dedicated **Secrets Vault** tab (`http://127.0.0.1:8080`):
- **Visual Secret Management**: Add, view metadata for, update, and delete secrets.
- **Domain Whitelisting**: Restrict each secret to specific hostnames (e.g. `api.github.com`, `*.mycorp.internal`).
- **Database Probing**: Test database connectivity with a single click (`POST /api/vault/probe-db`) which runs non-destructive TCP handshake probes against PostgreSQL, MySQL, Redis, MongoDB, or SQLite targets.
- **Audit Logging**: View an immutable log of every secret creation, update, and egress access.

### REST Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/api/vault/secrets` | `GET` | List all secret metadata (masked values) |
| `/api/vault/secrets` | `POST` | Create a new secret |
| `/api/vault/secrets/:id` | `GET` | Get metadata for a specific secret |
| `/api/vault/secrets/:id` | `PUT` | Update an existing secret |
| `/api/vault/secrets/:id` | `DELETE` | Delete a secret |
| `/api/vault/probe-db` | `POST` | Perform a TCP connectivity probe on a database secret |
| `/api/vault/audit` | `GET` | Get recent Vault access audit events |

---

## 🛡️ Security Best Practices

1. **Keep Master Key Secure**: Set `IRONCLAD_MASTER_KEY` in your private `.env` file or rely on the OS Keyring. Ensure `.ironclad/vault.key` is listed in `.gitignore` (excluded by default).
2. **Restrict Domain Scope**: Always specify `allowed_domains` when creating secrets (e.g., `["api.openai.com"]`). The Vault will refuse to inject secrets into requests targeting unlisted domains.
3. **Database Security**: When configuring database secrets, use read-only database users whenever possible.
4. **Never Print Secrets**: Do not attempt to instruct the agent to echo Vault environment variables; the dynamic scrubber will redact them regardless.
