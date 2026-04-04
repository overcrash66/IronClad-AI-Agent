# GitHub Action — IronClad Automated Tasks

IronClad ships a GitHub Actions workflow template that lets you run the agent in CI/CD pipelines via `workflow_dispatch` or a webhook.

## Template Location

```
workspace/templates/ironclad-agent.yml
```

Copy this file to `.github/workflows/ironclad-agent.yml` in your target repository.

## Workflow Overview

The workflow:

1. Checks out the repository.
2. Installs Rust and builds IronClad in release mode (cached).
3. Starts the IronClad HTTP API server in the background.
4. POSTs the task to `http://localhost:3000/task`.
5. Polls until the task is complete.
6. Optionally opens a Pull Request with any files changed by the agent.

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `task` | yes | — | The task description to hand to the agent |
| `create_pr` | no | `false` | If `true`, create a PR with agent's changes |
| `provider` | no | `anthropic` | LLM provider to use (`ollama`, `openai`, `anthropic`, `gemini`) |

## Required Secrets

Set these in **Settings → Secrets and variables → Actions**:

| Secret | Description |
|--------|-------------|
| `IRONCLAD_ANTHROPIC_KEY` | Anthropic API key (`sk-ant-...`) |
| `IRONCLAD_OPENAI_KEY` | OpenAI API key (if using OpenAI provider) |

## Usage

### Manual Dispatch

Navigate to **Actions → IronClad Agent → Run workflow** and fill in the inputs.

### Programmatic Trigger (API)

```bash
gh workflow run ironclad-agent.yml \
  --field task="Refactor the authentication module to use JWT" \
  --field create_pr=true \
  --field provider=anthropic
```

### Called from Another Workflow

```yaml
jobs:
  ai-review:
    uses: ./.github/workflows/ironclad-agent.yml
    with:
      task: "Review the PR diff and suggest improvements"
      provider: anthropic
    secrets: inherit
```

## Example: Automated Code Review

```yaml
name: AI Code Review
on:
  pull_request:
    types: [opened, synchronize]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run IronClad review
        run: |
          gh workflow run ironclad-agent.yml \
            --field task="Review the changes in this PR and post a detailed review as a GitHub comment on PR #${{ github.event.number }}" \
            --field provider=anthropic
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Customising the Workflow

### Budget

Add a session budget to prevent runaway CI jobs:

```yaml
- name: Run task
  env:
    IRONCLAD__LLM__SESSION_BUDGET_SECS: "240"
```

### Workspace Program

Drop a `program.md` in your repo to give the agent stable project-level instructions (see [program-md.md](program-md.md)):

```yaml
- name: Create program.md
  run: |
    cat > workspace/program.md <<'EOF'
    # CI Task Context
    You are running in a CI environment on branch ${{ github.ref_name }}.
    Always run `cargo test` before concluding a coding task.
    EOF
```

### Using Ollama (Self-Hosted)

For a fully self-hosted setup run Ollama as a service step:

```yaml
services:
  ollama:
    image: ollama/ollama:latest
    ports: ["11434:11434"]
```

Then set `provider: ollama` and configure `[llm.ollama]` via environment variables.

## Security Notes

- The API server only binds to `127.0.0.1` — it is not reachable from outside the runner.
- `autonomous_mode = true` is set automatically in CI so the agent can proceed without interactive approval.
- Restrict which branches/actors can trigger the workflow using GitHub's environment protection rules.
