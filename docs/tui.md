# Terminal UI (TUI) Guide

IronClad includes a rich Terminal User Interface (TUI) for interactive chat sessions.

## Starting the TUI

To launch the TUI, run IronClad without any subcommand:

```bash
cargo run
```

The current CLI does not expose a separate `tui` subcommand. The other top-level entry points are `ironclad sessions` and `ironclad orchestrate --task "..."`.

## Interface Layout

The TUI is divided into three main sections:

1. **Header (Top)**
   - Displays the current model, persona, and sandbox backend in use.
   - Shows connection status and token usage estimates.

2. **History Pane (Middle)**
   - Displays the conversation history.
   - User messages are aligned and colored differently from Agent responses.
   - System events and tool executions are displayed inline.

3. **Input Area (Bottom)**
   - A single-line input box where you type messages and slash commands.
   - Use `/image <path>` to attach an image to the next message.
   - Displays real-time hints and status messages at the bottom border.

## Keybindings

| Keybinding | Action |
|------------|--------|
| `Enter` | Send the current message or submit the active clarification answer |
| `Esc` | Quit the TUI in the main chat view, or dismiss the active dialog |
| `Ctrl + C` | Quit the application |
| `Backspace` | Delete the previous character from the input buffer |
| `PageUp/PageDown` | Scroll chat history by 10 lines |
| `Ctrl + Up / Ctrl + Down` | Scroll chat history by 1 line |

## Slash Commands

The current TUI slash-command surface is:

- `/quit` or `/exit` — leave the TUI
- `/clear` — clear the current conversation view
- `/help` — show the built-in command help
- `/image <path>` — attach an image to the next message

## Model Selection & Routing

The TUI integrates deeply with IronClad's Orchestrator. 

- **Default Behavior**: By default, simple conversational queries sent via the TUI are routed to the `default_provider` defined in your `settings.toml`.
- **Intelligent Routing**: If `orchestrator_enabled = true` and `force_use_default_model = false`, complex tasks may be routed to a better-suited worker model.
- **Forced Default**: If you want the TUI to always stick to one execution model, set `force_use_default_model = true`. The planner may still generate a plan, but execution stays on the default provider.

## Personas

Personas are defined in `personas.toml` and are used by orchestrated tasks and session state. The current default TUI launch path does not expose a dedicated `--persona` flag.

## Agent Clarification Dialog (`ask_user`)

When the agent is executing a multi-step task and encounters an ambiguity it cannot safely resolve on its own, it pauses and surfaces a clarification dialog in the TUI. This is driven by the built-in `ask_user` skill.

The dialog overlays the History Pane and displays:

- The agent's question (e.g., *"Should I overwrite the existing output file?"*)
- A single-line input box for your answer

Type your response and press `Enter`. The agent resumes immediately with your answer injected as context, then continues until the task is complete.

Press `Esc` to dismiss the clarification dialog without providing an answer. The agent receives an empty response and continues based on the surrounding task context.

`ask_user` is automatically invoked only when the agent judges that:
1. The task is genuinely ambiguous (not just uncertain).
2. Proceeding with a wrong assumption would waste significant time or trigger an irreversible action.
