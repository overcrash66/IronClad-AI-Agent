# ADR-004: RAG Implementation with In-Memory Vector Store

## Title

RAG Knowledge Base with In-Memory Vector Store

## Status

Accepted

## Context

IronClad needs to provide codebase context to the LLM when answering questions or making code changes. Without this context, the LLM may:

1. **Hallucinate**: Make up APIs, functions, or patterns that don't exist
2. **Miss Context**: Not understand project-specific conventions and patterns
3. **Provide Generic Answers**: Give advice that doesn't apply to the specific codebase

We need a Retrieval-Augmented Generation (RAG) system that:

- Indexes the workspace code into searchable vectors
- Retrieves relevant code chunks based on queries
- Works entirely locally for privacy
- Integrates seamlessly with the existing Orchestrator
- Has minimal external dependencies

## Decision

We implement a RAG system with an **in-memory vector store** with disk persistence, using:

### Core Components

1. **Vector Store**: In-memory storage with JSON persistence
   - Simple, embedded, no external dependencies
   - Fast similarity search using cosine similarity
   - Automatic persistence to `.ironclad/vectors/`

2. **Embedding Client**: Multi-provider support
   - Ollama (local, recommended)
   - OpenAI (cloud, high quality)
   - NVIDIA NIM (cloud, specialized)

3. **Code Parser**: Tree-sitter based semantic parsing
   - Language-aware chunking (functions, classes, modules)
   - Support for Rust, Python, JavaScript, TypeScript, Go, Java

4. **File Watcher**: Incremental indexing
   - Background monitoring for file changes
   - Debounced updates to batch changes

### Architecture

```
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│   File Watcher │────▶│  Code Parser   │────▶│   Chunker      │
│  [Background]  │     │  [Tree-sitter] │     │  [Semantic]    │
└────────────────┘     └────────────────┘     └───────┬────────┘
                                                       │
                                                       ▼
┌────────────────┐     ┌────────────────┐     ┌────────────────┐
│  Orchestrator  │────▶│  RAG Skill     │────▶│  Embedding     │
│  [Auto-query]  │     │  [query_knowledge_base] │  [Ollama/Cloud]│
└────────────────┘     └───────┬────────┘     └───────┬────────┘
                               │                      │
                               ▼                      ▼
                      ┌─────────────────────────────────────┐
                      │         Vector Store                 │
                      │   [In-memory with persistence]       │
                      └─────────────────────────────────────┘
```

## Consequences

### Positive

1. **Zero External Dependencies**: No separate database server to install or manage
2. **Privacy**: All data stays local, no cloud services required (with Ollama)
3. **Simplicity**: Easy to understand, debug, and maintain
4. **Fast Startup**: In-memory store loads quickly from disk
5. **Portable**: Single directory (`.ironclad/`) contains all RAG data
6. **Configurable**: Users can tune all aspects via settings.toml

### Negative

1. **Memory Usage**: Entire index must fit in memory
   - Mitigation: Configurable file size limits and exclusion patterns
   - Typical workspace: 10k files ≈ 100-500MB memory

2. **No Distributed Search**: Cannot scale across multiple machines
   - Acceptable: IronClad is designed for single-user local use

3. **Reindex on Restart**: Index is loaded from disk on startup
   - Mitigation: Fast JSON deserialization, typically < 1 second

4. **Limited Query Capabilities**: Basic similarity search only
   - Acceptable: Meets the primary use case of code retrieval

## Alternatives Considered

### 1. LanceDB

**Description**: Pure Rust embedded columnar database with vector support.

**Pros**:
- Native Rust implementation
- Columnar storage optimized for vectors
- Supports metadata filtering
- HNSW indexes for fast search

**Cons**:
- Additional dependency with complex build requirements
- Overkill for the current scale (single user, local workspace)
- Arrow-based storage adds complexity

**Decision**: Rejected in favor of simpler in-memory solution. May reconsider for larger scale needs.

### 2. Qdrant

**Description**: Dedicated vector database with rich features.

