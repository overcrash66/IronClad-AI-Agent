# Automated Bug Bounty Scanning

IronClad includes a high-performance, autonomous Bug Bounty scanning pipeline designed to monitor HackerOne programs, perform deep reconnaissance, and verify findings using AI.

## Overview

The pipeline works in four stages:
1. **Discovery**: Dynamically fetches the latest programs from HackerOne or a local config.
2. **Reconnaissance**: Executes a specialized Python-based `bug_bounty_manager.py` to perform port scanning (Nmap) and service identification.
3. **AI Verification**: Sends potential findings (e.g., open risky ports, exposed services) to your configured LLM for a "false positive" check and exploitability rating.
4. **Reporting**: Generates a Markdown report and sends a Telegram notification for any finding exceeding your confidence threshold.

## Prerequisites

- **Nmap**: Must be installed and available in your system `PATH`.
- **Python Dependencies**:
  ```bash
  ./venv/Scripts/pip install reqwest scraper scraper-json
  ```
- **HackerOne Access**: If using the API, you need your API key. Otherwise, it defaults to a hardcoded list of popular programs.

## Configuration

The scanner is configured via `tools/bug_bounty_config.yaml`.

### Key Settings

| Setting | Description |
|---------|-------------|
| `programs_source` | Set to `hackerone_api`, `file`, or `hardcoded`. |
| `scan_profiles` | Define customized Nmap arguments for `quick`, `full`, or `stealth` scans. |
| `risky_ports` | List of ports that trigger an AI investigation (e.g., 21, 445, 3389). |
| `confidence_threshold` | Findings below this score (0-100) are logged but not sent to Telegram. |

### Enforcing Security

Because the scanner executes `nmap` commands, it is subject to the [Traffic Light Policy](autonomy.md). 
- Ensure `IRONCLAD__TOOLS__ALLOW_SYSTEM_COMMANDS=true` is set in your environment or `settings.toml` to allow the scanner to run.

## Usage

### Manual Trigger
Ask IronClad to start a scan:
> "Run a quick bug bounty scan on the HackerOne programs."

### Autonomous Scheduling
Use the [Pulse Scheduler](pulse_scheduler.md) to run scans periodically:
> "Schedule a full bug bounty scan every Sunday at 2 AM."

## Reports

All findings are saved in the `bug_bounty_reports/` directory as individual Markdown files. Each report includes:
- Target URL and Program Name.
- Raw Nmap output.
- LLM Verification reasoning and confidence score.
- Recommended next steps for manual exploitation or reporting.
