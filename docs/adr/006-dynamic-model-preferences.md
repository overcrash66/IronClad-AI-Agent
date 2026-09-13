# ADR-006: Dynamic Model Preferences Registry

## Title

Dynamic Model Preferences Registry with Granular 8-Pillar Benchmark Scoring

## Status

Accepted

## Context

IronClad introduced intelligent model routing via `TaskClassifier` and `select_best_model()`, which maps task archetypes (`Planning`, `Coding`, `MathReasoning`, `FastChat`, `QaReview`, `Vision`, `Security`) to the highest-performing local models discovered during the IronClad 8-Pillar Benchmark Suite.

Previously, model preferences were **hardcoded as static string pattern arrays** in `src/llm/task_classifier.rs`:

```rust
TaskArchetype::Coding => &[
    "qwen3.6-27b", "qwen3.6", "qwen3.8-27b", "qwen3.8",
    "deepseek-r1", "gemma-4-31b", "gpt-oss",
],
```

This created three distinct limitations:

1. **Portability**: Users with custom or alternative model libraries (e.g. Phi-4, Mistral-Large, Command-R+) received no archetype-aware routing benefits without editing source code.
2. **Staleness**: Incorporating newly benchmarked models required modifying code and recompiling the binary.
3. **Missed Data Reuse**: The benchmark suite generates granular per-pillar performance metrics and throughput data in `benchmark/model_leaderboard.json`, but the compiled engine could not evaluate them dynamically against live connected backends (Ollama, LM Studio, vLLM).

## Decision

We replace hardcoded pattern arrays with a **layered `ModelPreferenceRegistry`** that combines static pattern matching, user configuration overrides, and dynamic 8-pillar benchmark scoring.

### 4-Tier Preference Hierarchy

| Tier | Source | Priority | Mechanism | Mutability |
|---|---|---|---|---|
| **1** | `settings.toml` `[llm.model_preferences]` | Highest | Explicit user pattern overrides | User-editable |
| **2** | `benchmark/model_leaderboard.json` (Models) | High | Dynamic mathematical scoring across 8 benchmark pillars | Auto-generated |
| **3** | `benchmark/model_leaderboard.json` (Rankings) | Medium | Leaderboard archetype ranking patterns | Auto-generated |
| **4** | Compiled defaults (`default_patterns()`) | Baseline | Hardcoded pattern fallback | Immutable |

### 7-Step Model Selection Pipeline

When `ModelPreferenceRegistry::select_best_model()` is invoked:

1. **Vision Capability Filter**: If archetype is `Vision`, models with `caps.vision == true` are strictly prioritized.
2. **Layer 1 (User TOML Overrides)**: User-defined patterns for the archetype are evaluated first.
3. **Layer 2 (Dynamic Benchmark Scoring)**: If `model_leaderboard.json` is loaded, all available models are scored against the archetype's weighted 8-pillar formula; the highest-scoring model (> 0.0) is chosen.
4. **Layers 3 & 4 (Ranked Pattern Matching)**: Evaluates merged priority patterns (Leaderboard rankings prepended to compiled defaults).
5. **FastChat Size/Throughput Heuristic**: If archetype is `FastChat`, selects the model with the smallest parameter size (`parameter_size_b`) or highest token throughput.
6. **Default Model Fallback**: Falls back to the configured provider default model if available.
7. **First Available Model Fallback**: Final safety net returning the first candidate.

## Implementation Details

### Core Data Structures (`src/llm/model_preferences.rs`)

