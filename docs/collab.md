# `collab_workspace` — Multi-Instance Collaboration

Distribute a goal across peer IronClad instances over HTTP, then merge the
results back. Coordinator decomposes the goal into a DAG, fans ready nodes
out to peers, collects capped unified diffs, applies them onto a local
`agent/collab/*` branch (one commit per node), and aggregates everything
into a `[collab]` parent mission.

## Topology

- **Separate checkouts, LAN HTTP.** Each instance owns its working tree.
  The coordinator is the only writer of its own tree; subordinates work in
  place and return diffs — they never touch branches remotely.
- **Transport:** Bearer authentication using each peer's configured `api_key` (or `IRONCLAD__API__API_KEY` / `api_key` in Secrets Vault).
  Non-loopback bindings strictly require an `api_key` at startup (IronClad refuses to start on `0.0.0.0` without an explicit key). Collab endpoints (`/api/collab/*`) strictly reject unauthenticated requests with `401 Unauthorized`.

## Setup (example: Windows coordinator + Ubuntu worker)

On the **worker** (`settings.toml`):

```toml
[api]
enabled = true
port = 3000
api_key = "shared-secret"

[integrations.collab]
enabled = true
```

On the **coordinator** (`settings.toml`):

```toml
[integrations.collab]
enabled = true

[[integrations.collab.peers]]
name = "ubuntu-worker"
url = "http://192.168.1.20:3000"
key = "shared-secret"
timeout_secs = 1800   # per-node budget; node runs take minutes
```

Then open the dashboard **Collab tab**: peers show health, **Distribute Task**
starts a run, and progress is tracked on the `[collab]` parent mission
(Missions tab). Path claims are listed on the Collab tab.

## Protocol (`collab/v1`)

| Endpoint | Auth | Description |
|---|---|---|
| `GET /api/collab/health` | none | `{ok, busy, version, protocol}` |
| `POST /api/collab/tasks` | bearer | Accept a node (`protocol`, `task_id`, `goal`, `branch`, `context`, `paths`, `depth: 0`, `ttl_secs`) → `202 {task_id, status_url, protocol}` |
| `GET /api/collab/tasks/:id` | bearer | `{task_id, status, summary, diff, diff_truncated}` |
| `GET /api/collab/claims` | dashboard session | Live advisory path claims (coordinator side) |

Rules enforced by the protocol:

- `depth >= 1` is rejected — subordinates never re-delegate, so fan-out
  storms are structurally impossible.
- Diffs are capped at 512 KiB per node (larger results fail the node with
  "diff too large" instead of silently truncating).
- Node budget = peer `timeout_secs` floored at 600s, plus 120s poll grace.

## Conflict handling

1. **Isolation first**: one branch per run (`agent/collab/<task>`), one
   commit per applied node, staging exactly the diff's paths.
2. **Deterministic detection**: `git apply --check` before every apply.
3. **One automatic retry** with winner summaries appended to the node
   context; on repeat collision the node fails loudly with its diff
   attached to the milestone step for manual resolution.
4. **Claims** (`register-claim` / `heartbeat` / `release-claim` via the
   `collab` skill, auto-registered for merged paths with a 1h TTL):
   advisory locks with an audit trail and UI view; authoritative for the
   shared-filesystem topology, observational for separate checkouts.

## The `collab` skill

Available when `[integrations.collab] enabled = true`:

- `peers` — health table of configured peers.
- `claims [owner]` / `register-claim` / `heartbeat` / `release-claim` —
  advisory path locks.
- `status [limit]` — recent `[collab]` parent missions with progress.

Full distributed runs are launched from the dashboard (which owns the
orchestrator provider used for DAG decomposition).

## Limits of v1 (honest)

- Coordinator applies node diffs sequentially; there is no three-way
  merge — overlapping hunks fail the later node (with one retry).
- Inbound runs are tracked in a process-local registry: a subordinate
  restart loses in-flight runs (coordinators observe a timeout and move on).
- New untracked files transfer only when they appear in the diff (capped);
  large artifacts (build outputs, media) should use another channel.
- Peers must serve a reachable API port; there is no peer discovery —
  configure endpoints explicitly.
