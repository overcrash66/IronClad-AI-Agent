# Pi AI Coding Agent Setup Guide

This guide covers how to set up the Pi AI coding agent on Ubuntu 22.04 for use with IronClad's `AutonomousWorker` delegation.

## Prerequisites

- **Ubuntu 22.04**
- **Node.js 18+**: Pi requires a modern Node.js environment.

You can install Node.js 18.x on Ubuntu using:
```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

## Installation

Install the Pi agent globally via npm:

```bash
sudo npm install -g pi-agent
```

## Verification

To verify that Pi is installed correctly, run:

```bash
pi --version
```
You should see the installed version printed to the console.

## Environment Variables

Pi requires an API key to function. Depending on the LLM provider you use, set the appropriate environment variable.
For example, if you are using OpenAI:

```bash
export OPENAI_API_KEY="your-api-key-here"
```

If using Anthropic:
```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

Make sure to add these to your `~/.bashrc` or `~/.profile` so they persist across sessions.

## IronClad Configuration

To allow IronClad to delegate autonomous tasks to Pi via the CLI, you must ensure that `prefer_cli_delegation` is set to `true` for `JobType::AutonomousWorker`.

If you are using the default bootstrap configuration, this is already set. If defining jobs in your configuration file, make sure the field is enabled:

```json
{
  "name": "Hourly Autonomous Worker",
  "schedule": "0 0 * * * *",
  "job_type": {
    "AutonomousWorker": {
      "max_feedback_retries": 3,
      "default_task": "Evaluate open backlog tasks...",
      "prefer_cli_delegation": true
    }
  }
}
```

When this flag is `true`, IronClad will shell out to the `pi` command line utility when escalating tasks.

## Troubleshooting

- **Node version mismatch**: If `pi --version` fails with syntax errors, ensure you are running at least Node.js 18 (`node -v`).
- **Permission Denied during npm install**: Ensure you use `sudo` or configure npm to install global packages in your home directory without root permissions.
- **Command not found**: If `pi` is not recognized, make sure your global npm bin path (e.g. `/usr/local/bin` or `~/.npm-global/bin`) is in your system `$PATH`.
- **API Key Errors**: Double-check that your API key environment variable matches the exact provider name Pi expects, and is correctly exported.
