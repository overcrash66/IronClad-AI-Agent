# write_todos — Structured Task Tracking

The `write_todos` skill lets the agent maintain a persistent, structured TODO list across turns without consuming tool budget on re-reads.  Inspired by the DeepAgents `write_todos` primitive.

## Storage

TODOs are persisted as JSON at:

```
<workspace>/.ironclad/todos.json
```

The file is created automatically on the first `op=create` call.

## Operations

### `op=create` — Add a new item

| Parameter | Required | Description |
|-----------|----------|-------------|
| `content` | yes | Imperative task description, e.g. `"Fix authentication bug"` |
| `active_form` | no | Present-continuous label shown while executing, e.g. `"Fixing authentication bug"`. Defaults to `content`. |

Returns the new item's generated ID.

```json
{
  "op": "create",
  "content": "Add rate-limiting middleware",
  "active_form": "Adding rate-limiting middleware"
}
```

### `op=update_status` — Change item status

| Parameter | Required | Description |
|-----------|----------|-------------|
| `id` | yes | ID returned by `op=create` |
| `status` | yes | `"pending"`, `"in_progress"`, or `"completed"` |

```json
{
  "op": "update_status",
  "id": "3f2a1c0b",
  "status": "in_progress"
}
```

**Best practice**: mark exactly one item `in_progress` at a time. Mark it `completed` immediately after finishing. Never batch completions.

### `op=list` — Show all items

Returns a formatted list with emoji status icons:

```
⬜ [3f2a1c0b] Add rate-limiting middleware (pending)
⏳ [1a2b3c4d] Write unit tests (in_progress)
✅ [deadbeef] Update README (completed)
```

```json
{ "op": "list" }
```

### `op=clear_completed` — Remove finished items

Removes all items with `status == "completed"` and reports how many were removed.

```json
{ "op": "clear_completed" }
```

## Typical Workflow

```
1. Use op=create to add all sub-tasks at the start of a complex job.
2. Use op=update_status id=X status=in_progress when starting each task.
3. Use op=update_status id=X status=completed when done.
4. Use op=list to review remaining work.
5. Use op=clear_completed when the TODO list is cluttered.
```

## ID Format

IDs are 8-character hex strings derived from the lower 32 bits of a nanosecond timestamp.  They are unique within a session but not guaranteed globally unique.

## Example: Multi-Step Refactoring

```json
// Step 1: plan
{ "op": "create", "content": "Rename snake_case fields",      "active_form": "Renaming snake_case fields" }
{ "op": "create", "content": "Update serialization tests",    "active_form": "Updating serialization tests" }
{ "op": "create", "content": "Run cargo check",               "active_form": "Running cargo check" }

// Step 2: execute
{ "op": "update_status", "id": "aabb1122", "status": "in_progress" }
// ... do the rename ...
{ "op": "update_status", "id": "aabb1122", "status": "completed" }

{ "op": "update_status", "id": "ccdd3344", "status": "in_progress" }
// ... update tests ...
{ "op": "update_status", "id": "ccdd3344", "status": "completed" }

// Step 3: clean up
{ "op": "clear_completed" }
```

## Notes

- The skill is **not read-only** (`is_read_only = false`) and therefore cannot run concurrently with write skills in the same parallel dispatch batch.
- The `.ironclad/` directory is created automatically if it does not exist.
- The JSON file can be inspected or edited manually during debugging.
