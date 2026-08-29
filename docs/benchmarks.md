# IronClad Benchmark & Model Evaluation Suite

IronClad features a dual-layer evaluation framework:
1. **Deterministic Offline Benchmark Suite**: Validates core filesystem and structural invariants without requiring a live LLM (`cargo test --test benchmarks`).
2. **Academic 6-Pillar Agent Benchmark & LM Studio Matrix Evaluator**: An automated test harness (`benchmark/run_model_matrix.py`) that evaluates local LLMs across 6 specialized agentic domains, manages model memory lifecycles via LM Studio's v1 API, and generates comparative intelligence leaderboards.

---

## 1. 6-Pillar Agent Capability Benchmark Taxonomy

The comprehensive benchmark suite is structured across 6 core pillars aligned with modern 2025–2026 AI agent evaluation standards:

| Pillar | Focus & Reference Standards | Key Test Scenarios |
|---|---|---|
| **Pillar 1: Tool Use & Function Calling** | **BFCL v4 / ToolBench / NexusRaven** | Single/multi-tool selection, parameter schema extraction, multi-tool chaining, parallel tool dispatch, unknown tool hallucination avoidance. |
| **Pillar 2: Task Planning & DAG Decomposition** | **GAIA / $\tau$-bench / TravelPlanner** | Multi-phase feature DAG decomposition, dependency prerequisite ordering, dynamic replanning upon error, milestone definition of done. |
| **Pillar 3: Safety, Governor & Red-Teaming** | **Agent-SafetyBench / OS-HARM / OWASP** | Privilege escalation defense (sudoers/shadow), destructive command refusal (`rm -rf /`), path traversal defense, secret exfiltration resistance, indirect prompt injection defense. |
| **Pillar 4: Multi-Turn OS & Database Ops** | **AgentBench (OSBench, DBBench) / Terminal-Bench** | Multi-table SQL join & aggregation queries, system log investigation, process/port inspection, thread-safe code synthesis. |
| **Pillar 5: Reasoning, Context & Token Hygiene** | **RULER / MultiHop-RAG / Clean Output** | Zero `<think>` token leakage, strict JSON schema contract adherence, negative constraint following, multi-hop relational reasoning. |
| **Pillar 6: Resilience & Self-Correction** | **Reflexion / InterCode / Self-Healing** | SQL syntax error recovery, fallback from failed direct reads to `grep_search`, replan budget limit adherence. |

---

## 2. Automated LM Studio Multi-Model Matrix Evaluator

The matrix evaluator (`benchmark/run_model_matrix.py`) interfaces with LM Studio's local server (`/api/v1/models`) to automate multi-model testing without manual intervention.

### Automated Lifecycle Workflow
```
[Discover Models] ──> [Unload Previous (Free VRAM)] ──> [Load Next Model] ──> [Health Check Probe] ──> [Run 6-Pillar Suite] ──> [Record Telemetry] ──> [Generate Leaderboard]
```

### CLI Usage

```bash
# 1. Run all 6 pillars against the currently loaded LM Studio model
.\venv\Scripts\python.exe benchmark/run_model_matrix.py --current-model

# 2. Run dry-run validation (checks discovery, suites, and prompt schemas without LLM inference)
.\venv\Scripts\python.exe benchmark/run_model_matrix.py --dry-run

# 3. Evaluate specific models by name/pattern
.\venv\Scripts\python.exe benchmark/run_model_matrix.py --models "qwen,gemma,deepseek"

# 4. Filter by specific test pillars (e.g. Tool Calling & Safety only)
.\venv\Scripts\python.exe benchmark/run_model_matrix.py --models "qwen3.8-27b" --pillars "pillar1_tool_use,pillar3_safety"

# 5. Route through IronClad Protected Gateway (:3000) for Three-Ring Governor validation
.\venv\Scripts\python.exe benchmark/run_model_matrix.py --current-model --gateway
```

### Generated Artifacts
- **Telemetry JSON**: `benchmark/results/matrix_eval_<timestamp>.json` (Contains per-turn latency ms, tokens/sec, prompt/completion tokens, assertion details).
- **Academic Leaderboard Report**: `benchmark/LM_STUDIO_MODELS_LEADERBOARD.md` (Ranks all models by Composite Intelligence Index, granular pillar scorecards, and deployment recommendations).

---

## 3. Deterministic Offline Benchmark Suite (Cargo)

No live LLM or network connection is required for offline invariant tests.

```bash
# Run all deterministic offline benchmark tests
cargo test --test benchmarks -- --nocapture
```

Benchmark results are written to `bench_results.json` in the project root.

---

## 4. Security & Zero-Leakage Policy

All evaluation harnesses and scripts adhere to strict security practices:
- All credentials and API keys are read strictly from `.env` via environment variables.
- All `.env*` files, key files (`*.pem`, `*.key`), databases (`*.db`), and raw output logs are strictly excluded from version control in `.gitignore`.
- Telemetry outputs and Markdown reports sanitize all sensitive variables and system tokens.

