# Architecture Decision Records (ADRs)

This directory documents key architectural and engineering design decisions made in IronClad.

## Table of Contents

| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-001](001-traffic-light-policy.md) | Three-Ring Security & Traffic Light Autonomy Policy | Accepted | 2026-03-15 |
| [ADR-002](002-sandbox-backend-abstraction.md) | Sandbox Backend Abstraction (Docker / Local Host) | Accepted | 2026-03-22 |
| [ADR-003](003-mcp-integration-pattern.md) | Model Context Protocol (MCP) Integration Pattern | Accepted | 2026-04-05 |
| [ADR-004](004-rag-implementation.md) | Tree-Sitter AST & Local Semantic Vector Search | Accepted | 2026-04-18 |
| [ADR-005](005-native-tool-calling.md) | Native Tool Calling Protocol & Prompt Tool Fallback | Accepted | 2026-05-02 |
| [ADR-006](006-dynamic-model-preferences.md) | Dynamic Model Preferences & Hardware-Aware Tiering | Accepted | 2026-06-10 |

---

## Proposing a New ADR

To propose a new architecture decision:
1. Copy [template.md](template.md) to a new file named `XXX-short-title.md` (e.g. `007-my-decision.md`).
2. Fill out Context, Decision, and Consequences sections.
3. Submit a PR for review.
