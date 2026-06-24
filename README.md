# semantic_search_codespark

[![pub package](https://img.shields.io/pub/v/semantic_search_codespark.svg)](https://pub.dev/packages/semantic_search_codespark)
[![pub points](https://img.shields.io/pub/points/semantic_search_codespark)](https://pub.dev/packages/semantic_search_codespark/score)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Add search-by-meaning to your Flutter app in three lines — fully on-device, no
backend, no API keys, no per-query cost.**

It matches by *meaning*, so a user typing **"I forgot my login details"** finds
**"Reset your password"** even though they share no words — something keyword and
fuzzy search physically can't do. Semantic search, vector search, and
embeddings, running entirely on the device.

<!-- Add a ~10s search-as-you-type demo GIF here once recorded, e.g.:
![demo](https://raw.githubusercontent.com/Katayath-Sai-Kiran/semantic_search_codespark/main/doc/demo.gif)
-->

## Three lines

```dart
import 'package:semantic_search_codespark/semantic_search_codespark.dart';

final search = SemanticSearch();
await search.initialize(); // downloads a ~23 MB model once, then it's cached

final hits = await search.search(
  query: 'I forgot my login details',
  items: ['Reset your password', 'Track my order', 'Cancel subscription'],
);
// hits.first.item == 'Reset your password'  — zero shared words
```

## Why developers use it

- **No backend, no API keys, no cost.** No Algolia, Firebase, or OpenAI bill —
  and nothing to deploy.
- **100% offline & private.** Text never leaves the device. Great for privacy,
  compliance (health/finance), planes, and low-connectivity markets.
- **Beats fuzzy search on real queries.** It understands intent, not just
  spelling.
- **Doesn't block your UI.** Inference runs on a background isolate.
- **Typed results.** Search your own objects and get them back, fully typed.
- **One package, every platform** — Android, iOS, macOS, Windows, Linux.

## Search your own objects

The real use case — rank a list of *your* models by meaning and get them back
typed (no untyped maps):

```dart
final hits = await search.searchObjects<Product>(
  query: 'comfy running shoes',
  items: products,
  textOf: (p) => '${p.name} ${p.description}',
);

for (final hit in hits) {
  print('${hit.item.name}  ·  ${hit.score.toStringAsFixed(2)}'); // your Product
}
```

## Index once, search many

For a stable corpus (an FAQ, a catalog, a notes list), embed it once and reuse
the index — only the query is embedded per search:

```dart
final index = await search.createIndex<Faq>(
  items: faqs,
  textOf: (f) => f.title,
);

final a = await index.search('where is my parcel'); // matches "Track your order"
final b = await index.search('how do I pay');        // matches "Payment methods"
```

Both `search()` and `index.search()` take `topK` and an optional cosine
`threshold`. The index also offers `searchDiverse()` (MMR) to avoid
near-duplicate results, and `add()` to append items without re-embedding.

## Embed once, ever — persist the index

Save the built index to disk and reload it next launch, so you never re-embed
the same corpus twice:

```dart
// First launch: build + save
final index = await search.createIndex<Faq>(items: faqs, textOf: (f) => f.title);
await index.save(cachePath, encode: (f) => f.toJson());

// Later launches: load instantly, no re-embedding
final index = await search.loadIndex<Faq>(
  path: cachePath,
  decode: (json) => Faq.fromJson(json),
);
```

(Filesystem-backed — mobile & desktop. It rejects a reload if the model
dimension changed, so stale vectors can't sneak in.)

## Drop-in search widget

Hand `SemanticSearchField` an index and a result builder — it handles the text
field, debouncing, and search-as-you-type:

```dart
SemanticSearchField<Faq>(
  index: faqIndex,
  hintText: 'Ask a question…',
  onResultTap: (r) => openFaq(r.item),
  resultBuilder: (context, r) => ListTile(
    title: Text(r.item.title),
    trailing: Text(r.score.toStringAsFixed(2)),
  ),
)
```

## Install

```yaml
dependencies:
  semantic_search_codespark: ^0.1.0
```

## When to reach for it (and when not to)

| If you need… | Use |
|---|---|
| Match by **meaning / intent**, offline, no backend | **semantic_search_codespark** |
| Typo tolerance on short strings, tiniest footprint | a fuzzy matcher like [text_comparison_score_codespark](https://pub.dev/packages/text_comparison_score_codespark) |
| Millions of docs, multilingual, managed, faceting | a cloud service (Algolia, Typesense, …) |

It's the right tool when meaning matters and a backend is overkill. **v0.2 fuses
this with fuzzy matching** (Reciprocal Rank Fusion) so you get meaning *and*
typo-tolerance in one call.

## Limitations & tips

- The model knows **general language, not niche jargon** ("doctor → physician" ✓;
  "flutter state management → riverpod" ✗). Search over descriptive text
  (titles, descriptions, tags), not bare codenames.
- Best for **small-to-medium on-device corpora** (up to ~10k items; ranking is
  brute-force cosine). Larger sets are on the roadmap.
- Primarily tuned for **English**.
- First `initialize()` downloads ~23 MB once and caches it — show the
  `onProgress` callback so it never looks stuck.

## Platform support

| Android | iOS | macOS | Windows | Linux | Web |
|:---:|:---:|:---:|:---:|:---:|:---:|
| ✓ | ✓ | ✓ | ✓ | ✓ | experimental |

## How it works

Text → a local MiniLM embedding (via
[ai_core_codespark](https://pub.dev/packages/ai_core_codespark)) → a vector →
cosine ranking, all on a background isolate. For raw primitives (custom
pipelines, classification, diversity/MMR) use the engine directly.

## Roadmap

- **v0.1** — on-device semantic search.
- **v0.2** — persistent save-to-disk index, incremental `add()`, and the
  `SemanticSearchField` widget (this release).
- **Next** — hybrid search (semantic + fuzzy via RRF) for typo-proof matching,
  then a multilingual model.

## More from ksaikiran.dev

| Package | What it does |
|---|---|
| [ai_core_codespark](https://pub.dev/packages/ai_core_codespark) | The on-device embedding engine this is built on. |
| [text_comparison_score_codespark](https://pub.dev/packages/text_comparison_score_codespark) | Fuzzy string similarity — Levenshtein, Jaro-Winkler. |
| [animated_dropdown_search_codespark](https://pub.dev/packages/animated_dropdown_search_codespark) | Searchable, animated dropdown widget. |
| [text_highlight_codespark](https://pub.dev/packages/text_highlight_codespark) | Highlight query matches in text. |

Browse all on [pub.dev/publishers/ksaikiran.dev](https://pub.dev/publishers/ksaikiran.dev/packages).

## License

MIT © Sai Kiran Katayath — part of the **codespark** on-device AI ecosystem · [ksaikiran.dev](https://ksaikiran.dev)

If this saved you a backend, a ⭐ on [GitHub](https://github.com/Katayath-Sai-Kiran/semantic_search_codespark) and a 👍 on [pub.dev](https://pub.dev/packages/semantic_search_codespark) help other developers find it.
