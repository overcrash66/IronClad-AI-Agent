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
# Use environment variables for secrets (recommended)
# token = "YOUR_BOT_TOKEN_FROM_BOTFATHER" 
allowed_chat_ids = [123456789, -100987654321] # Positive IDs for users, negative for groups/channels
```

### 4. Authorize Groups or Channels
To use IronClad in a group or channel:
1. Add your bot as an **Administrator**.
2. Send `/id` in the group/channel.
3. Add the resulting *negative* ID (e.g., `-100...`) to your `allowed_chat_ids` list.

## Features

### Conversational Tasks
Message your bot directly with any task:
> "Check the status of the bug bounty scans."

### Autonomous Notifications
Various background skills use Telegram to notify you upon completion:
- **Faceless YouTube**: Sends a video preview and completion summary.
- **Bug Bounty**: Broadcasts findings that exceed the configured `confidence_threshold`.
- **Pulse Jobs**: Alerts you when scheduled background tasks start and finish.

## Security & Privacy

- **Whitelist Only**: IronClad will ignore any message from a Chat ID not in `allowed_chat_ids`.
- **Data Privacy**: IronClad does not log or store messages from unauthorized users.
- **Rate Limiting**: Bot API rate limits apply (approx. 30 messages/second). For large reports, IronClad automatically splits long messages into chunks.
- **Confidence Filtering**: To prevent noise, the bug bounty scanner only triggers Telegram alerts for findings that meet your security threshold.
