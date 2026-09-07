# Telegram Bot Integration

IronClad can be used as a conversational agent and monitoring tool via Telegram. It supports receiving tasks, providing live updates, and sending notifications for long-running autonomous background processes.

## Setup Instructions

### 1. Create a Telegram Bot
1. Search for **@BotFather** on Telegram and start a conversation.
2. Send the command: `/newbot`.
3. Follow the instructions to choose a name and username for your bot.
4. BotFather will provide an **API Token**. *Keep this secret!*

### 2. Find Your Chat ID
For security, IronClad only responds to authorized Chat IDs.
1. Start a chat with your new bot.
2. Send the message: `/id`.
3. If IronClad is not already configured, use a Telegram ID bot (like **@userinfobot**) to find your unique numeric ID.

### 3. Configure IronClad
Add your token and authorized IDs to `settings.toml` or set them as environment variables:

```toml
[integrations.telegram]
enabled = true
allowed_chat_ids = [123456789, -100987654321] # Whitelisted users/groups
trusted_chat_ids = [123456789]                # Elevated operators (Governor bypass)
verbosity = "compact"                          # "quiet" | "compact" | "verbose"
send_typing_action = true                      # Send "typing" action while working
show_tool_progress = false                     # Broadcast individual tool invocations
voice_reply = false                            # Return audio replies via TTS
```

> **Security Note on Tokens:** Store your bot token in the `.env` file or environment variable as `IRONCLAD_TELEGRAM_KEY="123456:ABC-..."` rather than committing it to version control.

### 4. Authorize Groups or Channels
To use IronClad in a group or channel:
1. Add your bot as an **Administrator**.
2. Send `/id` in the group/channel.
3. Add the resulting *negative* ID (e.g., `-100...`) to your `allowed_chat_ids` list.

## Features

### Conversational Tasks
Message your bot directly with any task:
> "Check the status of the bug bounty scans."
> "Run cargo test and let me know if everything passes."

### Verbosity & Progress Streaming
Control how much information IronClad sends during task execution:

- **`verbosity = "quiet"`** (Default): Sends only task receipts, final completions, and errors. Minimal message volume.
- **`verbosity = "compact"`**: Sends concise milestone progress messages.
- **`verbosity = "verbose"`**: Automatically broadcasts every intermediate tool execution (`🌐 Browsing...`, `💻 Running command...`, `🔬 Researching...`).
- **`send_typing_action = true`**: Sends Telegram's native "typing" status while the agent is reasoning or waiting for tool execution, giving visual feedback that work is in progress.
- **`show_tool_progress = true/false`**: Explicitly override whether intermediate tool progress notices are sent as chat messages regardless of verbosity setting.

### Autonomous Notifications
Various background skills use Telegram to notify you upon completion:
- **Faceless YouTube**: Sends a video preview and completion summary.
- **Bug Bounty**: Broadcasts findings that exceed the configured `confidence_threshold`.
- **Pulse Jobs**: Alerts you when scheduled background tasks start and finish.

### Voice Support
IronClad can process voice messages sent via Telegram. 
1. **Transcription**: Requires STT to be configured (see [STT Setup](local_stt_setup.md)).
2. **Voice Reply**: Enable `voice_reply = true` under `[integrations.telegram]` to receive audio responses (requires TTS).

**Example Configuration:**
```toml
[llm]
local_stt_cmd = "python3 scripts/stt_whisper.py {input} tiny"

[integrations.telegram]
enabled = true
allowed_chat_ids = [123456789]
trusted_chat_ids = [123456789]
verbosity = "compact"
send_typing_action = true
voice_reply = true
```

## Security & Privacy

- **Whitelist Only (`allowed_chat_ids`)**: IronClad strictly ignores any message or command from a Chat ID not explicitly listed in `allowed_chat_ids`.
- **Operator Bypass (`trusted_chat_ids`)**: Users listed in `trusted_chat_ids` are recognized as trusted operators; commands initiated by these IDs automatically pass the Governor's confirmation gate for Yellow/Red operations.
- **Data Privacy**: IronClad does not log or store messages from unauthorized users.
- **Rate Limiting**: Bot API rate limits apply (approx. 30 messages/second). For large reports, IronClad automatically splits long messages into chunks.
- **Confidence Filtering**: To prevent noise, the bug bounty scanner only triggers Telegram alerts for findings that meet your security threshold.
