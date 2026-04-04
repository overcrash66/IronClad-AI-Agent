# Local Execution Backend

IronClad's architecture relies on isolated Sandboxes (like Docker or WSL) to prevent the LLM ("The Dreamer") from executing malicious code directly on the host machine. However, there are scenarios where absolute isolation is not required, and performance is paramount.

For these cases, IronClad offers the `local` backend.

## What is the Local Backend?

The `Local` execution backend bypasses containerization completely. When the agent uses the `shell` tool, the command is executed natively on the host operating system using the standard library's `std::process::Command`.

### Why Use It?

1. **Maximum Speed**: Spin-up time is virtually zero compared to spinning up a Docker container or initializing WSL interactions.
2. **Host Integration**: For tasks where the agent *must* interface with local system tools (e.g., managing files natively, manipulating host services) that are inaccessible from a container.
3. **Low Memory Overhead**: Ideal for running IronClad on constrained devices (like a Raspberry Pi) where Docker adds too much overhead.

### Trade-offs: Security ⚠️

The primary tradeoff is a significant reduction in security.

By using the `local` backend, IronClad loses its "Three-Ring" isolation. If the LLM generates a malicious command and the Governor's Traffic Light policy fails to block it, the command will execute with the same privileges as the user running the IronClad application.

**Do not use the `local` backend on production servers exposed to the internet, or if you regularly copy-paste untrusted text into the prompt.**

## Configuration

To switch to the local backend, update your `settings.toml`:

```toml
[sandbox]
backend = "local"
```

## Mitigating Risk While Using Local

Even though the execution environment is no longer isolated, IronClad still enforces the Governor's Traffic Light policy.

- **Green Commands**: `ls`, `cat`, etc., will execute without prompt.
- **Red Commands**: Destructive actions like `rm`, or privilege escalations like `sudo` must still be manually confirmed by the user in the TUI or Telegram before they execute locally.

If you observe the agent frequently trying to execute commands you find risky:
1. Revoke the "trusted" status in your `personas.toml`.
2. Disable the `local` backend and switch back to `wsl` or `docker`.
