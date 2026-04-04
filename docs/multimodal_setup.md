# Multimodal Setup Guide

IronClad supports multimodal interactions, allowing the agent to process images alongside text. This guide explains how to configure and use these features.

## 1. Prerequisites

- **Ollama**: Ensure you have [Ollama](https://ollama.com/) installed and running.
- **Vision Model**: Pull a vision-capable model. Common choices include:
    - `llava` (Llava v1.5/v1.6)
    - `moondream` (Small, fast)
    - `llama3.2-vision` (if available)

Run the following command in your terminal to pull a model:
```bash
ollama pull llava
```

## 2. Configuration (`settings.toml`)

To enable vision support for Ollama, you must update your `settings.toml` file.

1.  Locate the `[llm.ollama]` section.
2.  Set the `model` to your vision model (e.g., `llava`).
3.  Add `vision = true`.

Example `settings.toml`:

```toml
[llm]
default_provider = "ollama"
orchestrator_enabled = true

[llm.ollama]
base_url = "http://127.0.0.1:11434"
model = "llava"          # Default execution model
vision = true            # Mark the default model as vision-capable
planner_model = "llama3" # Optional planner used only for routing
```

**Planner Model**: 
If your primary model (for example `llava`) is good at vision but weak at routing decisions, set `planner_model` to a stronger reasoning model such as `llama3` or `mistral`. IronClad uses `planner_model` only for the routing decision; the selected worker model still comes from the discovered model list.

## 3. Usage

Once configured, restart IronClad. You can now send images to the agent via:
- **Telegram**: Upload an image with a caption.
- **TUI**: Use `/image <path>` and then send your prompt.
- **HTTP API**: Submit `images` alongside the task payload as base64 strings.

## 4. Verification

To verify that vision is working:
1.  Run IronClad in TUI or Telegram mode.
2.  Send an image.
3.  Ask "What is in this image?".
4.  The agent should describe the image content using the configured vision model.

## 5. Multiple Models (Advanced)

The Orchestrator automatically detects all models available in your local Ollama instance. To make use of this feature:

1.  **Pull Multiple Models**:
    Install the models you want to use. For example:
    ```bash
    ollama pull llama3:latest      # General reasoning
    ollama pull llava:latest       # Vision
    ollama pull codellama:latest   # Coding
    ```

2.  **Automatic Routing**:
    When you send a task with attached images through the TUI, Telegram, or the HTTP API, IronClad will:
    -   Scan your installed Ollama models.
    -   Identify which models support vision (e.g., `llava`, `moondream`).
    -   Select the best model for the specific task description.
    -   Route the execution to that model automatically.

    **Note**: The model in `[llm.ollama].model` remains the default execution model. If `planner_model` is set, IronClad uses that separate model for routing; otherwise it falls back to the primary provider for routing decisions.

