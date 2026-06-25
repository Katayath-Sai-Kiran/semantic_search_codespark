## 0.2.0

- **Persistent index** — `SemanticIndex.save()` and `SemanticSearch.loadIndex()`
  serialize the corpus + vectors to disk (compact base64), so you embed once
  *ever* instead of on every launch. Guards against a model/dimension change.
- **`SemanticSearchField`** — a drop-in, debounced search widget: hand it an
  index and a result builder, get search-as-you-type with your own UI.
- **`SemanticIndex.add()`** — append new items to an existing index without
  re-embedding the whole corpus. Plus `items` and `dimension` getters.
- **AI-agent-friendly docs** — "AI Agent Context" guidance on `search()`, an
  `llms.txt` (intent + minimal syntax), and scenario examples
  (`example/lib/faq_search_example.dart`, `custom_object_search_example.dart`).
- Discoverability: description now leads with "Offline vector search"; topics
  updated for on-device-AI search.

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
