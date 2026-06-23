# semantic_search_codespark

[![pub package](https://img.shields.io/pub/v/semantic_search_codespark.svg)](https://pub.dev/packages/semantic_search_codespark)
[![pub points](https://img.shields.io/pub/points/semantic_search_codespark)](https://pub.dev/packages/semantic_search_codespark/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Offline semantic search for Flutter — match by meaning, not spelling.**
No API keys. No cloud. No OpenAI/Gemini/Ollama. A tiny API over a local model.

It finds matches that keyword and fuzzy search **cannot** — a user typing
*"I forgot my login details"* matches *"Reset your password"* despite sharing
**zero words**.

> 💙 **If this saves you a backend, please [⭐ star the repo](https://github.com/Katayath-Sai-Kiran/semantic_search_codespark) and 👍 like it on [pub.dev](https://pub.dev/packages/semantic_search_codespark)** — it genuinely helps others find it.

## Why it's different

Most "search" packages are one of: fuzzy-only, cloud-based (API key), make you
bring your own vectors, or bundle a model that bloats your app. This one is
**on-device, zero-key, full-pipeline, and zero-setup**:

| Package | Semantic | Offline | No API key | Model setup |
|---|:---:|:---:|:---:|---|
| **semantic_search_codespark** | ✅ | ✅ | ✅ | **auto-downloads + verifies, cached** |
| mobile_rag_engine | ✅ | ✅ | ✅ | manual `curl` into assets |
| pocket_brain | ✅ | ✅ | ✅ | bundled (bloats every build) |
| mk_smart_search | ❌ fuzzy only | ✅ | ✅ | — |
| zir_semantic_search | ✅ | ❌ | ❌ needs key | cloud API |

The ~23 MB MiniLM model **downloads once on first run and is cached** (via
[ai_core_codespark](https://pub.dev/packages/ai_core_codespark)) — so your app
binary stays small instead of shipping the model to every user up front.

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
| `car` | automobile, vehicle | ✅ strong |
| `doctor` | physician, nurse | ✅ strong |
| `"I forgot my login details"` | "Reset your password" | ✅ zero-word-overlap match |
| `flutter state management` | riverpod | ❌ niche jargon — see below |

**The model knows general language, not niche jargon.** Search works best over
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

Text → local MiniLM embedding (via
[ai_core_codespark](https://pub.dev/packages/ai_core_codespark)) → vector →
cosine ranking. Inference runs on a background isolate so the UI stays smooth.

## Platform support

| Android | iOS | macOS | Windows | Linux | Web |
|:---:|:---:|:---:|:---:|:---:|:---:|
| ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ experimental |

## Roadmap

- **v0.1** — semantic-only search (this release).
- **v0.2 — Hybrid search:** fuse semantic + fuzzy matching (Reciprocal Rank
  Fusion) so word-level *and* meaning-level queries both rank well.

## License

MIT © Sai Kiran Katayath — part of the **codespark** on-device AI ecosystem · [ksaikiran.dev](https://ksaikiran.dev)

If you ship something with it, a ⭐ on GitHub and a 👍 on pub.dev are hugely appreciated.
