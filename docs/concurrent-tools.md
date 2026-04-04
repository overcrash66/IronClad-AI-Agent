# Concurrent Tool Dispatch

IronClad's QA loop executes tool calls in **parallel** when the LLM requests multiple tools in a single turn.  This significantly reduces wall-clock time for tasks that fan out across independent operations (e.g. reading several files, running multiple searches).

## How It Works

When the LLM responds with more than one tool call in a turn the dispatcher:

1. **Notifies** the user of all pending tool calls upfront.
2. **Dispatches** all tool futures concurrently using `futures_util::future::join_all`.
3. **Waits** for all results, collecting successes and failures.
4. **Reports** any individual failures as observations while still returning successful results.
5. **File-backs** any output that exceeds 8 000 characters (see [File-Backed Output](#file-backed-output)).

```
Turn N: LLM requests [read_file("a.rs"), read_file("b.rs"), shell("cargo check")]
          │
          ├─ read_file("a.rs")  ─────────────────┐
          ├─ read_file("b.rs")  ─────────────────┤  join_all (parallel)
          └─ shell("cargo check") ───────────────┘
                                                  │
          All observations returned to LLM ◄──────┘
```

## Read-Only Parallelism

Skills that declare `is_read_only() -> bool { true }` are safe to run in parallel without ordering concerns.  Write skills (default `false`) participate in the same parallel batch but must not have data-ordering dependencies that would break under concurrent execution.

Currently read-only skills include:

- `read_file`, `list_directory`, `grep_search`, `system_info`, `list_tools`
- `search`, `browser_scrape`, `sqlite_read`, `search_history`

## File-Backed Output

Large tool outputs are automatically written to disk instead of injecting the full content into the context window.

| Threshold | Behaviour |
|-----------|-----------|
| ≤ 8 000 chars | Returned inline to the LLM |
| > 8 000 chars | Written to `.ironclad/tool_outputs/<timestamp>_<tool>.txt`; LLM receives a truncated preview and the file path |

The LLM can use the `read_file` skill to retrieve the full content when needed.

File-backed outputs reduce prompt token usage on large tool results such as full test output, large grep results, or long shell command output.

### Example

```
shell executed successfully (output too large — saved to .ironclad/tool_outputs/1718291234_shell.txt)

Preview (first 2000 chars):
running 147 tests
test audit::tests::test_audit_logger ... ok
test config::tests::test_default ... ok
...
[truncated — read .ironclad/tool_outputs/1718291234_shell.txt for full output]
```

## Performance Impact

Parallel dispatch provides the largest benefit when:

- The LLM requests 3+ independent read operations in one turn.
- Individual tool calls have non-trivial latency (network calls, WSL overhead).
- `shell` and `read_file` operations are interleaved in a single turn.

For sequential workflows (where each step depends on the previous result) the LLM naturally issues one tool call per turn and no parallelism occurs.

## Configuration

Use `max_parallel_tools` in the `[llm]` section to cap how many tool calls run concurrently in a single turn (default: `4`):

```toml
[llm]
max_parallel_tools = 4   # limit concurrent tool calls per turn
```

Setting this lower reduces peak memory and API load at the cost of higher wall-clock time for fan-out turns. Setting it higher (e.g. `8`) can improve throughput when the LLM issues many independent read operations in one turn.

To cap the total number of tool calls across an entire task, use `max_tool_calls`:

```toml
[llm]
max_tool_calls = 10   # limit overall tool call budget per task
```
