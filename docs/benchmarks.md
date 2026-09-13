# IronClad Benchmark & Model Evaluation Suite

IronClad features a comprehensive, multi-tiered evaluation framework:
1. **Deterministic Offline Benchmark Suite**: Validates core filesystem and structural invariants without requiring a live LLM (`cargo test --test benchmarks`).
2. **Academic 8-Pillar Agent Benchmark & Matrix Evaluator**: An automated test harness (`benchmark/run_model_matrix.py` and `benchmark/run_comparative_eval.py`) that evaluates models across 8 specialized agentic domains, manages model GPU VRAM lifecycles via LM Studio's v1 API, measures planner vs worker timing metrics, and generates comparative intelligence leaderboards.

---

## 1. 8-Pillar Agent Capability Benchmark Taxonomy

The evaluation suite tests models across 8 core pillars aligned with modern AI agent evaluation standards:

| Pillar | ID | Focus & Reference Standards | Key Test Scenarios |
|---|---|---|---|
| **Pillar 1: Tool Use & Function Calling** | `pillar1_tool_use` | **BFCL v4 / ToolBench / NexusRaven** | Single/multi-tool selection, parameter schema extraction, multi-tool chaining, parallel tool dispatch, unknown tool hallucination avoidance. |
| **Pillar 2: Task Planning & DAG Decomposition** | `pillar2_planning` | **GAIA / $\tau$-bench / TravelPlanner** | Multi-phase feature DAG decomposition, dependency prerequisite ordering, dynamic replanning upon error, milestone definition of done. |
| **Pillar 3: Math Reasoning & Formal Logic** | `pillar3_math_reasoning` | **GSM8K / MATH / Theorem Proving** | Multi-step mathematical deductions, Collatz lemma formal proofs, inductive bounds, arithmetic accuracy without calculator tools. |
| **Pillar 4: Autonomous Agentic Tasks** | `pillar4_agentic_tasks` | **LiveCodeBench Hard / TerminalBench 4.0 / SWE-bench** | Complex multi-file refactoring, debugging subtle logical regressions, terminal problem solving, standalone benchmark suite filtering. |
| **Pillar 5: Safety, Governor & Red-Teaming** | `pillar5_safety` | **Agent-SafetyBench / OS-HARM / OWASP** | Privilege escalation defense (sudoers/shadow), destructive command refusal (`rm -rf /`), path traversal defense, secret exfiltration resistance, SSRF blocking, indirect prompt injection defense. |
| **Pillar 6: Multi-Turn OS & Database Ops** | `pillar6_os_database` | **AgentBench (OSBench, DBBench) / Terminal-Bench** | Multi-table SQL join & aggregation queries, system log investigation, process/port inspection, thread-safe code synthesis. |
| **Pillar 7: Reasoning, Context & Token Hygiene** | `pillar7_reasoning_hygiene` | **RULER / MultiHop-RAG / Clean Output** | Zero `<think>` token leakage, strict JSON schema contract adherence, negative constraint following, multi-hop relational reasoning. |
| **Pillar 8: Resilience & Self-Correction** | `pillar8_self_correction` | **Reflexion / InterCode / Self-Healing** | SQL syntax error recovery, fallback from failed direct reads to `grep_search`, replan budget limit adherence. |

---

## 2. Comparative Evaluation (LLM-Only vs IronClad Agent)

To isolate the concrete performance delta provided by IronClad's runtime architecture, `benchmark/run_comparative_eval.py` runs dual-mode comparative evals:
1. **Raw LLM Baseline**: Prompts the bare model directly with task context.
2. **IronClad Agent Harness**: Runs the same task through IronClad's Governor, ReAct harness, tool execution sandbox, and dynamic self-healing loop.

### Telemetry & Timing Metrics
The benchmark runner records separated execution metrics:
- `planner_duration_ms`: Total latency spent in high-reasoning planning LLM calls.
- `worker_duration_ms`: Latency spent in action execution / ReAct tool worker passes.
- `planner_requests` & `worker_requests`: Call count breakdown.
- **Pass Rate Delta**: Quantifies the percentage boost provided by IronClad's autonomous error recovery.

---

## 3. Automated LM Studio Multi-Model Matrix Evaluator

The matrix evaluator (`benchmark/run_model_matrix.py`) interfaces with LM Studio's local server (`/api/v1/models`) to automate multi-model testing without manual intervention.

### Automated Lifecycle Workflow
```
[Discover Models] ──> [Unload Previous (Free VRAM)] ──> [Load Next Model] ──> [Health Check Probe] ──> [Run 8-Pillar Suite] ──> [Record Telemetry] ──> [Generate Leaderboard]
```

### CLI Usage

IronClad provides a built-in Rust CLI subcommand that automatically locates your virtual environment and forwards parameters:

```bash
# 1. Run comparative benchmark evaluation across models
ironclad benchmark --mode comparative

# 2. Evaluate specific models and pillars
ironclad benchmark --models "qwen2.5-coder:32b,deepseek-r1:32b" --pillars "pillar1_tool_use,pillar5_safety"

# 3. Force re-testing without using cached results
ironclad benchmark --force-retest

# 4. Or invoke the Python runner directly inside your virtual environment
.\venv\Scripts\python.exe benchmark/run_comparative_eval.py
.\venv\Scripts\python.exe benchmark/run_model_matrix.py --current-model
.\venv\Scripts\python.exe benchmark/run_model_matrix.py --models "qwen,gemma,deepseek"
```

### Generated Artifacts
- **Leaderboard JSON**: `benchmark/model_leaderboard.json` (Aggregated Composite Intelligence Index scores per pillar).
- **Synthesis Report**: `benchmark/LATEST_BENCHMARKS_SYNTHESIS_REPORT.md` (Comprehensive evaluation narrative, pass rates, and archetype recommendations).
- **Comparative Report**: `benchmark/COMPARATIVE_BENCHMARK_REPORT.md` (Direct comparison of bare LLM vs IronClad Agent harness).

---

## 4. Deterministic Offline Benchmark Suite (Cargo)

No live LLM or network connection is required for offline invariant tests.

```bash
# Run all deterministic offline benchmark tests
cargo test --test benchmarks -- --nocapture
```

Benchmark results are written to `bench_results.json` in the project root.

---

## 5. Security & Zero-Leakage Policy

All evaluation harnesses and scripts adhere to strict security practices:
- All credentials and API keys are read strictly from `.env` via environment variables.
- All `.env*` files, key files (`*.pem`, `*.key`), databases (`*.db`), and raw output logs are strictly excluded from version control in `.gitignore`.
- Telemetry outputs and Markdown reports sanitize all sensitive variables and system tokens.
