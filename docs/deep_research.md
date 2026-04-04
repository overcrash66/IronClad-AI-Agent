# Deep Research Skill

The `deep_research` skill performs multi-phase research across configurable data sources: GitHub repositories, arXiv academic papers, and Semantic Scholar.

---

## Usage

```xml
<call_tool name="deep_research" args='{
  "topic": "transformer attention mechanisms",
  "sources": ["github", "arxiv", "semantic_scholar"],
  "max_results": 5
}'></call_tool>
```

---

## Arguments

| Argument | Type | Default | Description |
|----------|------|---------|-------------|
| `topic` | string | *(required)* | Research topic or query |
| `sources` | array | `["github"]` | Data sources: `"github"`, `"arxiv"`, `"semantic_scholar"` |
| `max_results` | integer | `5` | Maximum results per source |
| `github_token` | string | *(optional)* | GitHub personal access token for higher rate limits |

---

## Phases

### GitHub (Discovery → Triage → DeepRead → Synthesis)

Searches GitHub repositories matching the topic. Triages by stars/activity, deep-reads READMEs, and synthesizes findings.

**No API key required** for public repositories. Provide `github_token` for higher rate limits (5000 req/hr vs 60 req/hr unauthenticated).

### arXiv

Queries `api.arxiv.org/query` for academic papers matching the topic. Returns paper titles, authors, abstracts, and arXiv IDs.

**No API key required.**

Example output entry:
```
[arXiv:2310.06825] Mistral 7B — Jiang et al. (2023)
Abstract: We introduce Mistral 7B, a 7-billion-parameter language model...
```

### Semantic Scholar

Queries the [Semantic Scholar Open Research Corpus API](https://api.semanticscholar.org/) for papers with citation counts and TL;DR summaries.

**No API key required** for the public API (rate-limited to ~100 req/5min).

Example output entry:
```
[S2] Attention Is All You Need — Vaswani et al. (2017) — 90,000+ citations
TL;DR: Introduces the Transformer architecture based solely on attention mechanisms.
```

---

## Synthesis

When multiple sources are requested, results are merged into a unified synthesis covering:

1. **Code implementations** — GitHub repositories with working code
2. **Foundational papers** — arXiv preprints and Semantic Scholar results
3. **Key themes** — cross-source patterns and recurring concepts

---

## Examples

### GitHub only (default)
```xml
<call_tool name="deep_research" args='{"topic": "rust async runtime"}'></call_tool>
```

### Academic papers only
```xml
<call_tool name="deep_research" args='{
  "topic": "reinforcement learning from human feedback",
  "sources": ["arxiv", "semantic_scholar"]
}'></call_tool>
```

### Full research (all sources)
```xml
<call_tool name="deep_research" args='{
  "topic": "vector databases for RAG",
  "sources": ["github", "arxiv", "semantic_scholar"],
  "max_results": 10
}'></call_tool>
```
