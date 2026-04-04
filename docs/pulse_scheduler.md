# Pulse Scheduler

The **Pulse Scheduler** is IronClad's autonomous cron job system. It allows you to schedule tasks for the agent to perform automatically at specific times or intervals, even when you are not actively interacting with it.

## Features

- **Natural Language Parsing**: You don't need to know cron syntax. Tell the agent what you want in plain English (e.g., "Remind me to check the logs every hour").
- **Persistence**: Jobs are saved to `memory.db`. If you restart IronClad, the jobs are automatically reloaded and resumed.
- **Asynchronous Execution**: Jobs run in the background (`tokio::spawn`) and do not block the main application loop or the TUI.
- **Safety**: Built-in safety checks prevent the creation of highly aggressive "second-level" intervals that could spam APIs or incur high costs.

## Managing Jobs

You can manage Pulse jobs directly through conversation with the agent. The current runtime exposes a single `schedule_job` tool with `action` values of `schedule`, `list`, `delete`, and `update`.

### 1. Scheduling a Job

Simply ask the agent to schedule something:

> **User:** "Schedule a system health check every morning at 8 AM."
> 
> **Agent:** *Uses the `schedule_job` tool to parse your request into a cron expression (`0 0 8 * * *`) and creates the job.* "I have scheduled the system health check for every morning at 8:00 AM."

**Requirements for scheduling:**
- The requested task must be something the agent can actually perform independently.
- The interval must not be less than 1 minute (e.g., "do this every second" is blocked by safety checks).

### 2. Listing Jobs

If you forget what is scheduled, ask the agent:

> **User:** "What jobs are currently scheduled?"
> 
> **Agent:** *Uses the `schedule_job` tool with `action: "list"`.* "You have the following jobs scheduled: 1. System health check (ID: abc-123) - Runs daily at 08:00."

You can also view scheduled jobs via the [Web Dashboard](dashboard.md) under the "Job List" section.

### 3. Deleting Jobs

To stop a recurring task, ask the agent to cancel it:

> **User:** "Cancel the system health check job."
> 
> **Agent:** *Uses the `schedule_job` tool with `action: "delete"` and the job ID or name.* "I have cancelled the system health check job."

You can refer to the job by name or list its ID.

### 4. Updating Jobs

To change an existing job's schedule or task text, the agent uses `schedule_job` with `action: "update"`.

> **User:** "Move the nightly summary job to 11 PM instead."
>
> **Agent:** *Uses the `schedule_job` tool with `action: "update"`.* "I updated the nightly summary job to run at 23:00."

## How Jobs Execute

When a cron trigger fires:
1. The Pulse Scheduler wakes up.
2. It fetches the `job_type` payload from the database.
3. If it's an `LlmTask` (the most common type), it creates an isolated task request containing the original prompt (e.g., "Run a system health check").
4. This request is sent directly to the Orchestrator, which plans and executes the task using the connected tools and sandboxes.
5. The result (or any errors) are logged to the `ironclad_audit.db`.

## Job Types

IronClad supports the following `JobType` variants:

### `LlmTask(String)`
Runs an arbitrary natural-language task through the Orchestrator. The most common type.

```toml
# Example: ask the agent to summarize logs every night
type = "LlmTask"
prompt = "Review the past 24 hours of audit logs and summarize anomalies."
```

### `Command(String)`
Executes a raw shell command in the sandbox.

### `Maintenance`
Runs SQLite VACUUM and/or session retention cleanup.

```
Maintenance { vacuum: true, retention_cleanup: true, max_age_days: 30 }
```

### `Summarization`
Summarizes old session transcripts into structured learnings using the LLM.

```
Summarization { min_session_age_days: 7, max_sessions_per_run: 10, delete_after_summarization: false }
```

### `HealthCheck` *(new)*
Pings GitHub API and/or Ollama on a schedule. Writes a failed audit event and optionally
fires an LLM alert when a service is unreachable.

```toml
type = "HealthCheck"
check_github = true
check_ollama = true
alert_on_failure = true
```

Example — schedule a health check every 15 minutes:
> **User:** "Schedule a health check for GitHub and Ollama every 15 minutes, alert me if something is down."

The check uses a 10-second HTTP timeout for GitHub and a 5-second timeout for Ollama
(`http://localhost:11434/api/tags`).

### `LogWatch` *(new)*
Watches a log file for lines matching a regex. When a match is found the agent fires an
alert using the configured template (with `{match}` substituted by the matched lines).

```toml
type = "LogWatch"
log_file = "/var/log/ironclad/app.log"
pattern = "ERROR|PANIC|CRITICAL"
alert_template = "⚠️ IronClad detected the following log issues:\n{match}"
```

Example:
> **User:** "Watch `logs/ironclad.log` for ERROR lines every hour and send me an alert."

### `FacelessYT` *(new)*
Runs the automated Faceless YouTube Video Pipeline, compiling raw topics into finalized videos complete with TTS and subtitles. 

```toml
type = "FacelessYT"
niche = "AI news"
languages = ["en", "fr"]
format = "16:9"
upload = false
```

Example:
> **User:** "Schedule the faceless YouTube pipeline for the generic tech niche every Friday at 5 PM."

## Security & Rate Limiting

- **Cost Control**: Automated jobs use LLM tokens. If you schedule a complex task to run every 5 minutes using a paid API (like OpenAI or Anthropic), it can generate significant costs. It's recommended to use the local `Ollama` provider for high-frequency jobs.
- **Tool Sandbox**: Jobs executed by the scheduler are subject to the same Sandbox and Governor policies as interactive commands. If a scheduled job tries to run a `Red` command without pre-authorization, it will be blocked.
- **HealthCheck & LogWatch**: These job types make outbound HTTP calls and read local files. They do **not** execute LLM tasks unless `alert_on_failure` / the alert template requires it.
