# System Prompts (`src/llm/prompts.rs`)

All LLM-facing system prompt text is centralised in `src/llm/prompts.rs`.  This ensures prompt strings can be reviewed, tested, and updated without touching orchestration logic.

---

## Functions

### `build_agentic_prompt(base, time, budget, tools) -> String`

Builds the full agentic system prompt used when `agentic_mode = true` (the default).

**Parameters:**

| Parameter | Source |
|-----------|--------|
| `base` | Active persona's `system_prompt` from `personas.toml` |
| `time` | Current UTC timestamp injected at call time |
| `budget` | `max_tool_calls` from `LlmConfig` |
| `tools` | Formatted list of all registered skills |

**Prompt structure:**

```
{persona system_prompt}
Current Time: {time}

═══ AGENTIC EXECUTION PROTOCOL ═══

[Identity and capabilities declaration]

FOR EACH STEP:
1. THINK: <thought>...</thought>
2. ACT:   <call_tool name="..." args='...'></call_tool>
3. OBSERVE: tool output returned in <observation>...</observation>
4. COMPLETE: <final_answer>...</final_answer>

RULES:
- Tool budget: {budget} calls per task
- Never fabricate data
- Call ask_user alone if clarification is needed
- ...

AVAILABLE TOOLS:
{tools}

EXAMPLES: ...
```

### `build_legacy_prompt(base, time, tools) -> String`

Builds the simpler non-agentic prompt used when `agentic_mode = false`.

**Prompt structure:**

```
{persona system_prompt}
Current Time: {time}

═══ CRITICAL EXECUTION RULES ═══
1. EXECUTE, DON'T EXPLAIN
2. TOOL USAGE: {tools}
   <call_tool name="..." args='...'></call_tool>
3. ERROR RECOVERY
4. NEVER FABRICATE FACTS

EXAMPLES: ...
```

---

## How Prompts Are Assembled

The call chain in `src/llm/messaging.rs`:

1. Load persona `system_prompt` from `personas.toml` (or use the default persona).
2. If a `program.md` exists in the workspace root, prepend its contents as a *task context* block (logged with `tracing::info!`).
3. Call `build_agentic_prompt()` or `build_legacy_prompt()` based on the `agentic_mode` config flag.
4. The resulting string becomes the `system` message at position 0 in the context window.

---

## Personas

Personas are defined in `personas.toml` in the project root.  Each persona supplies the `base` prompt that `build_agentic_prompt` prepends before the execution protocol.

```toml
[personas.coder]
name = "Senior Engineer"
description = "Expert in Rust, Python, and secure coding practices."
system_prompt = """You are a Senior Software Engineer..."""
```

Select a persona at runtime:

```bash
ironclad orchestrate --task "..." --persona coder
```

Or via the API:

```json
{ "task": "...", "persona": "coder" }
```

Built-in personas: `default`, `coder`, `researcher`, `analyst`, `devops`.

---

## Customisation

### Adding a Persona

Add a new section to `personas.toml`:

```toml
[personas.security]
name = "Security Auditor"
description = "Reviews code for vulnerabilities."
system_prompt = """You are a security-focused code auditor.
Focus on OWASP Top 10, memory safety, and input validation."""
```

### project-level Instructions (`program.md`)

Drop a `program.md` file in the workspace root to inject project-specific instructions before the execution protocol on every task:

```markdown
# Project Context
This is a Rust project. Always run `cargo check` before marking a coding task done.
Never modify `Cargo.lock` directly.
```

The file is detected at runtime.  When active, you will see a log line:

```
INFO ironclad::llm::messaging: program.md active: injecting task instructions into system prompt chars=... path=...
```

### Modifying the Execution Protocol

Edit the `build_agentic_prompt` or `build_legacy_prompt` functions in `src/llm/prompts.rs`.  Re-run `cargo check` to confirm there are no compile errors.

**Guidelines for contributors:**
- Keep the `RULES` section short (each rule fits on one screen line).
- Do not remove the `<thought>` / `<call_tool>` / `<final_answer>` tag contract — the ReAct parser in `qa_loop.rs` depends on these.
- Avoid putting provider-specific instructions in `prompts.rs`; use provider config instead.
