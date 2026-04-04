# How to Set Up Local Speech-to-Text (STT) for IronClad

IronClad supports local Speech-to-Text via the `LocalStt` provider. This allows you to transcribe voice messages using your own hardware, without sending audio to OpenAI.

## Prerequisites

You need a CLI tool installed on your system that:
1.  Accepts an audio file path as an argument.
2.  Outputs the transcribed text to **Standard Output (STDOUT)**.

### Option A: Whisper (Python)
The easiest way if you have Python installed.

1.  Install OpenAI Whisper:
    ```bash
    pip install -U openai-whisper
    ```
2.  Install `ffmpeg` (required by Whisper).

### Option B: Whisper.cpp (High Performance)
Faster and no Python dependency.

1.  Clone and build [whisper.cpp](https://github.com/ggerganov/whisper.cpp).
2.  Download a model (e.g., `bash ./models/download-ggml-model.sh base.en`).
3.  Build the `main` example.

---

## Configuration

You configure IronClad to use your local tool by setting the `local_stt_cmd` parameter. IronClad will replace `{input}` with the path to the temporary audio file (usually a `.ogg` file from Telegram).

### Method 1: `settings.toml`

Edit your `settings.toml` file:

```toml
[llm]
# ... other settings ...
local_stt_cmd = "whisper {input} --model base --output_format txt --fp16 False --verbose False"
```

*Note: For Python Whisper, `--output_format txt` might write to file. ensuring it prints to stdout is key. The default behavior prints to stdout.*

**Better Python Whisper Command:**
```toml
local_stt_cmd = "whisper {input} --model base --output_format txt --verbose False --fp16 False" 
```
(You might need to adjust flags to ensure mostly clean output, or use a wrapper script).

### Method 2: Environment Variable

You can set the environment variable:

```powershell
$env:IRONCLAD__LLM__LOCAL_STT_CMD = "path/to/whisper_binary -f {input} -m path/to/model.bin --no-timestamps"
```

Nested configuration env vars use the `IRONCLAD__SECTION__KEY` format.

---

## Example Wrappers

If your tool outputs extra logs (like progress bars) to STDOUT, IronClad might include them in the transcription. It's best to wrap the command to filter output if necessary.

**PowerShell Wrapper (example):**
```powershell
# transcribe.ps1
param($InputFile)
whisper $InputFile --model base --output_format txt | Select-String -Pattern "^\[" -NotMatch
```

Then config:
```toml
local_stt_cmd = "powershell -File c:/path/to/transcribe.ps1 {input}"
```
