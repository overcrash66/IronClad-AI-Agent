# program.md — Workspace Behaviour File

`program.md` is an optional Markdown file you can place in the workspace root.  Its contents are automatically prepended to every system prompt, giving the agent persistent, task-specific instructions without repeating them in every message.

Inspired by the concept of a workspace-level "persona override" in DeepAgents.

## Location

```
<workspace_dir>/program.md
```

`workspace_dir` defaults to `./workspace` and can be changed in `settings.toml`:

```toml
[general]
workspace_dir = "./workspace"
```

## How It Works

When the orchestrator builds the system prompt it reads `program.md` and, if non-empty, inserts it as a **Task Instructions** section at the top of the combined prompt:

```
<base system prompt>

---
### Task Instructions (program.md)

<contents of program.md>

<rest of system prompt (skills list, persona, etc.)>
```

The injection is silently skipped when the file is absent or empty.

## Use Cases

### Focus the Agent on a Project

```markdown
# Project: IronClad

You are working on the IronClad Rust codebase at `e:/IronClad`.

## Rules
- Always run `cargo check` before marking a coding task complete.
- Never modify files in `src/security/` without explicit confirmation.
- Use `snake_case` for all new Rust identifiers.
```

### Set Quality Gates

```markdown
## Definition of Done
A task is only complete when:
1. All tests pass (`cargo test`).
2. No new clippy warnings (`cargo clippy -- -D warnings`).
3. New public functions have doc-comments.
```

### Pre-load Context

```markdown
## Architecture Summary
The agent consists of three rings:
- **Dreamer**: LLM, no direct system access.
- **Governor**: Policy engine, Traffic Light classification.
- **Executor**: Sandbox (WSL/Docker/local).

Key files: src/bootstrap.rs, src/llm/qa_loop.rs, src/skills/mod.rs
```

### Constrain Scope

```markdown
## Out of Scope
- Do NOT modify CI/CD pipelines.
- Do NOT create new dependencies without asking the user first.
- Only work in the `src/` and `tests/` directories.
```

## Tips

- Keep it concise — the content consumes context tokens on every turn.
- Use it for *stable* instructions.  For per-session state use `write_todos`.
- You can update it mid-session; the new content will be used from the **next** turn onward.
- `program.md` instructions have higher precedence than the persona prompt because they are injected before it.
