# RAG Knowledge Base

IronClad's RAG (Retrieval-Augmented Generation) system indexes your workspace code into a local vector database, enabling the AI to retrieve highly relevant codebase context before answering questions or making changes.

## Overview

### What is RAG?

RAG combines the power of large language models with a retrieval system that can search through your actual codebase. Instead of relying solely on the LLM's training data, IronClad can now access and reference your specific code, reducing hallucinations and improving accuracy.

### Benefits

- **Reduced Hallucinations**: The AI has access to actual code, reducing made-up information
- **Better Code Understanding**: Understands project structure, patterns, and conventions
- **Privacy-Preserving**: All indexing and retrieval happens locally
- **Configurable**: Enable/disable and tune to your needs
- **Automatic Updates**: File watcher keeps the index in sync with code changes

### How It Works

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│   File Watcher │────▶│  Code Parser   │────▶│   Chunker      │
│  [Background]  │     │  [Tree-sitter] │     │  [Semantic]    │
└────────────────┘     └────────────────┘     └───────┬────────┘
                                                       │
                                                       ▼
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│  Orchestrator  │────▶│  RAG Skill     │────▶│  Embedding     │
│  [Auto-query]  │     │[query_knowledge_base]│  [Ollama/Cloud]│
└────────────────┘     └───────┬────────┘     └───────┬────────┘
                               │                      │
                               ▼                      ▼
                      ┌─────────────────────────────────────┐
                      │         Vector Store                 │
                      │   [In-memory with persistence]       │
                      └─────────────────────────────────────┘
```

1. **Indexing**: Code files are parsed into semantic units (functions, classes, modules)
2. **Embedding**: Each unit is converted to a vector representation
3. **Storage**: Vectors are stored in a local database
4. **Retrieval**: Queries are matched against stored vectors for relevance
5. **Context Injection**: Relevant code is injected into the LLM prompt

## Quick Start

### 1. Enable RAG

Add to your `settings.toml`:

```toml
[rag]
enabled = true
```

### 2. Install an Embedding Model

For Ollama (recommended):

```bash
ollama pull nomic-embed-text
```

### 3. Restart IronClad

The workspace will be automatically indexed on startup.

### 4. Verify

Ask a question about your codebase:

```
> What function handles user authentication?
```

The AI will now have access to relevant code context when answering.

## Configuration

### Basic Configuration

```toml
[rag]
enabled = true
embedding_provider = "ollama"
embedding_model = "nomic-embed-text"
chunk_size = 512
chunk_overlap = 50
max_results = 10
min_similarity = 0.7
```

### All Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable or disable RAG functionality |
| `db_path` | string | `".ironclad/vectors"` | Vector database path |
| `embedding_provider` | string | `"ollama"` | Provider: "ollama", "openai", "nvidia" |
| `embedding_model` | string | `"nomic-embed-text"` | Model name for embeddings |
| `chunk_size` | number | `512` | Target chunk size in tokens (100-4000) |
| `chunk_overlap` | number | `50` | Overlap between chunks in tokens |
| `max_results` | number | `10` | Maximum chunks to retrieve (1-50) |
| `min_similarity` | number | `0.7` | Minimum similarity threshold (0.0-1.0) |
| `include_patterns` | [string] | `["**/*.rs", ...]` | Glob patterns for files to include |
| `exclude_patterns` | [string] | `["**/target/**", ...]` | Glob patterns for files to exclude |
| `auto_index` | boolean | `true` | Auto-index workspace on startup |
| `watch_changes` | boolean | `true` | Watch for file changes |
| `watch_debounce_ms` | number | `1000` | Debounce interval for file changes |
| `max_file_size_kb` | number | `500` | Maximum file size to index |
| `auto_inject_context` | boolean | `true` | Auto-inject context into prompts |
| `max_context_tokens` | number | `2000` | Maximum tokens of context to inject |

### Environment Variables

All settings can be overridden via environment variables with the `IRONCLAD__RAG__` prefix:

```bash
# Enable/disable RAG
IRONCLAD__RAG__ENABLED=true

