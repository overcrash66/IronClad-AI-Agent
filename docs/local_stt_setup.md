# How to Set Up Local Speech-to-Text (STT) for IronClad

IronClad supports local Speech-to-Text via the `LocalStt` provider. This allows you to transcribe voice messages using your own hardware, without sending audio to OpenAI.

## Prerequisites

You need a CLI tool installed on your system that:
1.  Accepts an audio file path as an argument.
2.  Outputs the transcribed text to **Standard Output (STDOUT)**.

### Option A: Whisper (Python) - Recommended
The easiest way if you have Python installed. We provide a clean wrapper script in `scripts/stt_whisper.py`.

1.  Install OpenAI Whisper:
    ```bash
    pip install -U openai-whisper
    ```
2.  Install `ffmpeg` (required by Whisper).
3.  Use the provided script:
    ```toml
    [llm]
    local_stt_cmd = "python3 scripts/stt_whisper.py {input} tiny"
    ```

### Option B: Whisper.cpp (High Performance)
Faster and no Python dependency.

1.  Clone and build [whisper.cpp](https://github.com/ggerganov/whisper.cpp).
2.  Download a model (e.g., `bash ./models/download-ggml-model.sh base.en`).
3.  Build the `main` example.

---

## Configuration

You configure IronClad to use your local tool by setting the `local_stt_cmd` parameter or using the `[llm.stt]` section for OpenAI-compatible APIs.

### Method 1: Local Command (`settings.toml`)

Edit your `settings.toml` file under the `[llm]` section:

```toml
[llm]
# Recommended local script (included in repository)
local_stt_cmd = "python3 scripts/stt_whisper.py {input} tiny"

# OR use a direct binary
# local_stt_cmd = "whisper {input} --model base --output_format txt --fp16 False --verbose False"
```

### Method 2: OpenAI-Compatible API (`[llm.stt]`)

If you are running a server like `whisper.cpp` server or `LM Studio` that supports the `/v1/audio/transcriptions` endpoint:

```toml
[llm.stt]
enabled = true
base_url = "http://localhost:11434" # e.g. local server
model = "whisper-1"
api_key = "sk-..." # optional
```

### Method 3: Environment Variable

You can set the environment variable:

```powershell
$env:IRONCLAD__LLM__LOCAL_STT_CMD = "python3 scripts/stt_whisper.py {input} base"
```

---

## Troubleshooting

### Clean Output Requirement
IronClad parses the **STDOUT** of your local command as the final transcription. If your command prints extra logs, progress bars, or warnings to STDOUT, they will be included in the message. 

The provided `scripts/stt_whisper.py` handles this by suppressing internal logs and only printing the final text.
