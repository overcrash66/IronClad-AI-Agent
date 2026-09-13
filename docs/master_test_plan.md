# IronClad AI Agent — Master Test Plan & Verification Guide

> **Document Version:** 1.1.0  
> **Status:** Active Reference Specification  
> **Applicability:** IronClad v0.6.7+  
> **Target Environments:** Windows (pwsh), Linux (bash), macOS, Docker, WSL2  

---

## 1. Executive Summary & Test Strategy

This document provides the definitive, comprehensive **Master Test Plan** for the IronClad AI Agent framework. It establishes a rigorous verification taxonomy spanning:
- Single-turn and multi-turn autonomous agent loops & Mission DAG Planning.
- Asynchronous multi-actor swarms (`SwarmOrchestrator`).
- External CLI coding agent orchestration (`delegate_to_cli_agent`, `subprocess_manager`).
- Distributed multi-instance federation (`remote_agent` HTTP bridge).
- Model Context Protocol (**MCP**) live stdio server integration.
- Headless API daemon, HMAC-verified webhooks (`POST /api/v1/webhooks/github`), and Prometheus telemetry.
- Zero-Trust Three-Ring Governor, Secrets Vault (AES-256-GCM, PBKDF2, Zeroize), Dynamic Aho-Corasick Scrubber, Docker/WSL sandboxing, and resource constraint enforcement.
- Autonomous Pulse Scheduler (`tokio-cron-scheduler`), periodic maintenance, and session summarization (`LearningSummarizer`).
- Embedded Web Dashboard SPA contracts, markdown sanitization, and real-time state synchronization.

---

## 2. Pillar Architecture Disambiguation: System Architecture vs. Agent Capabilities

