# ADR 005: Native Tool Calling vs XML Tool Calling

## Status

Accepted

## Context

IronClad originally relied on an XML-based convention for tool use: the LLM was prompted to
emit `<tool_call name="..."><arg name="...">…</arg></tool_call>` blocks, which were
then extracted from the raw text response using a regex parser (`tool_parser.rs`).

This approach has several drawbacks:

1. **Reliability** — The model can hallucinate malformed XML or forget the convention
   entirely, causing silent failures or missed tool invocations.
2. **Prompt bloat** — Every system prompt includes a sizeable XML-schema section that
   reduces the effective context window available for actual task content.
3. **Latency** — The model must serialise tool calls as plain text then IronClad must
   parse that text, adding a full round-trip before results are returned.
4. **Lost semantics** — Some providers (OpenAI, Anthropic) natively support multi-tool
   invocation in a single response and structured streaming. These capabilities are not
   accessible through the XML path.

## Decision

Introduce a **dual-path tool calling architecture**:

- Every `ModelProvider` implementation may override `supports_native_tools() → bool`
  (default `false`) and `send_with_tools(messages, tool_defs) → NativeResponse`.
- OpenAI and Anthropic implementations return `true` and dispatch to their respective
  function-calling / tool_use APIs.
- The agentic ReAct loop in `qa_loop.rs` checks `supports_native_tools()` before each
  iteration:
  - **Native path**: calls `send_with_tools()`, receives structured `ToolCall` objects
    with an `id` field, no XML parsing required.
  - **Legacy path**: calls the existing `send()` method and parses XML from the text
    response (unchanged).
- The `MatchedFormat` enum gains a `Native` variant so downstream telemetry and logging
  can distinguish the two paths.
- A new helper `build_native_tool_defs()` on `Orchestrator` converts the live skill
  registry into `Vec<NativeToolDef>` on each turn, keeping tool definitions always in
  sync with registered skills.

## Consequences

**Positive:**
- Higher tool-invocation accuracy for OpenAI and Anthropic providers.
- Shorter effective system prompts (XML schema section can be omitted for native-capable
  models).
- Unlocks parallel tool calls in a single response (already supported by both providers).
- Structured `id` field enables correct multi-turn tool-result messages required by both
  APIs.

**Negative / trade-offs:**
- Additional code paths increase test surface.
- Ollama, local, and custom providers still use the XML path until they are individually
  updated to declare `supports_native_tools() → true`.
- The `ToolCall` struct now carries an optional `id` field that is `None` on the XML path;
  consumers must handle both cases.

## Alternatives Considered

| Alternative | Reason not chosen |
|-------------|-------------------|
| Always use XML even for OpenAI/Anthropic | Foregoes reliability and latency improvements |
| Force all providers to use a JSON extraction prompt | Still text-based; not as reliable as first-class API support |
| Use a third-party `tool_call` crate | Added dependency; nontrivial to integrate with async provider trait |
| Drop XML path entirely | Too many local/custom providers rely on it |

## References

- [OpenAI Function Calling docs](https://platform.openai.com/docs/guides/function-calling)
- [Anthropic Tool Use docs](https://docs.anthropic.com/en/docs/build-with-claude/tool-use)
- `src/llm/mod.rs` — `NativeToolDef`, `NativeResponse`, `ModelProvider` trait
- `src/llm/openai.rs` — OpenAI implementation
- `src/llm/anthropic.rs` — Anthropic implementation
- `src/llm/qa_loop.rs` — dual-path ReAct loop
