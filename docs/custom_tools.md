# Custom Tools & Auto-Discovery

Adding your own capabilities to IronClad is as simple as placing a script into the `tools/` directory. IronClad uses a sophisticated auto-discovery mechanism to register these scripts as first-class skills or MCP (Model Context Protocol) tools.

## Supported Script Types

IronClad supports the following extensions by default:
- **Python** (`.py`)
- **PowerShell** (`.ps1`)
- **Shell Scripts** (`.sh` / `.bash`)
- **Node.js** (`.js`)

## Creating Your First Skill

### 1. Create a script in `tools/`
Create a Python script: `tools/get_weather.py`

```python
import sys
import json

def main():
    # The agent passes arguments via stdin or CLI
    location = sys.argv[1] if len(sys.argv) > 1 else "New York"
    
    # Simple logic
    result = {"location": location, "weather": "Sunny", "temp": "22C"}
    
    # Always output the final result as JSON to stdout
    print(json.dumps(result))

if __name__ == "__main__":
    main()
```

### 2. Auto-Discovery
IronClad will automatically detect `get_weather.py` and register it as a skill named `get_weather`. No restart is required for most backend configurations.

### 3. Usage
You can now ask the agent:
> "Check the weather in London."

IronClad will recognize the `get_weather` skill and execute your Python script.

## Custom Execution Commands

You can customize how scripts are called in `settings.toml`:

```toml
[tools]
python_venv_enforced = true # Always use ./venv/Scripts/python 
extensions = { "rb" = "ruby", "lua" = "lua" } 
```

## Input & Output Conventions

For your script to work seamlessly with the agent:
1. **Inputs**: The agent will pass arguments as command-line flags (e.g., `--location London`) or as a JSON string via `stdin`.
2. **Outputs**: Your script **must** print its final result as valid JSON to `stdout`.
3. **Logs**: Any human-readable logs should be sent to `stderr` to avoid polluting the JSON result.

## Example: PowerShell Skill

Create `tools/my_system_info.ps1`:
```powershell
# Get system info and return as JSON
$info = @{
    Hostname = $env:COMPUTERNAME
    OS = (Get-WmiObject Win32_OperatingSystem).Caption
    Memory = (Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB
}
$info | ConvertTo-Json
```

Once saved, the agent can use `my_system_info` to inspect your machine (subject to the [Traffic Light Policy](autonomy.md)).
