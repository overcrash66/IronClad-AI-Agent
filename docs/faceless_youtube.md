# Faceless YouTube Video Pipeline

The **Faceless YouTube Video Pipeline** is an automated skill built into IronClad that acts as an autonomous media company. It uses several AI agents and background tools to automatically scrape trending topics, generate a script, synthesise voiceovers, find background clips, and mux it all together into a final MP4 video.

## Features

- **Trend Scraping**: Uses your local LLM (e.g., Ollama) to dynamically hallucinate high-engagement, viral topics based on your configured niche.
- **AI Scripting**: Uses your configured LLM (e.g., Ollama `qwen2.5:14b` or OpenAI) to generate an engaging, hook-heavy narrative.
- **Media Sourcing**: Searches the Pexels API for relevant B-roll clips based on script keywords.
- **Voiceover & Subtitles**: Generates TTS audio using Edge-TTS and perfectly timed subtitle `.vtt` files simultaneously.
- **Multi-language**: Can seamlessly translate the English script into other languages (e.g., French) and render localised versions of the video.
- **Automated Rendering**: Uses MoviePy and FFmpeg for final video composition.
- **Configurable TTS Voices**: Choose different TTS voices per language (e.g., `en-US-JennyNeural`, `fr-FR-DeniseNeural`).
- **Optional Subtitles**: Control subtitle generation and burning independently.
- **Improved Pexels Search**: Use example topics to better match video content.

## Prerequisites

To use this feature, you must install the Python dependencies and configure API keys.

1. **Install Python dependencies:**
The pipeline relies on a Python backend script. Ensure your virtual environment (`venv`) has the required packages:
```bash
./venv/Scripts/pip install moviepy edge-tts Pillow feedparser google-api-python-client
```

2. **Configure APIs:**
Add your Pexels API key to `settings.toml`:
```toml
[faceless_yt]
enabled = true
# Get this from https://www.pexels.com/api/
pexels_api_key = "YOUR_API_KEY"
```

## Configuration (`settings.toml`)

The pipeline is now configured via `settings.toml` under the `[faceless_yt]` section. This replaces the old `tools/pipeline_config.yaml` method.

```toml
[faceless_yt]
enabled = true
pexels_api_key = "YOUR_PEXELS_KEY"

# Override LLM model for video generation (uses [llm] model if empty)
default_model = ""

# Subtitle options
generate_subtitles = true    # Generate .vtt subtitle files
burn_subtitles = true       # Burn subtitles into video (requires generate_subtitles=true)

# TTS voice options (per language)
tts_voice_en = ""        # e.g., "en-US-GuyNeural" or "en-US-JennyNeural"
tts_voice_fr = ""        # e.g., "fr-FR-HenriNeural" or "fr-FR-DeniseNeural"
tts_voice_es = ""        # Spanish voice
tts_voice_de = ""        # German voice

# Search improvement
example_topic = ""         # Topic to search for example videos on Pexels
```

### Default TTS Voices by Language

If not specified in config, these defaults are used:

| Language | Default Voice |
|-----------|---------------|
| English (`en`) | `en-US-GuyNeural` |
| French (`fr`) | `fr-FR-HenriNeural` |
| Spanish (`es`) | `es-ES-AlvaroNeural` |
| German (`de`) | `de-DE-ConradNeural` |
| Italian (`it`) | `it-IT-DiegoNeural` |
| Portuguese (`pt`) | `pt-BR-AntonioNeural` |

## CLI Arguments

When invoking via the command line or when the agent calls the skill, these arguments are supported:

| Argument | Description |
|-----------|-------------|
| `--niche "AI news"` | Content niche for trend scraping |
| `--topic "specific topic"` | Specific topic override (skips trend scraping) |
| `--languages en,fr` | Target languages (comma-separated) |
| `--format 16:9` | Video aspect ratio (`16:9` or `9:16`) |
| `--duration 180` | Target video duration in seconds |
| `--burn-subtitles` / `--no-burn-subtitles` | Burn subtitles into video |
| `--generate-subtitles` / `--no-generate-subtitles` | Generate .vtt subtitle files |
| `--tts-voice-en "en-US-JennyNeural"` | TTS voice for English |
| `--tts-voice-fr "fr-FR-DeniseNeural"` | TTS voice for French |
| `--tts-voice-es "es-ES-ElviraNeural"` | TTS voice for Spanish |
| `--tts-voice-de "de-DE-KatjaNeural"` | TTS voice for German |
| `--example-topic "artificial intelligence"` | Topic for Pexels example video search |

## How to Run

### Interactive Mode
You can trigger the pipeline manually by asking IronClad:
> "Generate a faceless youtube video about the latest AI news in English and French."

IronClad will use the `faceless_yt_pipeline_py` skill to execute the generations.

### Autonomous Scheduling (Pulse)
Video rendering is CPU/GPU intensive. It is highly recommended to schedule this pipeline to run off-hours using the [Pulse Scheduler](pulse_scheduler.md).

> "Schedule the faceless YouTube pipeline to run every day at 3 AM for the tech niche."

The generated `.mp4`, `.mp3` background audio, and `.vtt` subtitle files will be saved in your `workspace/yt_videos` directory.

## Environment Variables

For advanced configuration, these environment variables can be used (requires restart):

```bash
# LLM Configuration
IRONCLAD__FACeless_YT__DEFAULT_MODEL="qwen3.5-35b-a3b"
IRONCLAD__FACeless_YT__LLM_PROVIDER="ollama"
IRONCLAD__FACeless_YT__LLM_URL="http://127.0.0.1:11434"

# Pexels API Key
IRONCLAD__FACeless_YT__PEXELS_API_KEY="YOUR_KEY"

# Subtitle Options
IRONCLAD__FACeless_YT__GENERATE_SUBTITLES=true
IRONCLAD__FACeless_YT__BURN_SUBTITLES=true

# TTS Voices
IRONCLAD__FACeless_YT__TTS_VOICE_EN="en-US-JennyNeural"
IRONCLAD__FACeless_YT__TTS_VOICE_FR="fr-FR-DeniseNeural"

# Search Improvement
IRONCLAD__FACeless_YT__EXAMPLE_TOPIC="artificial intelligence"
```
