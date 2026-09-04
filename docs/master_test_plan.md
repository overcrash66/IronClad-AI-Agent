# IronClad AI Agent — Master Test Plan & Verification Guide

> **Document Version:** 1.0.0  
> **Status:** Active Reference Specification  
> **Applicability:** IronClad v0.6.7+  
> **Target Environments:** Windows (pwsh), Linux (bash), macOS, Docker, WSL2  

---

## 1. Executive Summary & Test Strategy

This document provides the definitive, comprehensive **Master Test Plan** for the IronClad AI Agent framework. It establishes a rigorous verification taxonomy spanning:
- Single-turn and multi-turn autonomous agent loops.
- Asynchronous multi-actor swarms (`SwarmOrchestrator`).
- External CLI coding agent orchestration (`delegate_to_cli_agent`, `subprocess_manager`).
- Distributed multi-instance federation (`remote_agent` HTTP bridge).
- Model Context Protocol (**MCP**) live server integration.
- Headless API daemon, webhooks, and Prometheus telemetry.
- Zero-Trust Three-Ring Governor, Docker/WSL sandboxing, and resource constraint enforcement.

---

## 2. Gap Analysis: Why Specific Use Cases Were Not Yet Tested Live

While the standard test suite includes **693 passed library unit tests** and **43 integration test targets**, prior interactive validation focused primarily on single-agent CLI tasks and local tools. Below is the technical root-cause analysis of why key advanced subsystems were not previously exercised end-to-end:

