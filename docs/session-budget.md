# Session Budget

The `session_budget_secs` setting imposes a wall-clock time limit on a single QA-loop session.  When the elapsed time since the first loop iteration reaches the budget the agent exits gracefully and returns the best answer accumulated so far rather than continuing to retry or call more tools.

## Configuration

In `settings.toml`:

```toml
[llm]
session_budget_secs = 600   # 10-minute hard limit
```

Omit the field (or set it to `0`) to disable the budget entirely (default behaviour).

### Field Reference

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `session_budget_secs` | integer or null | `null` (disabled) | Wall-clock seconds before the loop exits gracefully |

### Environment Variable Override

```bash
export IRONCLAD__LLM__SESSION_BUDGET_SECS=300
```

## How It Works

Each iteration of the QA loop checks three exit conditions in order:

1. **Loop timeout** (`loop_timeout_secs`) — hard retry-level timeout (default 300 s).
2. **Session budget** (`session_budget_secs`) — wall-clock budget measured from the first iteration.
3. **Max tool calls** (`max_tool_calls`) — absolute tool call count limit.

When the session budget is exceeded the loop returns the most recent assistant response (or an informational message if no response has been received yet) and emits a log warning:

```
Session budget of 600s exceeded after 601s — returning best-effort answer
```

## Difference from `loop_timeout_secs`

| Setting | Scope | Resets on retry? |
|---------|-------|-----------------|
| `loop_timeout_secs` | Per retry attempt | Yes |
| `session_budget_secs` | Entire session from first iteration | No |

Use `loop_timeout_secs` to cap individual retry attempts; use `session_budget_secs` as a fail-safe ceiling for a whole task.

## Recommended Values

| Use Case | `session_budget_secs` |
|----------|----------------------|
| Interactive chat | disabled (null) |
| Simple coding task | 120–300 |
| Complex multi-step task | 600–1800 |
| CI/CD automation | 300 (match CI job timeout) |
| Experiment loop | set via `ExperimentLoopSkill.time_budget_secs` instead |

## Example: CI/CD Pipeline Budget

```toml
[llm]
turbo_mode = true
session_budget_secs = 240   # 4-minute CI budget
max_tool_calls = 20
```

This ensures the IronClad process always terminates before a typical CI job times out.