# Embedding configuration
IRONCLAD__RAG__EMBEDDING_PROVIDER=ollama
IRONCLAD__RAG__EMBEDDING_MODEL=nomic-embed-text

# Retrieval settings
IRONCLAD__RAG__MAX_RESULTS=15
IRONCLAD__RAG__MIN_SIMILARITY=0.75

# File patterns (comma-separated)
IRONCLAD__RAG__INCLUDE_PATTERNS="**/*.rs,**/*.py,**/*.md"
IRONCLAD__RAG__EXCLUDE_PATTERNS="**/target/**,**/node_modules/**"
```

## Embedding Model Selection

### Ollama (Recommended for Local)

Local embeddings using Ollama provide privacy and no API costs.

**Available Models:**

| Model | Dimensions | Best For |
|-------|------------|----------|
| `nomic-embed-text` | 768 | General purpose, good balance |
| `all-minilm` | 384 | Fast, lightweight |
| `mxbai-embed-large` | 1024 | High quality, larger codebases |

**Configuration:**

```toml
[rag]
embedding_provider = "ollama"
embedding_model = "nomic-embed-text"
```

**Setup:**

```bash
# Pull the embedding model
ollama pull nomic-embed-text

# Verify it works
ollama run nomic-embed-text "Hello world"
```

### OpenAI (Cloud)

Higher quality embeddings with API costs.

**Available Models:**

| Model | Dimensions | Cost (per 1M tokens) |
|-------|------------|---------------------|
| `text-embedding-3-small` | 1536 | $0.02 |
| `text-embedding-3-large` | 3072 | $0.13 |

**Configuration:**

```toml
[rag]
embedding_provider = "openai"
embedding_model = "text-embedding-3-small"
```

**Setup:**

```bash
# Set API key
export IRONCLAD_OPENAI_KEY="sk-..."
```

### NVIDIA NIM (Cloud)

High-quality embeddings via NVIDIA NIM API.

**Available Models:**

| Model | Dimensions | Best For |
|-------|------------|----------|
| `nvidia/nv-embedqa-e5-v5` | 1024 | Question answering |
| `nvidia/llama-3.2-nv-embedqa-1b-v2` | 2048 | Large-scale retrieval |

**Configuration:**

```toml
[rag]
embedding_provider = "nvidia"
embedding_model = "nvidia/nv-embedqa-e5-v5"
```

**Setup:**

```bash
# Set API key
export IRONCLAD_NVIDIA_KEY="nvapi-..."
```

## Performance Tuning

### Chunk Size

The `chunk_size` parameter controls how code is split:

- **Smaller (256-512)**: More granular retrieval, better for finding specific functions
- **Larger (1024-2048)**: More context per result, better for understanding larger patterns

```toml
# For finding specific functions
chunk_size = 256
chunk_overlap = 25