### 2.1 GitHub Webhook Ingestion (`POST /api/v1/webhooks/github`)
* **Prior Testing Status:** Unit tests validated JSON deserialization and routing. Headless API tests verified `GET /metrics`, `POST /v1/chat/completions`, and `POST /api/v1/tasks`.
* **Why Not Tested Live:** Webhooks operate asynchronously: they acknowledge receipt with `HTTP 200 OK` within milliseconds, then spawn a detached Tokio task to analyze commits or comments in the background. Verifying this requires sending simulated webhook payloads with valid `X-GitHub-Event` and HMAC-SHA256 signatures while monitoring audit log events.
* **Resolution in Test Plan:** Dedicated test script ([Test 6.1](#test-61--github-webhook-push-event-processing)) simulating GitHub push/issue_comment webhooks and asserting background task execution.

### 2.2 Live Model Context Protocol (MCP) Servers
* **Prior Testing Status:** Verified by 18 unit/integration tests (`tests/mcp_tests.rs`, `tests/mcp_client_tests.rs`) using in-memory mock JSON-RPC streams.
* **Why Not Tested Live:** Running MCP end-to-end requires a live, external process running over stdio (e.g. `@modelcontextprotocol/server-filesystem` or a Python MCP server). Without an active MCP server registered in `settings.toml`, the MCP initialization loop safely degrades and skips registration.
* **Resolution in Test Plan:** Standalone Python stdio MCP server fixture ([Test 5.1](#test-51--stdio-mcp-server-tool-auto-discovery--invocation)) to verify live tool discovery, JSON schema extraction, and invocation.

### 2.3 Swarm of Agents Pipeline (`SwarmOrchestrator`)
* **Prior Testing Status:** Unit tests (`src/swarm/actor.rs`) validated the 4 actor roles (*Architect*, *Coder*, *SecurityReviewer*, *TestEngineer*) and sequential chaining using a mock model provider.
* **Why Not Tested Live:** `SwarmOrchestrator` requires four consecutive multi-thousand-token LLM inference passes. In fast interactive CLI validation, single-agent ReAct runs were favored to conserve execution time.
* **Resolution in Test Plan:** Automated multi-stage swarm test ([Test 2.1](#test-21--4-actor-swarm-pipeline-execution)) that runs a complete feature synthesis across all 4 roles against the local model.

### 2.4 External CLI Agent Orchestration (`subprocess_manager` & PTY)
* **Prior Testing Status:** Single-shot non-interactive delegation to `pi` was validated for a basic arithmetic query (`17 * 19`).
* **Why Not Fully Tested:** True interactive process management involves bidirectional PTY streaming, regex-based prompt matching, interactive stdin responses (e.g., user confirmations in CLI wizards), and graceful `SIGTERM`/kill signals across background child processes.
* **Resolution in Test Plan:** Multi-stage subprocess lifecycle test ([Test 3.1](#test-31--interactive-pty-process-management-via-subprocess_manager)) spawning a persistent Python REPL or shell session.

### 2.5 Two IronClad Instances Working Together (`remote_agent`)
* **Prior Testing Status:** `RemoteAgentSkill` unit tests validated payload construction and parsing of generic, LangGraph, and OpenAI-compatible HTTP response formats.
* **Why Not Tested Live:** Requires coordinating two concurrent IronClad daemon instances on separate TCP ports (e.g., Instance A on port 3001, Instance B on port 3002) with cross-configured endpoints in `settings.toml`.
* **Resolution in Test Plan:** Dual-instance cluster test ([Test 4.1](#test-41--dual-ironclad-cluster-federation)) where Primary (Instance B) delegates sub-tasks over HTTP to Worker (Instance A).

---

## 3. Master Test Matrix: 7 Core Testing Pillars

| Pillar | Focus Area | Key Components Tested | Execution Mode |
|---|---|---|---|
| **Pillar 1** | Single-Agent Core Engine | ReAct Loop, Tool Calling, Git Ops, Memory, AST RAG | CLI (`orchestrate`, TUI) |
| **Pillar 2** | Multi-Agent Swarms & Coordination | `SwarmOrchestrator`, Shared Blackboard, Task Leases | Rust API / Custom Harness |
| **Pillar 3** | External CLI Agent Orchestration | `subprocess_manager`, PTY Drivers, `delegate_to_cli_agent` | CLI / Subprocess |
| **Pillar 4** | Distributed Multi-Instance Federation | `remote_agent`, OpenAI Proxy Endpoint, Cross-Node RPC | Multi-Daemon Network |
| **Pillar 5** | Model Context Protocol (MCP) | JSON-RPC stdio, Tool Auto-Discovery, Schema Validation | Stdio Subprocess |
| **Pillar 6** | Headless APIs, Webhooks & Telemetry | Axum Server, GitHub HMAC Webhooks, Prometheus Metrics | HTTP Client (`curl` / Python) |
| **Pillar 7** | Security Governor, Sandboxing & Limits | Three-Ring Policy, Docker Sandbox, Session Budget, Context Compression | Sandboxed Runtime |

---

## 4. Detailed Test Specifications & Execution Procedures

### Pillar 1: Single-Agent Core Engine

#### Test 1.1 — ReAct Self-Correction on Tool Failure
* **Objective:** Verify that when a tool execution fails, the agent generates a reflection prompt, analyzes the error, and recovers autonomously.
* **Command:**
  ```powershell
  ironclad orchestrate --task "Read nonexistent_file_xyz.txt, and if missing, find the largest file in src/ and summarize it."
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
  ironclad --session persistent-eval-101 orchestrate --task "Remember that the staging redis password is 'IronCladSecret99'."
  # Turn 2
  ironclad --session persistent-eval-101 orchestrate --task "What is the staging redis password I asked you to remember?"
  ```
* **Pass Criteria:** Turn 2 accurately extracts `'IronCladSecret99'` from `memory.db` without prompting the user.

---

### Pillar 2: Multi-Agent Swarms & Coordination

#### Test 2.1 — 4-Actor Swarm Pipeline Execution
* **Objective:** Verify the sequential handoff: Architect -> Coder -> Security Reviewer -> Test Engineer.
* **Test Invocation:**
  ```powershell
  .env\Scripts\python.exe benchmark/run_master_test_plan.py --pillar swarm
  ```
* **Expected Output:**
  - `[ARCHITECT PLAN]`: Component breakdown, data structures, and interface definitions.
  - `[CODER IMPLEMENTATION]`: Syntactically valid code with proper typing and concurrency management.
  - `[SECURITY AUDIT]`: Security inspection for injection, memory safety, and boundary validation.
  - `[TEST SUITE]`: Unit tests verifying core functionality and edge cases.
* **Pass Criteria:** All 4 pipeline phases complete with non-empty, contextually relevant outputs.

#### Test 2.2 — Shared Blackboard & Task Claim Contention
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
  ironclad orchestrate --task "Use subprocess_manager to spawn a python interactive shell, send 'x = 42 * 2; print(f"RESULT={x}")', read the output, and terminate the process."
  ```
* **Expected Steps:**
  1. `subprocess_manager action="spawn" command="python" args=["-i"]`.
  2. `subprocess_manager action="send" id="..." input="x = 42 * 2; print(f'RESULT={x}')
"`.
  3. `subprocess_manager action="read" id="..." timeout_ms=3000` -> Captures `RESULT=84`.
  4. `subprocess_manager action="kill" id="..."` -> Clean termination.
* **Pass Criteria:** Process ID tracked in state; output string captured; no orphaned processes remain.

#### Test 3.2 — External Agent Escalation (`delegate_to_cli_agent`)
* **Objective:** Detect installed CLI agents (`pi`, `claude`, `aider`, `opencode`) and delegate a task.
* **Command:**
  ```powershell
  ironclad orchestrate --task "Delegate to external CLI agent 'pi' (or auto) to inspect Cargo.toml and list all dependencies."
  ```
* **Pass Criteria:** CLI agent discovered via PATH; arguments forwarded; output returned to IronClad context.

---

### Pillar 4: Distributed Multi-Instance Federation

#### Test 4.1 — Dual-IronClad Cluster Federation (`remote_agent`)
* **Objective:** Two independent IronClad instances communicating over HTTP.
* **Setup:**
  1. **Worker Node (Instance A)**:
     ```powershell
     ironclad serve --port 3001
     ```
  2. **Primary Node (Instance B)**:
     Configured with:
     ```toml
     [integrations.remote_agents]
     enabled = true
     [[integrations.remote_agents.endpoints]]
     name = "ironclad-worker-node"
     url = "http://127.0.0.1:3001/v1/chat/completions"
     timeout_secs = 60
     ```
  3. **Trigger Execution from Primary**:
     ```powershell
     ironclad orchestrate --task "Use remote_agent to ask ironclad-worker-node to explain zero-copy deserialization in Rust."
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
  command = ".\venv\Scripts\python.exe"
  args = ["benchmark/fixtures/mock_mcp_server.py"]
  timeout_secs = 15
  ```
* **Test Execution:**
  ```powershell
  ironclad orchestrate --task "Use the custom_math tool from the MCP server to calculate the hypotenuse of a right triangle with sides 3 and 4."
  ```
* **Pass Criteria:**
  1. IronClad logs: `Initializing MCP server: custom_math` and `Loaded X tools from MCP server`.
  2. Tool is registered in runtime registry.
  3. Agent invokes tool and returns `5.0`.

---

### Pillar 6: Headless APIs, Webhooks & Telemetry

#### Test 6.1 — GitHub Webhook Push Event Processing
* **Objective:** Verify `POST /api/v1/webhooks/github` accepts webhook events and triggers asynchronous background analysis.
* **Execution:**
  1. Start server:
     ```powershell
     ironclad serve --port 3000
     ```
  2. Send simulated push payload:
     ```powershell
     .env\Scripts\python.exe -c "
import requests, json
payload = {
    'ref': 'refs/heads/main',
    'commits': [
        {'id': 'a1b2c3d', 'message': 'fix(security): sanitize shell command arguments', 'author': {'name': 'Security Bot'}}
    ]
}
res = requests.post('http://127.0.0.1:3000/api/v1/webhooks/github', json=payload)
print('Status:', res.status_code, res.text)
assert res.status_code == 200
"
     ```
* **Pass Criteria:**
  - Endpoint returns `HTTP 200 OK ("Webhook received")`.
  - Background task is dispatched to Orchestrator.
  - Event logged in `ironclad_audit.db` with actor `github_webhook`.

#### Test 6.2 — Prometheus Telemetry Scraping (`GET /metrics`)
* **Objective:** Ensure production metrics endpoint outputs compliant OpenMetrics/Prometheus format.
* **Execution:**
  ```powershell
  curl http://127.0.0.1:3000/metrics
  ```
* **Pass Criteria:** Output contains valid metrics such as `ironclad_tasks_total`, `ironclad_tool_executions_total`, and `ironclad_task_duration_seconds`.

---

### Pillar 7: Security Governor, Sandboxing & Edge Cases

#### Test 7.1 — Wall-Clock Session Budget Enforcement (`session_budget_secs`)
* **Objective:** Ensure runaway loops gracefully exit when the configured time limit expires.
* **Setup:** Configure `session_budget_secs = 10` in `settings.toml`.
* **Execution:**
  ```powershell
  ironclad orchestrate --task "Run a loop counting to 1000000 with 1 second sleep between numbers."
  ```
* **Pass Criteria:** Execution gracefully halts after 10 seconds; logs report session budget expired; partial results saved without corruption.

#### Test 7.2 — Context Compression Under Heavy Multi-Turn Token Bloat
* **Objective:** Verify that long sessions automatically summarize dropped history when `context_compression = true`.
* **Verification:** Generate a synthetic 40-turn session exceeding the model's sliding window; verify that Turn 40 retains critical facts stated in Turn 1 via compressed summary injection.
* **Pass Criteria:** Token count stays within model context boundary; agent references early conversation facts accurately.

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
  ironclad orchestrate --task "Run ping -c 1 8.8.8.8 inside the sandbox."
  ```
* **Pass Criteria:** Command fails with network unreachable error inside the container; host network remains unaffected.

---

## 5. Automated Verification Test Harness Script

To run all advanced test pillars automatically, use the automated test harness:

```powershell
# Run the complete Master Test Plan automated harness
.env\Scripts\python.exe benchmark/run_master_test_plan.py --all

# Run specific testing pillars
.env\Scripts\python.exe benchmark/run_master_test_plan.py --pillar webhooks
.env\Scripts\python.exe benchmark/run_master_test_plan.py --pillar mcp
.env\Scripts\python.exe benchmark/run_master_test_plan.py --pillar swarm
.env\Scripts\python.exe benchmark/run_master_test_plan.py --pillar remote_cluster
```

---

## 6. Continuous Integration & Quality Gates

A pull request or release candidate must satisfy all gates below before being certified:

1. **Unit Test Gate:** `cargo test --lib` -> 100% pass (0 failures).
2. **Integration Test Gate:** `cargo test --tests` -> 100% pass (0 failures).
3. **Linter & Formatting Gate:** `cargo clippy -- -D warnings` -> 0 warnings, 0 errors.
4. **Offline Benchmark Invariants:** `cargo test --test benchmarks` -> 2/2 pass.
5. **Security Scan Gate:** `bug_bounty_scan_py` in `--mode repo` -> 0 Critical / High severity findings.
6. **Master Test Plan Live Gate:** All 7 pillars in this specification validated with automated telemetry recording.
