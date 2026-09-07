# IronClad Autonomy Subsystem

The IronClad autonomous agent architecture relies on several interconnected Subsystems and Skills to achieve continuous autonomous operations:

## The Pulse Scheduler
The `Pulse` mechanism acts as the heartbeat of the agent. It leverages a cron-like scheduler (`tokio-cron-scheduler`) combined with persistent storage (SQLite) to wake the agent up and perform tasks automatically.
- **LlmTask**: Free-form scheduled goals.
- **Command**: Periodic system commands executed on the host.
- **Maintenance**: Auto-vacuuming or housekeeping.

## Cross-Agent Delegation
IronClad supports spawning sub-agents recursively via the `delegate_task` skill. Sub-agents are sandboxed in their own conversation state and report back an execution result, allowing complex trees of work to execute simultaneously.

## Security Controls (Governor)
Because the agent can schedule its own tasks, the `Governor` provides a static sandbox boundary to prevent destructive loops. System commands and SQL injections are blocked dynamically, while file modifications are constrained based on read-only policies.