# Dynamic Plugin Subsystem

IronClad provides a high-performance, enterprise-grade dynamic plugin subsystem ([`src/plugin.rs`](../src/plugin.rs)) that enables developers to extend the AI agent with native dynamic libraries (`.dll`, `.so`, `.dylib`) or statically registered in-process plugins.

Native plugins integrate seamlessly into IronClad's [`SkillRegistry`](../src/skills/mod.rs), allowing LLMs to discover and invoke plugin tools alongside built-in capabilities, while enforcing strict Governor security policies, cryptographic integrity checks, and panic safety.

---

## Plugins vs. Script Tools

IronClad supports two complementary ways to add custom capabilities:

| Feature | Script Tools (`tools/`) | Dynamic Plugins (`plugins/`) |
| :--- | :--- | :--- |
| **Technology** | Interpreted Python, PowerShell, Bash, Node.js | Native compiled binaries (`.dll`, `.so`, `.dylib`) or Rust crates |
| **Execution** | Spawned as external child processes | Executed in-process via ABI symbols with sub-millisecond overhead |
| **Security** | Process-level isolation and Governor CLI inspection | Governor `TrafficLight` policies + deep parameter security scanning |
| **Integrity** | Filesystem permissions | SHA-256 cryptographic verification (`checksums.json`) |
| **Fault Isolation** | OS process isolation | `std::panic::catch_unwind` panic boundaries |
| **Best For** | Fast prototyping, administrative scripts, data tasks | Performance-critical engines, native hardware drivers, proprietary modules |

---

## Configuration

Enable and configure the plugin subsystem in `settings.toml`:

```toml
[plugins]
# Enable or disable the native dynamic plugin subsystem
enabled = true

# Path to the directory containing dynamic library binaries
directory = "./plugins"

# Strict cryptographic integrity gating
# When true, binaries missing from checksums.json will be rejected
strict_checksums = false

# Automatically watch the plugins directory and hot-reload binaries on change
hot_reload = true
```

---

## Cryptographic Integrity Verification

To protect against untrusted binaries or tampering, IronClad supports cryptographic SHA-256 verification.

Place a `checksums.json` file inside your configured plugins directory (e.g. `./plugins/checksums.json`):

```json
{
  "libimage_processor.so": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  "native_math.dll": "a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e"
}
```

### Verification Behavior
- **Permissive Mode (`strict_checksums = false`)**: If a binary is present in `checksums.json`, its SHA-256 checksum is strictly verified using constant-time comparison. If absent, it is loaded with an advisory warning.
- **Strict Mode (`strict_checksums = true`)**: Any binary not explicitly listed with a matching SHA-256 hash in `checksums.json` is rejected immediately (`PluginError::UntrustedBinary`).

---

## Governor Security & Traffic Light Policies

Every tool exposed by a plugin can specify its Governor [`TrafficLight`](../src/governor/policy.rs) policy:

| Policy | Behavior |
| :--- | :--- |
| `TrafficLight::Green` | Safe, read-only operations — auto-approved by the agent loop. |
| `TrafficLight::Yellow` | Potentially impactful operations — user is notified. |
| `TrafficLight::Red` | Mutating or dangerous operations — requires user confirmation. |
| `TrafficLight::Blocked` | Forbidden operations — strictly rejected by the Governor before execution. |

### Automatic Parameter Security Scanning
Before any plugin tool executes, IronClad automatically analyzes the incoming JSON arguments:
- **Directory Traversal**: Rejects paths containing `../`, `..\\`, or parent directory escapes.
- **Secret & Credential Protection**: Rejects arguments referencing sensitive locations such as `.env`, `secrets/`, `id_rsa`, or private keys.

---

## Building an IronClad Native Plugin

### 1. Create a Cargo Crate

Initialize a new library crate:

```bash
cargo new --lib ironclad_sample_plugin
cd ironclad_sample_plugin
```

Configure `Cargo.toml` to produce a C-compatible dynamic library:

```toml
[package]
name = "ironclad_sample_plugin"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
```

### 2. Implement the Plugin Trait

Create your plugin implementation in `src/lib.rs`:

```rust
use serde_json::{json, Value};
use std::collections::HashMap;

pub struct SamplePlugin;

impl SamplePlugin {
    pub fn new() -> Self {
        Self
    }
}

// Implement IronClad's plugin ABI
impl SamplePlugin {
    pub fn name(&self) -> &'static str {
        "sample_plugin"
    }

    pub fn on_load(&mut self) -> Result<(), String> {
        println!("[SamplePlugin] Initialized successfully.");
        Ok(())
    }

    pub fn on_unload(&mut self) -> Result<(), String> {
        println!("[SamplePlugin] Unloaded cleanly.");
        Ok(())
    }

    pub fn execute(&self, action: &str, params: Value) -> Result<Value, String> {
        match action {
            "fast_add" => {
                let a = params.get("a").and_then(|v| v.as_i64()).unwrap_or(0);
                let b = params.get("b").and_then(|v| v.as_i64()).unwrap_or(0);
                Ok(json!({ "result": a + b }))
            }
            _ => Err(format!("Unknown action: {}", action)),
        }
    }
}

// Export the native entrypoint symbol
#[no_mangle]
pub extern "C" fn ironclad_plugin_entrypoint() -> *mut SamplePlugin {
    Box::into_raw(Box::new(SamplePlugin::new()))
}
```

### 3. Compile the Dynamic Library

Compile for release:

```bash
cargo build --release
```

The resulting library will be located in:
- **Windows**: `target/release/ironclad_sample_plugin.dll`
- **Linux**: `target/release/libironclad_sample_plugin.so`
- **macOS**: `target/release/libironclad_sample_plugin.dylib`

### 4. Deploy to IronClad

Copy the binary into your IronClad `plugins/` directory:

```bash
mkdir -p plugins
cp target/release/libironclad_sample_plugin.so plugins/
```

If `hot_reload = true` is set, IronClad detects the new file instantly, loads the library, performs cryptographic validation, and registers the tools into the agent's active registry.

---

## Fault Isolation & Panic Safety

IronClad guarantees that faulty or crashing third-party plugins cannot crash the host agent process. 

Every tool call is wrapped inside an `std::panic::catch_unwind` boundary. If a plugin triggers a panic (such as an out-of-bounds array access or unwrap on None):
1. The panic is intercepted safely at the host boundary.
2. The plugin's status is transitioned to `PluginStatus::Error`.
3. An informative `IronCladError::ToolExecutionFailed` error is returned to the agent ReAct loop.
4. The agent can replan or report the tool failure to the user without process termination.