**Pros**:
- Production-ready vector search
- Rich filtering capabilities
- Distributed deployment possible
- Excellent performance at scale

**Cons**:
- Requires separate server process
- Additional operational complexity
- Overkill for single-user local use case
- Docker deployment adds overhead

**Decision**: Rejected. Better suited for production multi-user scenarios.

### 3. Chroma

**Description**: AI-native open-source embedding database.

**Pros**:
- Simple Python SDK
- Built-in embedding functions
- Good documentation

**Cons**:
- Python-based, requires separate process
- Not native to Rust ecosystem
- Additional deployment complexity

**Decision**: Rejected. Not suitable for Rust-native application.

### 4. SQLite with Vector Extension

**Description**: SQLite with sqlite-vss or similar vector extension.

**Pros**:
- Leverages existing SQLite infrastructure
- Familiar SQL interface
- Good persistence story

**Cons**:
- Extensions require compilation
- Less flexible than dedicated vector store
- Query performance may be slower

**Decision**: Rejected. In-memory with JSON persistence is simpler and faster.

### 5. Pinecone (Cloud)

**Description**: Managed vector database service.

**Pros**:
- Fully managed, no infrastructure
- Excellent scalability
- Enterprise features

**Cons**:
- Cloud-only, privacy concerns
- Ongoing costs
- External dependency

**Decision**: Rejected. Conflicts with privacy-first local approach.

## Implementation Details

### Vector Store Schema

```rust
pub struct CodeChunk {
    pub id: String,
    pub file_path: String,
    pub content: String,
    pub embedding: Vec<f32>,
    pub language: String,
    pub chunk_type: String,
    pub name: String,
    pub start_line: u32,
    pub end_line: u32,
    pub docstring: Option<String>,
    pub signatures: Vec<String>,
    pub imports: Vec<String>,
    pub indexed_at: i64,
    pub file_modified_at: i64,
    pub token_count: u32,
}
```

### Similarity Search

Uses cosine similarity for vector comparison:

```rust
pub fn cosine_similarity(a: &[f32], b: &[f32]) -> f32 {
    let dot_product: f32 = a.iter().zip(b.iter()).map(|(x, y)| x * y).sum();
    let norm_a: f32 = a.iter().map(|x| x * x).sum::<f32>().sqrt();
    let norm_b: f32 = b.iter().map(|x| x * x).sum::<f32>().sqrt();
    dot_product / (norm_a * norm_b)
}
```

### Persistence

Vectors are persisted to JSON files in `.ironclad/vectors/`:

```
.ironclad/
└── vectors/
    ├── manifest.json      # Metadata and statistics
    ├── chunks_0001.json   # Chunk data
    └── embeddings_0001.bin # Binary embeddings (optional)
```

## Configuration

```toml
[rag]
enabled = true
db_path = ".ironclad/vectors"
embedding_provider = "ollama"
embedding_model = "nomic-embed-text"
chunk_size = 512
chunk_overlap = 50
max_results = 10
min_similarity = 0.7
auto_index = true
watch_changes = true
auto_inject_context = true
max_context_tokens = 2000
```

## Future Enhancements

1. **HNSW Index**: Add approximate nearest neighbor search for faster queries
2. **Embedding Cache**: Cache embeddings to avoid recomputation
3. **Multi-workspace**: Support indexing multiple projects
4. **Code Graph**: Build and query code dependency relationships
5. **Semantic Search**: Natural language queries with code understanding
6. **Incremental Persistence**: Save only changed chunks

## References

- [Retrieval-Augmented Generation (RAG)](https://arxiv.org/abs/2005.11401)
- [Tree-sitter Parsing](https://tree-sitter.github.io/tree-sitter/)
- [Cosine Similarity](https://en.wikipedia.org/wiki/Cosine_similarity)
- [Ollama Embeddings](https://ollama.com/blog/embedding-models)
- [OpenAI Embeddings](https://platform.openai.com/docs/guides/embeddings)
