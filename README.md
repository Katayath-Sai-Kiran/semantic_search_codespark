# semantic_search_codespark

[![pub package](https://img.shields.io/pub/v/semantic_search_codespark.svg)](https://pub.dev/packages/semantic_search_codespark)
[![pub points](https://img.shields.io/pub/points/semantic_search_codespark)](https://pub.dev/packages/semantic_search_codespark/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Offline semantic search for Flutter — match by meaning, not spelling.**
No API keys. No cloud. No OpenAI/Gemini/Ollama. A tiny API over a local model.

It finds matches that keyword and fuzzy search cannot — a user typing
*"I forgot my login details"* matches *"Reset your password"* despite sharing
zero words.

If this saves you a backend, please
[star the repo](https://github.com/Katayath-Sai-Kiran/semantic_search_codespark)
and [like it on pub.dev](https://pub.dev/packages/semantic_search_codespark) —
it helps others find it.

## Why it's different

Most "search" packages are one of: fuzzy-only, cloud-based (API key), make you
bring your own vectors, or bundle a model that bloats your app. This one is
on-device, zero-key, full-pipeline, and zero-setup:

| Package | Semantic | Offline | No API key | Model setup |
|---|:---:|:---:|:---:|---|
| **semantic_search_codespark** | ✓ | ✓ | ✓ | **auto-downloads + verifies, cached** |
| mobile_rag_engine | ✓ | ✓ | ✓ | manual `curl` into assets |
| pocket_brain | ✓ | ✓ | ✓ | bundled (bloats every build) |
| mk_smart_search | ✗ fuzzy only | ✓ | ✓ | — |
| zir_semantic_search | ✓ | ✗ | ✗ needs key | cloud API |

The ~23 MB MiniLM model downloads once on first run and is cached (via
[ai_core_codespark](https://pub.dev/packages/ai_core_codespark)) — so your app
binary stays small instead of shipping the model to every user up front.

## Why not just use ai_core_codespark?

You can — the engine exposes `embed`, `VectorStore`, and `cosine` directly. This
package is the ergonomic layer on top:

- **One line to index, one to search** — no manual `VectorStore` + `embedBatch` +
  `VectorRecord` wiring.
- **Typed results** — `searchObjects<T>` and `SemanticIndex<T>` hand back *your*
  objects (`SemanticResult<T>.item`), instead of stuffing fields into a
  `metadata` map and reading them back untyped.
- **Embed once, query many** — `createIndex` embeds the corpus a single time;
  each search only embeds the query.

Reach for [ai_core_codespark](https://pub.dev/packages/ai_core_codespark) when
you want the raw primitives (custom pipelines, classification, diversity/MMR).
Reach for this when you just want to rank things by meaning.

## Install

```yaml
dependencies:
  semantic_search_codespark: ^0.1.0
```

## Quick start

```dart
import 'package:semantic_search_codespark/semantic_search_codespark.dart';

final search = SemanticSearch();
await search.initialize();            // downloads the model once (~23 MB), then cached

final hits = await search.search(
  query: 'doctor',
  items: ['physician', 'car', 'engineer'],
);
print(hits.first.item);               // physician
```

These results are probed against the real model, so expectations are honest:

| Query | Finds | |
|---|---|---|
| `car` | automobile, vehicle | strong |
| `doctor` | physician, nurse | strong |
| `"I forgot my login details"` | "Reset your password" | zero-word-overlap match |
| `flutter state management` | riverpod | no — niche jargon, see below |

The model knows general language, not niche jargon. Search works best over
descriptive text (notes, FAQs, product names, support topics). For domain terms,
search over richer text (descriptions/tags), not bare labels.

## Search typed objects

```dart
final hits = await search.searchObjects<Product>(
  query: 'comfy running shoes',
  items: products,
  textOf: (p) => '${p.name} ${p.description}',
);
hits.first.item;   // your Product, ranked by meaning
```

## Repeated queries — embed once, search many

```dart
final index = await search.createIndex<Faq>(
  items: faqs,
  textOf: (f) => f.title,
);
final a = await index.search('where is my parcel');   // only the query is embedded
final b = await index.search('when will it arrive');
```

Use `createIndex` whenever you query the same data more than once — it embeds the
corpus a single time. `search()` re-embeds items on every call. Both accept
`topK` and an optional cosine `threshold`; the index also offers
`searchDiverse()` (MMR) to avoid near-duplicate results.

## How it works

Text to a local MiniLM embedding (via
[ai_core_codespark](https://pub.dev/packages/ai_core_codespark)) to a vector to
cosine ranking. Inference runs on a background isolate so the UI stays smooth.

## Platform support

| Android | iOS | macOS | Windows | Linux | Web |
|:---:|:---:|:---:|:---:|:---:|:---:|
| ✓ | ✓ | ✓ | ✓ | ✓ | experimental |

## Roadmap

- **v0.1** — semantic-only search (this release).
- **v0.2 — Hybrid search:** fuse semantic + fuzzy matching (Reciprocal Rank
  Fusion) so word-level and meaning-level queries both rank well.

## More from ksaikiran.dev

Other Flutter packages for text, search, and input:

| Package | What it does |
|---|---|
| [ai_core_codespark](https://pub.dev/packages/ai_core_codespark) | The on-device embedding engine this package is built on. |
| [text_comparison_score_codespark](https://pub.dev/packages/text_comparison_score_codespark) | String similarity — Levenshtein, Damerau-Levenshtein, Jaro-Winkler. |
| [animated_dropdown_search_codespark](https://pub.dev/packages/animated_dropdown_search_codespark) | Dropdown widget with built-in search and highlighting. |
| [text_highlight_codespark](https://pub.dev/packages/text_highlight_codespark) | Highlight rich text — queries, regex, per-term colors, tappable spans. |

Browse the full list on [pub.dev/publishers/ksaikiran.dev](https://pub.dev/publishers/ksaikiran.dev/packages).

## License

MIT © Sai Kiran Katayath — part of the **codespark** on-device AI ecosystem · [ksaikiran.dev](https://ksaikiran.dev)
