# Experiment Loop

The **Experiment Loop** is IronClad's autonomous iterate-evaluate-keep/revert skill, inspired by Andrej Karpathy's [autoresearch](https://github.com/karpathy/autoresearch) pattern.

Given an objective and a measurable metric, it runs a fixed number of improvement iterations without human intervention:

1. A delegate sub-agent proposes and applies **one targeted change**
2. The metric command is evaluated
3. If the metric improved → the change is **kept**
4. If it did not improve → the change is **reverted** (via git)
5. Every attempt is logged to `ironclad_audit.db`

This loop can run overnight, over a lunch break, or within a strict time budget — automatically discovering what works and discarding what does not.

---

## Requirements

| Requirement | Details |
|---|---|
| **Sandbox** | WSL, Docker, or local backend must be active |
| **Git repo** | The workspace must be a git repository (used for checkpointing) |
| **`delegate_task` skill** | Must be available (registered automatically at startup) |
| **Metric command** | A shell command that prints a **numeric score** to stdout |

---

## Parameters

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `metric_command` | string | **yes** | — | Shell command whose output contains a numeric score. The last float found in stdout+stderr is used. |
| `objective` | string | no | `"improve the metric score"` | Plain-English description of what to improve. Shown to the sub-agent each iteration. |
| `max_iterations` | integer | no | `10` | Maximum number of improvement iterations (1–50). |
| `direction` | `"lower"` \| `"higher"` | no | `"lower"` | Whether a lower or higher metric value is better. |
| `time_budget_secs` | integer | no | — | Optional wall-clock budget in seconds (minimum 30). The loop stops early if this duration is exceeded. |

---

## Usage Examples

### Increase test coverage (Rust project)

> **User:** "Run the experiment loop. Metric: `cargo test 2>&1 | grep -c 'test result: ok'`, objective: increase the number of passing tests, direction: higher, max 8 iterations."

The agent will use `experiment_loop` with:
```json
{
  "metric_command": "cargo test 2>&1 | grep -c 'test result: ok'",
  "objective": "increase the number of passing tests",
  "direction": "higher",
  "max_iterations": 8
}
```

### Reduce validation loss (Python ML project)

> **User:** "Autonomously improve my model. Command: `python3 eval.py`, direction: lower, run for up to 2 hours."

```json
{
  "metric_command": "python3 eval.py",
  "objective": "reduce validation loss",
  "direction": "lower",
  "max_iterations": 50,
  "time_budget_secs": 7200
}
```

### Custom benchmark script

> **User:** "Optimise memory usage. Metric command: `python3 bench.py | tail -1`, direction: lower, 5 iterations."

```json
{
  "metric_command": "python3 bench.py | tail -1",
  "objective": "reduce peak memory consumption",
  "direction": "lower",
  "max_iterations": 5
}
```

---

## How the Metric Command Works

The `metric_command` must print a number somewhere in its output. The skill uses a flexible parser that handles all of these formats:

| Output | Parsed value |
|---|---|
| `0.8542` | `0.8542` |
| `val_bpb=0.8542` | `0.8542` |
| `Score: 93.2%` | `93.2` |
| `loss=1.2 acc=0.85` | `0.85` (last float wins) |
| `42 passed; 0 failed` | `0.0` (last float) |

The **last float** in the combined stdout+stderr is used as the score. Design your metric script to print the score as the final value on the last line.

---

## Iteration Flow

Each iteration follows this exact sequence:

```
┌─── Iteration N ──────────────────────────────────────────────┐
│                                                               │
│  1. git stash push "experiment_loop_pre_iter_N"              │
│     (checkpoint; detects if workspace was clean or dirty)    │
│                                                               │
│  2. delegate_task sub-agent runs:                            │
│     - reads current codebase                                 │
│     - proposes and applies ONE targeted change               │
│     - outputs: CHANGE_APPLIED: <description>                 │
│                  or NO_CHANGE: <reason>                       │
│                                                               │
│  3. metric_command is evaluated → new_score                  │
│                                                               │
│  4a. improved?  → git stash drop   (keep change)             │
│  4b. regressed? → git stash pop    (restore checkpoint)      │
│      (clean workspace fallback: git checkout -- . + clean)   │
│                                                               │
│  5. Result logged to ironclad_audit.db                       │
└───────────────────────────────────────────────────────────────┘
```

---

## Sample Output

```
╔═══════════════════════════════════════════╗
║          ExperimentLoop started           ║
╚═══════════════════════════════════════════╝
Objective  : increase the number of passing tests
Metric cmd : cargo test 2>&1 | grep -c 'test result: ok'
Direction  : higher is better  |  Max iterations: 5
Baseline   : 37.000000

─── Iteration 1/5 ───
  IMPROVED: 37.000000 → 39.000000  (Δ+2.000000) ✓ keeping
  Change  : CHANGE_APPLIED: Fixed off-by-one in parser boundary check

─── Iteration 2/5 ───
  No improvement: 39.000000 vs best 39.000000 — reverting

─── Iteration 3/5 ───
  IMPROVED: 39.000000 → 41.000000  (Δ+2.000000) ✓ keeping
  Change  : CHANGE_APPLIED: Added missing error handling branch in tokenizer

─── Iteration 4/5 ───
  Agent: NO_CHANGE: All obvious fixes already applied, no further improvements found

─── Iteration 5/5 ───
  No improvement: 40.000000 vs best 41.000000 — reverting

╔═══════════════════════════════════════════╗
║          ExperimentLoop Summary           ║
╚═══════════════════════════════════════════╝
Baseline     : 37.000000
Best         : 41.000000
Total delta  : +4.000000  (higher is better)
Iterations   : 2 improved / 5 total
Wall time    : 312.4s
```

---

## Audit Log

Every iteration is written to `ironclad_audit.db` with `actor = "experiment_loop"`. Each row's payload is a JSON object:

```json
{
  "iter": 3,
  "score": 0.812400,
  "baseline": 0.854200,
  "status": "improved",
  "change": "CHANGE_APPLIED: Reduced embedding dimension from 256 to 128"
}
```

**Possible `status` values:**

| Status | Meaning |
|---|---|
| `improved` | Metric moved in the desired direction; change was kept |
| `reverted` | Metric did not improve; change was reverted |
| `no_change` | Sub-agent found nothing useful to change |
| `metric_error` | Metric command failed to produce a parseable number |
| `error` | Sub-agent itself failed with an error |

To query the experiment history, ask the agent:

> "Show me all experiment_loop runs from the audit log."

Or directly via SQL using the `query_logs` skill:

```sql
SELECT timestamp, payload
FROM audit_events
WHERE actor = 'experiment_loop'
ORDER BY timestamp DESC
LIMIT 50;
```

---

## Safety & Limitations

### What the sub-agent can and cannot do
The delegate sub-agent has access to all registered skills (`file_system`, `shell_execute`, `git_ops`, etc.) but is subject to the same **Governor policy** (Traffic Light) as any other agent action. Red-classified operations (e.g., `git push`, destructive commands outside the workspace) are blocked.

### Workspace scope
The experiment loop operates within `workspace_dir` (default: `./scratchpad` or the project root if it contains `.git`). It will not read or write outside this boundary.

### Cost awareness
Each iteration makes one or more LLM calls via the delegate sub-agent. With `max_iterations=10` and a paid provider (OpenAI, Anthropic), this can use significant tokens. For long overnight runs, prefer a local provider (`ollama`) or set an explicit `time_budget_secs`.

### The metric command must be deterministic
If your metric command produces noisy output (e.g., wall-clock timing on a busy machine), the loop may incorrectly keep or revert changes. Use stable metrics: test pass counts, output scores from a fixed validation set, or line counts.

### Concurrent git operations
Do not run multiple experiment loops in the same workspace simultaneously. The git stash is shared — concurrent loops will conflict.

---

## Architecture Note

`ExperimentLoopSkill` is implemented in `src/skills/experiment_loop.rs` and registered in `src/bootstrap.rs` after `DelegateSkill`. It holds a direct `SandboxBackend` reference (for metric evaluation and git operations) and an `Arc<SkillRegistry>` reference (to dispatch `delegate_task`). It declares `delegate_task` as a dependency via `Skill::dependencies()`.