```rust
/// 8-Pillar benchmark scores for a single model.
#[derive(Debug, Clone, Deserialize, Serialize, Default)]
pub struct PillarScores {
    pub tool_use: f64,
    pub planning: f64,
    pub math: f64,
    pub agentic: f64,
    pub safety: f64,
    pub os_db: f64,
    pub reasoning: f64,
    pub self_heal: f64,
}

/// Evaluated model entry with benchmark scores and metadata.
#[derive(Debug, Clone, Deserialize, Serialize)]
pub struct ModelScoreEntry {
    pub name: String,
    pub key_patterns: Vec<String>,
    pub params_b: u32,
    pub quantization: Option<String>,
    pub composite_score: f64,
    pub tokens_per_sec: f64,
    pub pillar_scores: PillarScores,
}

/// Structured benchmark leaderboard data loaded from `model_leaderboard.json`.
#[derive(Debug, Clone, Deserialize, Serialize, Default)]
pub struct LeaderboardData {
    pub generated_at: Option<String>,
    pub evaluation_suite: Option<String>,
    pub total_models_evaluated: Option<usize>,
    pub models: Vec<ModelScoreEntry>,
    pub archetype_rankings: HashMap<String, Vec<String>>,
}
```

### Archetype Scoring Formulas (`calculate_archetype_score`)

- **Planning**: `0.50 * planning + 0.25 * reasoning + 0.25 * agentic`
- **Coding**: `0.40 * tool_use + 0.25 * reasoning + 0.20 * self_heal + 0.15 * os_db + size_bonus`
  *(Size bonus: +0.08 for >= 27B, +0.03 for >= 14B)*
- **MathReasoning**: `0.60 * math + 0.40 * reasoning`
- **FastChat**: `(tokens_per_sec / params).min(10.0) / 10.0` (or `1.0 / params`)
- **QaReview**: `0.50 * safety + 0.50 * self_heal`
- **Vision**: `composite_score`
- **Security**: `0.35 * os_db + 0.30 * tool_use + 0.20 * agentic + 0.15 * reasoning`

### Configuration (`settings.toml`)

```toml
[llm.model_preferences]
leaderboard_path = "benchmark/model_leaderboard.json"
coding = ["my-finetuned-coder", "qwen3.8-27b"]
planning = ["gpt-oss-20b", "deepseek-r1"]
math_reasoning = ["deepseek-r1"]
fast_chat = ["gemma-4-e4b", "qwen3.5-9b"]
qa_review = ["qwen3.8-27b"]
vision = ["qwen2.5-vl", "glm-4.6v"]
security = ["dolphin-2.9-llama3-8b", "qwen3.8-27b-uncensored"]
```

## Consequences

### Positive

- **Zero Regression**: Hardcoded patterns remain compiled defaults; if no JSON or TOML overrides exist, behavior is identical to earlier releases.
- **Dynamic Optimization**: Benchmarking new models (`benchmark/generate_leaderboard.py`) immediately improves runtime model selection without code changes.
- **Flexibility**: Users can override specific archetypes in `settings.toml` while inheriting benchmark scores for other archetypes.
- **Robust Fallbacks**: Multi-tier resolution ensures a suitable model is selected even with partial or missing model names.

### Negative

- Slight file read overhead at startup (~2–5ms) to parse `model_leaderboard.json`.
- Configuration surface increases; users must be aware of archetype keys in `settings.toml`.

### Neutral

- `TaskClassifier::classify()` remains the single source of truth for task archetype categorization.
- `TaskClassifier::select_best_model()` is superseded by `ModelPreferenceRegistry::select_best_model()` in orchestrator routing.

## Alternatives Considered

1. **Parse Markdown Leaderboard (`LM_STUDIO_MODELS_LEADERBOARD.md`) Directly**: Rejected as fragile to formatting/table changes and slower than structured JSON.
2. **LLM-Based Model Routing at Runtime**: Rejected because querying an LLM before every task introduces high latency, cost, and circular dependencies.
3. **Central Model Catalog Service**: Rejected to uphold IronClad's local-first, zero-telemetry offline operation guarantee.

## References

- `src/llm/model_preferences.rs` — Registry implementation, scoring formulas, and unit tests
- `src/llm/task_classifier.rs` — Task classifier and archetype definitions
- `src/llm/routing.rs` — Dynamic model selection integration in Orchestrator
- `docs/configuration.md` — Configuration guide for `[llm.model_preferences]`
- `benchmark/model_leaderboard.json` — 8-Pillar Leaderboard dataset