To avoid terminology collision across the codebase, IronClad formally distinguishes between two complementary pillar models:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        IronClad AI Agent Suite                         │
├──────────────────────────────────┬─────────────────────────────────────┤
│   8 System Architecture Pillars  │    8 Agent Capability Pillars       │
│      (Master Test Plan)          │       (Academic Benchmark)          │
├──────────────────────────────────┼─────────────────────────────────────┤
│ 1. Single-Agent Core & Planner   │ 1. Tool Use & Function Precision    │
│ 2. Multi-Agent Swarms            │ 2. Multi-Step DAG Task Planning     │
│ 3. External CLI Orchestration    │ 3. Math Reasoning & Formal Proofs   │
│ 4. Distributed Multi-Instance    │ 4. Autonomous Agentic Tasks         │
│ 5. Model Context Protocol (MCP)  │ 5. Safety, Governor & Red-Teaming   │
│ 6. Headless APIs, SPA & Webhooks │ 6. Multi-Turn OS & Database Ops     │
│ 7. Governor, Vault & Sandboxing  │ 7. Context & Token Hygiene          │
│ 8. Autonomous Pulse Scheduler    │ 8. Resilience & Self-Correction     │
├──────────────────────────────────┼─────────────────────────────────────┤
│ Target: Runtime Daemons, Drivers,│ Target: LLM Reasoning, Prompt       │
│ Crypto, IPC, Sandboxing & Invars │ Adherence & Solution Accuracy       │
│ Verified by: Master Test Plan    │ Verified by: docs/benchmarks.md     │
│ runner & Rust/Pytest Test Suites │ & `ironclad benchmark` CLI          │
└──────────────────────────────────┴─────────────────────────────────────┘
```

The current testing baseline of the repository consists of:
- **1,039 passed library unit tests** (`cargo test --lib`).
- **45 Rust integration test targets** (`tests/*.rs`).
- **10 Python end-to-end integration test suites** (64 pytest tests in `tests/`).
- **2 deterministic offline benchmark targets** (`tests/benchmarks.rs`).
- **10 academic capability benchmark scenario suites** in `benchmark/suites/`.

---

## 3. Gap Analysis: Why Key Subsystems Require Explicit Test Procedures

While unit tests validate algorithmic units in isolation, interactive live validation requires active background processes, IPC pipes, or external mock daemons. Below is the technical analysis of why advanced subsystems require specialized testing fixtures:

### 3.1 GitHub Webhook Ingestion (`POST /api/v1/webhooks/github`)
* **Prior Testing Status:** Unit tests validated deserialization and HMAC math in isolation.
* **Why Not Tested Live Interactively:** Inbound webhooks strictly enforce `api.webhook_secret` and valid `X-Hub-Signature-256` HMAC-SHA256 headers. Plain unauthenticated requests are rejected immediately with `HTTP 401 Unauthorized`. Additionally, webhook tasks operate asynchronously by acknowledging with `HTTP 200 OK` and dispatching a detached Tokio task.
* **Resolution in Test Plan:** Automated script fixture ([Test 6.1](#test-61--github-webhook-push-event-ingestion-with-hmac-sha256-signature)) that configures `api.webhook_secret`, computes HMAC-SHA256 digests over payload bytes, verifies rejection of unauthenticated requests, and asserts background processing.

### 3.2 Live Model Context Protocol (MCP) Servers
* **Prior Testing Status:** Verified by unit tests (`tests/mcp_tests.rs`, `tests/mcp_client_tests.rs`) using in-memory mock JSON-RPC streams.
* **Why Not Tested Live Interactively:** Running MCP end-to-end requires a live child process communicating over bidirectional stdio.
* **Resolution in Test Plan:** Dedicated Python stdio MCP server fixture (`benchmark/fixtures/mock_mcp_server.py`) exercising `initialize`, `tools/list`, and `tools/call` ([Test 5.1](#test-51--stdio-mcp-server-tool-auto-discovery--invocation)).

### 3.3 Swarm of Agents Pipeline (`SwarmOrchestrator`)
* **Prior Testing Status:** Actor prompt generation was tested in isolation.
* **Why Not Tested Live Interactively:** `SwarmOrchestrator` chains four consecutive LLM roles (*Architect*, *Coder*, *SecurityReviewer*, *TestEngineer*). Live inference against slow models requires significant token latency.
* **Resolution in Test Plan:** Dedicated pipeline harness ([Test 2.1](#test-21--4-actor-swarm-pipeline-execution)) that exercises `run_swarm_pipeline` across all four roles.

### 3.4 External CLI Agent Orchestration (`subprocess_manager` & PTY)
* **Prior Testing Status:** Non-interactive subprocess calls were tested via mock streams.
* **Why Not Fully Tested:** Full interactive process management involves bidirectional pseudo-terminal (PTY) allocation, regex stdout buffering, and clean SIGTERM/kill signal cleanup across process trees.
* **Resolution in Test Plan:** Persistent Python REPL lifecycle test ([Test 3.1](#test-31--interactive-pty-process-management-via-subprocess_manager)).

### 3.5 Distributed Cluster Federation (`remote_agent`)
* **Prior Testing Status:** `RemoteAgentSkill` unit tests validated payload construction.
* **Why Not Tested Live Interactively:** Requires orchestrating two concurrent IronClad daemon instances on separate TCP ports.
* **Resolution in Test Plan:** Dual-instance cluster test ([Test 4.1](#test-41--dual-ironclad-cluster-federation-remote_agent)) where Primary delegates sub-tasks over HTTP to Worker.

### 3.6 Secrets Vault & Dynamic Scrubber
* **Prior Testing Status:** Cryptographic primitives were tested in unit suites.
* **Why Not Tested Live Interactively:** Live LLM prompts could leak credentials if the scrubber fails to mask sensitive patterns in real time across token streams.
* **Resolution in Test Plan:** Automated encryption roundtrip, tamper detection with AAD, and multi-pattern Aho-Corasick dynamic scrubber validation ([Test 7.4](#test-74--secrets-vault-authenticated-encryption--dynamic-aho-corasick-scrubber)).

### 3.7 Autonomous Pulse Scheduler
* **Prior Testing Status:** Parser unit tests validated cron string translation.
* **Why Not Tested Live Interactively:** Requires clock progression and SQLite state verification.
* **Resolution in Test Plan:** Lifecycle test verifying natural language scheduling, SQLite persistence across restarts, and trigger execution ([Test 8.1](#test-81--autonomous-cron-job-scheduling-persistence--execution)).

---

## 4. Master Test Matrix: 8 System Architecture Pillars

| Pillar | Focus Area | Key Components Tested | Execution Mode |
|---|---|---|---|
| **Pillar 1** | Single-Agent Core & Mission Planner | ReAct Loop, DAG Planner, Git Ops, Memory, AST RAG | CLI (`orchestrate`) / Rust Tests |
| **Pillar 2** | Multi-Agent Swarms & Coordination | `SwarmOrchestrator`, Shared Blackboard, Task Leases | Rust API / Custom Harness |
| **Pillar 3** | External CLI Agent Orchestration | `subprocess_manager`, PTY Drivers, `delegate_to_cli_agent` | CLI / Subprocess |
| **Pillar 4** | Distributed Multi-Instance Federation | `remote_agent`, OpenAI Proxy Endpoint, Cross-Node RPC | Multi-Daemon Network |
| **Pillar 5** | Model Context Protocol (MCP) | JSON-RPC stdio, Tool Auto-Discovery, Schema Validation | Stdio Subprocess |
| **Pillar 6** | Headless APIs, Webhooks & Dashboard SPA | Axum Server, HMAC Webhooks, Prometheus, SPA DOM | HTTP Client / Pytest |
| **Pillar 7** | Security Governor, Secrets Vault & Sandbox | Three-Ring Policy, AES-256-GCM Vault, Scrubber, Docker | Sandboxed Runtime / Rust Tests |
| **Pillar 8** | Autonomous Pulse Scheduler & Maintenance | `tokio-cron-scheduler`, NL Cron, `LearningSummarizer` | Background Engine / Rust Tests |

---

## 5. Detailed Test Specifications & Execution Procedures

### Pillar 1: Single-Agent Core Engine & Mission DAG Planner

#### Test 1.1 — ReAct Self-Correction on Tool Failure
* **Objective:** Verify that when a tool execution fails, the agent generates a reflection prompt, analyzes the error, and recovers autonomously.
* **Command:**
  ```powershell
  cargo run -- orchestrate --task "Read nonexistent_file_xyz.txt, and if missing, find the largest file in src/ and summarize it."
  ```
* **Expected Output:**
  1. Agent calls `read_file` with `nonexistent_file_xyz.txt`.
  2. Governor/Executor returns file not found error.
  3. ReAct reflection hook captures the failure.
  4. Agent pivots to `list_directory` or `grep_search` and successfully summarizes the file.
* **Pass Criteria:** Final answer generated; task does not crash; reflection logged to `ironclad_audit.db`.

#### Test 1.2 — Multi-Turn Memory & Semantic Fact Recall Across Process Restarts
* **Objective:** Ensure facts stored in Turn 1 persist in SQLite and are recalled in Turn 2 in a new OS process.
* **Command:**
  ```powershell
  # Turn 1
  cargo run -- --session persistent-eval-101 orchestrate --task "Remember that the staging redis password is 'IronCladSecret99'."
  # Turn 2
  cargo run -- --session persistent-eval-101 orchestrate --task "What is the staging redis password I asked you to remember?"
  ```
* **Pass Criteria:** Turn 2 accurately extracts `'IronCladSecret99'` from `memory.db` without prompting the user.

#### Test 1.3 — Mission DAG Planner Decomposition & Timing Telemetry
* **Objective:** Verify that complex tasks are decomposed into sequential DAG stages and record separated planner vs. worker telemetry.
* **Pass Criteria:** `planner_duration_ms` and `worker_duration_ms` recorded; DAG milestone status reported.

---

### Pillar 2: Multi-Agent Swarms & Coordination

#### Test 2.1 — 4-Actor Swarm Pipeline Execution
* **Objective:** Verify the sequential handoff: Architect -> Coder -> Security Reviewer -> Test Engineer.
* **Automated Invocation:**
  ```powershell
  .\venv\Scripts\python.exe benchmark/run_master_test_plan.py --pillar swarm
  ```
* **Expected Output:**
  - `[ARCHITECT PLAN]`: Component breakdown, data structures, and interface definitions.
  - `[CODER IMPLEMENTATION]`: Syntactically valid code with proper typing and concurrency management.
  - `[SECURITY AUDIT]`: Security inspection for injection, memory safety, and boundary validation.
  - `[TEST SUITE]`: Unit tests verifying core functionality and edge cases.
* **Pass Criteria:** All 4 pipeline phases complete with non-empty, contextually relevant outputs.

#### Test 2.2 — Shared Blackboard & Atomic Task Claim Contention
* **Objective:** Verify that concurrent sub-agents claiming the same task in `coordination.db` respect atomic leases.
* **Verification Steps:**
  1. Agent A claims `task-cache-module` with a 30-second lease.
  2. Agent B attempts to claim `task-cache-module` before expiration.
  3. Agent B receives `TaskAlreadyClaimed` rejection.
  4. Agent A posts artifact to blackboard; status transitions to `Completed`.
* **Pass Criteria:** No double-claims permitted; audit log confirms lease contention resolution.

---

### Pillar 3: External CLI Agent Orchestration

#### Test 3.1 — Interactive PTY Process Management via `subprocess_manager`
* **Objective:** Verify spawning a persistent child CLI process, writing to its stdin, and reading matched stdout.
* **Command:**
  ```powershell
  cargo run -- orchestrate --task 'Use subprocess_manager to spawn a python interactive shell, send "x = 42 * 2; print(f\"RESULT={x}\")", read the output, and terminate the process.'
  ```
* **Expected Steps:**
  1. `subprocess_manager action="spawn" command="python" args=["-i"]`.
  2. `subprocess_manager action="send" id="..." input="x = 42 * 2; print(f'RESULT={x}')\n"`.
  3. `subprocess_manager action="read" id="..." timeout_ms=3000` -> Captures `RESULT=84`.
  4. `subprocess_manager action="kill" id="..."` -> Clean termination.
* **Pass Criteria:** Process ID tracked in state; output string captured; no orphaned processes remain.

#### Test 3.2 — External Agent Escalation (`delegate_to_cli_agent`)
* **Objective:** Detect installed CLI agents (`pi`, `claude`, `aider`, `opencode`) and delegate a task.
* **Command:**
  ```powershell
  cargo run -- orchestrate --task "Delegate to external CLI agent 'pi' (or auto) to inspect Cargo.toml and list all dependencies."
  ```
* **Pass Criteria:** CLI agent discovered via PATH; arguments forwarded; output returned to IronClad context.

---

### Pillar 4: Distributed Multi-Instance Federation

#### Test 4.1 — Dual-IronClad Cluster Federation (`remote_agent`)
* **Objective:** Two independent IronClad instances communicating over HTTP.
* **Setup:**
  1. **Worker Node (Instance A)**:
     ```powershell
     cargo run -- serve --port 3001
     ```
  2. **Primary Node (Instance B)**:
     Configured in `settings.toml`:
     ```toml
     [integrations.remote_agents]
     enabled = true
     [[integrations.remote_agents.endpoints]]
     name = "ironclad-worker-node"
     url = "http://127.0.0.1:3001/v1/chat/completions"
     key = ""  # Bearer token if API key is enabled on worker
     timeout_secs = 60
     ```
  3. **Trigger Execution from Primary**:
     ```powershell
     cargo run -- orchestrate --task "Use remote_agent to ask ironclad-worker-node to explain zero-copy deserialization in Rust."
     ```
* **Pass Criteria:** Seamless cross-process execution; response contains `[Remote agent: ironclad-worker-node]`.

---

### Pillar 5: Model Context Protocol (MCP) Live Integration

#### Test 5.1 — Stdio MCP Server Tool Auto-Discovery & Invocation
* **Objective:** Verify stdio JSON-RPC MCP server connection, dynamic tool registration, and execution.
* **Fixture Setup (`benchmark/fixtures/mock_mcp_server.py`):**
  A lightweight Python script implementing JSON-RPC 2.0 stdio handling `tools/list` and `tools/call`.
* **Configuration (`settings.toml`):**
  ```toml
  [mcp.custom_math]
  command = '.\venv\Scripts\python.exe'  # Use single quotes or forward slashes
  args = ["benchmark/fixtures/mock_mcp_server.py"]
  timeout_secs = 15
  ```
* **Automated Invocation:**
  ```powershell
  .\venv\Scripts\python.exe benchmark/run_master_test_plan.py --pillar mcp
  ```
* **Pass Criteria:**
  1. MCP initialize returns protocol version and server info.
  2. `tools/list` discovers `calculate_hypotenuse`.
  3. `tools/call` executes `calculate_hypotenuse(3, 4)` and returns `5.0`.

---

### Pillar 6: Headless APIs, HMAC Webhooks, Web Dashboard SPA & Telemetry

#### Test 6.1 — GitHub Webhook Push Event Ingestion with HMAC-SHA256 Signature
* **Objective:** Verify `POST /api/v1/webhooks/github` enforces HMAC-SHA256 authentication and dispatches asynchronous background analysis.
* **Execution:**
  1. Start server with configured webhook secret:
     ```powershell
     $env:IRONCLAD__API__WEBHOOK_SECRET = "test-webhook-secret-42"
     cargo run -- serve --port 3000
     ```
  2. Send authenticated push payload:
     ```powershell
     .\venv\Scripts\python.exe -c "
import requests, json, hmac, hashlib

secret = 'test-webhook-secret-42'
payload = {
    'ref': 'refs/heads/main',
    'commits': [
        {'id': 'a1b2c3d', 'message': 'fix(security): sanitize shell command arguments', 'author': {'name': 'Security Bot'}}
    ]
}
body = json.dumps(payload).encode('utf-8')
sig = hmac.new(secret.encode('utf-8'), body, hashlib.sha256).hexdigest()

headers = {
    'Content-Type': 'application/json',
    'X-GitHub-Event': 'push',
    'X-Hub-Signature-256': f'sha256={sig}'
}
res = requests.post('http://127.0.0.1:3000/api/v1/webhooks/github', data=body, headers=headers)
print('Status:', res.status_code, res.text)
assert res.status_code == 200
assert 'Webhook received' in res.text
"
     ```
* **Pass Criteria:**
  - Endpoint returns `HTTP 200 OK ("Webhook received")`.
  - Background task is dispatched to Orchestrator.
  - Missing or invalid HMAC signature returns `HTTP 401 Unauthorized`.

#### Test 6.2 — Prometheus Telemetry Scraping (`GET /metrics`)
* **Objective:** Ensure production metrics endpoint outputs compliant OpenMetrics/Prometheus format.
* **Execution:**
  ```powershell
  curl http://127.0.0.1:3000/metrics
  ```
* **Pass Criteria:** Output contains valid metrics such as `ironclad_tasks_total`, `ironclad_tool_executions_total`, and `ironclad_task_duration_seconds`.

#### Test 6.3 — Web Dashboard SPA Parity & Contract Verification
* **Objective:** Ensure the embedded web dashboard SPA maintains required DOM contracts, blocks XSS injection in markdown, and strips thought monologue tokens.
* **Execution:**
  ```powershell
  .\venv\Scripts\python.exe -m pytest tests/test_frontend_spa.py tests/test_api_security.py -q
  ```
* **Pass Criteria:** 100% pass across all DOM element checks, JavaScript syntax checks, markdown sanitizers, and API loopback security assertions.

---

### Pillar 7: Security Governor, Secrets Vault, Sandboxing & Resource Limits

#### Test 7.1 — Wall-Clock Session Budget Enforcement (`session_budget_secs`)
* **Objective:** Ensure runaway loops gracefully exit when the configured time limit expires.
* **Setup:** Configure `session_budget_secs = 10` in `settings.toml`.
* **Execution:**
  ```powershell
  cargo run -- orchestrate --task "Run a loop counting to 1000000 with 1 second sleep between numbers."
  ```
* **Pass Criteria:** Execution gracefully halts after 10 seconds; logs report session budget expired; partial results saved without corruption.

#### Test 7.2 — Context Compression Under Heavy Multi-Turn Token Bloat
* **Objective:** Verify that long sessions automatically summarize dropped history when `context_compression = true`.
* **Pass Criteria:** Token count stays within model context boundary; agent references early conversation facts accurately via injected summary.

#### Test 7.3 — Docker Sandbox Isolation & Network Disabling
* **Objective:** Verify container isolation when `backend = "docker"`.
* **Configuration:**
  ```toml
  [sandbox]
  backend = "docker"
  default_image = "alpine:latest"
  network_enabled = false
  ```
* **Command:**
  ```powershell
  cargo run -- orchestrate --task "Run ping -c 1 8.8.8.8 inside the sandbox."
  ```
* **Pass Criteria:** Command fails with network unreachable error inside container; host network remains unaffected.

#### Test 7.4 — Secrets Vault Authenticated Encryption & Dynamic Aho-Corasick Scrubber
* **Objective:** Verify that sensitive credentials stored in `ironclad_vault.db` use AES-256-GCM authenticated encryption and that the Dynamic Vault Scrubber redacts credentials from LLM reasoning, tool arguments, outputs, and audit logs.
* **Automated Invocation:**
  ```powershell
  .\venv\Scripts\python.exe benchmark/run_master_test_plan.py --pillar vault
  ```
* **Pass Criteria:**
  - `cargo test --lib vault::`: AES-256-GCM encryption roundtrips pass, wrong key fails, tampered AAD fails, PBKDF2 salt derivation is unique per record, zeroize cleans memory.
  - `cargo test --test test_scrubber`: Dynamic scrubber replaces plaintext secrets with `[REDACTED:SECRET:<TYPE>]` in all output streams.

---

### Pillar 8: Autonomous Pulse Scheduler & Background Lifecycle

#### Test 8.1 — Autonomous Cron Job Scheduling, Persistence & Execution
* **Objective:** Verify natural language cron parsing, job persistence in SQLite `memory.db`, background execution via `tokio-cron-scheduler`, and safety guards against aggressive sub-minute intervals.
* **Automated Invocation:**
  ```powershell
  .\venv\Scripts\python.exe benchmark/run_master_test_plan.py --pillar pulse
  ```
* **Pass Criteria:** `pulse_lifecycle_test` passes; scheduled jobs reload cleanly upon daemon restart.

#### Test 8.2 — Autonomous Pulse CLI Subcommand
* **Objective:** Verify that autonomous maintenance jobs can be triggered directly from the CLI.
* **Command:**
  ```powershell
  cargo run -- pulse --mode scan
  ```
* **Pass Criteria:** Pulse scans workspace, executes scheduled health checks, runs session summarizer (`LearningSummarizer`), and reports summary.

---

## 6. Automated Verification Test Harness Script

To run all automated system architecture pillars, invoke the master test harness inside your active virtual environment:

```powershell
# Run all automated Master Test Plan pillars (Webhooks, MCP, Remote Cluster, Swarms, Vault, Pulse, SPA)
.\venv\Scripts\python.exe benchmark/run_master_test_plan.py --all

# Run specific testing pillars
.\venv\Scripts\python.exe benchmark/run_master_test_plan.py --pillar webhooks
.\venv\Scripts\python.exe benchmark/run_master_test_plan.py --pillar mcp
.\venv\Scripts\python.exe benchmark/run_master_test_plan.py --pillar swarm
.\venv\Scripts\python.exe benchmark/run_master_test_plan.py --pillar vault
.\venv\Scripts\python.exe benchmark/run_master_test_plan.py --pillar pulse
.\venv\Scripts\python.exe benchmark/run_master_test_plan.py --pillar spa
.\venv\Scripts\python.exe benchmark/run_master_test_plan.py --pillar remote_cluster
```

---

## 7. Continuous Integration & Quality Gates

A pull request or release candidate must satisfy all gates below before being certified:

1. **Unit Test Gate:** `cargo test --lib` -> 1,039 unit tests 100% pass (0 failures).
2. **Integration Test Gate:** `cargo test --tests` -> 45 Rust integration targets 100% pass (0 failures).
3. **Pytest Integration Gate:** `.\venv\Scripts\python.exe -m pytest tests/ -q` -> 64 tests 100% pass (0 failures).
4. **Linter & Formatting Gate:** `cargo clippy -- -D warnings` -> 0 warnings, 0 errors.
5. **Deterministic Offline Benchmark Invariants:** `cargo test --test benchmarks` -> 2/2 pass.
6. **Security Scan Gate:** `.\venv\Scripts\python.exe tools/bug_bounty_manager.py --mode repo` -> 0 Critical / High severity findings.
7. **Master Architecture Live Gate:** `.\venv\Scripts\python.exe benchmark/run_master_test_plan.py --all` -> All executed pillars pass.
