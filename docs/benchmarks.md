# Benchmark Suite

IronClad includes a deterministic benchmark suite for tracking agent capability and verifying that core filesystem and structural invariants hold.  No live LLM is required — all benchmarks run offline.

---

## Running the Benchmarks

```bash
# Run all benchmark tests
cargo test --test benchmarks

# Run with printed output (recommended for local use)
cargo test --test benchmarks -- --nocapture
```

Benchmark results are written to `bench_results.json` in the project root after each run.  This file is excluded from version control (`.gitignore`).

---

## Test Functions

### `benchmark_task_definitions_are_valid`

Loads every TOML file in `tests/benchmark_tasks/` and validates:
- `id`, `tool`, `description` are non-empty strings
- `expect_contains` has at least one assertion string
- The TOML schema is well-formed (required fields present)

Fails if fewer than 10 task files are found.

### `benchmark_filesystem_reads`

Reads 10 real project files and asserts that expected content is present.  Measures total elapsed time and writes `bench_results.json`.

| File | Assertion |
|------|-----------|
| `Cargo.toml` | `[package]` |
| `settings.toml` | `default_provider` |
| `src/skills/mod.rs` | `pub trait Skill` |
| `src/error.rs` | `IronCladError` |
| `src/bootstrap.rs` | `skill_registry` |
| `src/config/llm.rs` | `LlmConfig` |
| `src/llm/qa_loop.rs` | `run_qa_loop` |
| `src/planner/dag.rs` | `DagPlan` |
| `src/api/routes.rs` | `handle_task` |
| `plans/todo-tasks.md` | `T1` |

---

## Task Definition Format (TOML)

Each task in `tests/benchmark_tasks/` follows this schema:

```toml
id = "01_file_read"
description = "Read an existing file and verify content is returned"
tool = "read_file"
args_json = '{"path": "Cargo.toml"}'
expect_contains = ["[package]"]
category = "filesystem"
```

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | Unique task identifier (e.g. `01_file_read`) |
| `description` | string | Human-readable description of what is being tested |
| `tool` | string | Skill name to invoke |
| `args_json` | string | JSON-encoded arguments for the skill |
| `expect_contains` | [string] | One or more substrings that must appear in the output |
| `category` | string | Category tag (e.g. `filesystem`, `git`, `search`) |

### Current Task Files

| File | Category | What it tests |
|------|----------|---------------|
| `01_file_read.toml` | filesystem | Read file, verify `[package]` present |
| `02_list_directory.toml` | filesystem | List directory, verify entries returned |
| `03_git_status.toml` | git | `git_ops` status, verify output non-empty |
| `04_search_code.toml` | search | `grep_search` across source files |
| `05_find_files.toml` | filesystem | `list_directory` glob patterns |
| `06_write_read_roundtrip.toml` | filesystem | Write then read a temp file |
| `07_settings_read.toml` | config | Read `settings.toml`, verify provider key |
| `08_skill_list.toml` | skills | `list_tools` returns skill catalogue |
| `09_error_types.toml` | error | `src/error.rs` defines `IronCladError` |
| `10_bootstrap_skills.toml` | skills | `src/bootstrap.rs` registers skill_registry |

---

## `bench_results.json` Schema

```json
{
  "total": 10,
  "passed": 10,
  "failed": 0,
  "elapsed_ms": 12,
  "results": [
    {
      "id": "fs_01",
      "path": "Cargo.toml",
      "passed": "true"
    }
  ]
}
```

---

## Adding New Tasks

1. Create a new TOML file in `tests/benchmark_tasks/` following the schema above.
2. Pick a unique `id` (e.g. `11_my_task`).
3. Run `cargo test --test benchmarks` to verify the new task is valid.

---

## CI Integration

The test is registered as a standard Cargo integration test and runs in CI automatically:

```yaml
- name: Run benchmark suite
  run: cargo test --test benchmarks
```

No mock LLM provider or network access is required.

---

## ExperimentLoop Integration (Future)

The benchmark suite is designed to be wired as the `metric_command` for the `experiment_loop` skill so that it can automatically track capability regression across code changes.  This integration is tracked in `plans/todo-tasks.md` as an open item under T9.
