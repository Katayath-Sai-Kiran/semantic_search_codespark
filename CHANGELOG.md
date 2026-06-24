## 0.1.1

- Docs: rewrote the README around the use case (lead example, real-world object
  search, when-to-use guidance, limitations & tips).
- Discoverability: sharper description and topics (semantic / vector search,
  embeddings, AI, offline).

## 0.1.0

Initial release — offline semantic search for Flutter.

- `SemanticSearch`: one-call API to rank a list of strings or typed objects by
  meaning, fully on-device (no API keys, no cloud).
- `search()` / `searchObjects<T>()`: one-shot search with `topK` and an optional
  similarity `threshold`.
- `createIndex()` → `SemanticIndex`: embed a corpus once and query it repeatedly;
  supports diversity-aware ranking (MMR) via `searchDiverse()`.
- `SemanticResult<T>`: carries the matched item, its cosine score, and original
  index.
- Pluggable `SearchEmbedder` (default `CodesparkBackend` over
  [ai_core_codespark](https://pub.dev/packages/ai_core_codespark)) so search
  logic is testable without downloading a model.