# For understanding architecture
chunk_size = 1024
chunk_overlap = 100
```

### Retrieval Settings

- **`max_results`**: Number of chunks to retrieve (1-50)
  - Higher = more context, but slower and more tokens
  - Lower = faster, but may miss relevant code

- **`min_similarity`**: Minimum similarity threshold (0.0-1.0)
  - Higher (0.8+) = only very relevant results
  - Lower (0.5-0.7) = broader results, may include noise

### Memory Optimization

For large codebases:

```toml
[rag]
max_file_size_kb = 200  # Skip large files
exclude_patterns = [
    "**/target/**",
    "**/node_modules/**",
    "**/.git/**",
    "**/dist/**",
    "**/build/**",
    "**/vendor/**",
    "**/__pycache__/**",
    "**/*.min.js",
    "**/*.lock"
]
```

### Indexing Speed

- **Disable auto-index** for faster startup:
  ```toml
  auto_index = false
  ```

- **Disable file watching** to reduce background CPU:
  ```toml
  watch_changes = false
  ```

- **Increase debounce** to batch more changes:
  ```toml
  watch_debounce_ms = 5000  # 5 seconds
  ```

## Usage Examples

### Querying the Knowledge Base

The RAG skill is automatically available when enabled:

```json
{
  "name": "query_knowledge_base",
  "arguments": {
      "action": "query",
    "query": "function to parse JSON",
      "limit": 10,
    "language_filter": "rust"
  }
}
```

### Automatic Context Injection

When `auto_inject_context` is enabled, relevant code is automatically added to the system prompt:

```
═══════════════════════════════════════════════════════════════
RELEVANT CODEBASE CONTEXT:
═══════════════════════════════════════════════════════════════
[src/parser.rs:45-67] fn parse_json(input: &str) -> Result<Value>
[src/json_utils.rs:12-34] fn validate_json_schema(value: &Value)
═══════════════════════════════════════════════════════════════
```

### Manual Reindexing

To force a reindex of the workspace:

```json
{
   "name": "query_knowledge_base",
   "arguments": {
      "action": "index",
      "reindex": true
   }
}
```

Or delete the vector database and restart:

```bash
rm -rf .ironclad/vectors
```

## Troubleshooting

### Index Not Building

**Symptoms**: No results from queries, "RAG is disabled" message

**Solutions**:

1. Verify RAG is enabled:
   ```toml
   [rag]
   enabled = true
   ```

2. Check the embedding model is available:
   ```bash
   ollama list | grep nomic
   ```

3. Check logs for errors:
   ```bash
   IRONCLAD_LOG=debug ironclad
   ```

4. Verify file patterns match your files:
   ```toml
   include_patterns = ["**/*.rs", "**/*.py"]
   ```

### Poor Retrieval Quality

**Symptoms**: Irrelevant results, missing obvious matches

**Solutions**:

1. **Lower similarity threshold**:
   ```toml
   min_similarity = 0.5
   ```

2. **Increase results**:
   ```toml
   max_results = 20
   ```

3. **Try a different embedding model**:
   ```toml
   embedding_model = "mxbai-embed-large"  # Higher quality
   ```

4. **Adjust chunk size**:
   ```toml
   chunk_size = 256  # More granular
   ```

### Memory Issues

**Symptoms**: High memory usage, slow performance

**Solutions**:

1. **Exclude large directories**:
   ```toml
   exclude_patterns = [
       "**/target/**",
       "**/node_modules/**",
       "**/vendor/**"
   ]
   ```

2. **Limit file size**:
   ```toml
   max_file_size_kb = 200
   ```

3. **Use a smaller embedding model**:
   ```toml
   embedding_model = "all-minilm"  # 384 dimensions vs 768
   ```

### Slow Indexing

**Symptoms**: Long startup time, high CPU during indexing

**Solutions**:

1. **Disable auto-index**:
   ```toml
   auto_index = false
   ```

2. **Reduce included files**:
   ```toml
   include_patterns = ["**/*.rs"]  # Only Rust files
   ```

3. **Use faster embedding model**:
   ```toml
   embedding_model = "all-minilm"
   ```

### File Watcher Not Working

**Symptoms**: Index not updating when files change

**Solutions**:

1. **Verify file watching is enabled**:
   ```toml
   watch_changes = true
   ```

2. **Check debounce setting**:
   ```toml
   watch_debounce_ms = 1000  # 1 second
   ```

3. **Restart IronClad** to reinitialize the watcher

## Architecture Decision Record

See [ADR-004](adr/004-rag-implementation.md) for the architectural decisions behind the RAG implementation, including:

- Why in-memory vector store was chosen over external databases
- Alternatives considered (LanceDB, Qdrant, Chroma)
- Trade-offs and consequences

## See Also

- [Configuration Documentation](configuration.md#rag-settings)
- [Architecture Overview](architecture.md#rag-knowledge-base)
- [Architecture Decision Record](adr/004-rag-implementation.md)
