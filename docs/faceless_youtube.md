# Faceless YouTube Video Pipeline

The **Faceless YouTube Video Pipeline** is an automated skill built into IronClad that acts as an autonomous media company. It uses several AI agents and background tools to automatically scrape trending topics, generate a script, synthesise voiceovers, find background clips, and mux it all together into a final MP4 video.

## Features

- **Trend Scraping**: Uses your local LLM (e.g. Ollama) to dynamically hallucinate high-engagement, viral topics based on your configured niche.
- **AI Scripting**: Uses your configured LLM (e.g. Ollama `qwen2.5:14b` or OpenAI) to generate an engaging, hook-heavy narrative.
- **Media Sourcing**: Searches the Pexels API for relevant B-roll clips based on script keywords.
- **Voiceover & Subtitles**: Generates TTS audio using Edge-TTS and perfectly timed subtitle `.vtt` files simultaneously.
- **Multi-language**: Can seamlessly translate the English script into other languages (e.g. French) and render localised versions of the video.
- **Automated Rendering**: Uses MoviePy and FFmpeg for final video composition.

## Prerequisites

To use this feature, you must install the Python dependencies and configure API keys.

1. **Install Python dependencies:**
The pipeline relies on a Python backend script. Ensure your virtual environment (`venv`) has the required packages:
```bash
./venv/Scripts/pip install moviepy edge-tts Pillow feedparser google-api-python-client
```

2. **Configure APIs:**
Add your Pexels API key to `.env` or `settings.toml`:
```toml
[faceless_yt]
enabled = true
# Get this from https://www.pexels.com/api/
pexels_api_key = "YOUR_API_KEY" 
```

## Configuration (`tools/pipeline_config.yaml`)

This pipeline provides deep customization via its YAML config.

```yaml
niche: "AI news"
languages: ["en", "fr"]
video_format: "16:9"  # Use "9:16" for YouTube Shorts / TikTok
output_dir: "./workspace/yt_videos"
ollama_url: "http://127.0.0.1:11434"
ollama_model: "llama3"
translation_model: "translategemma"
tts_voice_en: "en-US-GuyNeural"
tts_voice_fr: "fr-FR-HenriNeural"
```

## How to Run

### Interactive Mode
You can trigger the pipeline manually by asking IronClad:
> "Generate a faceless youtube video about the latest AI news in English and French."

IronClad will use the `faceless_yt_pipeline` skill to execute the generations.

### Autonomous Scheduling (Pulse)
Video rendering is CPU/GPU intensive. It is highly recommended to schedule this pipeline to run off-hours using the [Pulse Scheduler](pulse_scheduler.md).

> "Schedule the faceless YouTube pipeline to run every day at 3 AM for the tech niche."

The generated `.mp4`, `.mp3` background audio, and `.vtt` subtitle files will be saved in your `workspace/yt_videos` directory.
