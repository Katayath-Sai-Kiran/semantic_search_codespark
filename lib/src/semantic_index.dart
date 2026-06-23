import 'dart:typed_data';

import 'package:ai_core_codespark/ai_core_codespark.dart';

import 'search_embedder.dart';
import 'semantic_result.dart';

/// A reusable, pre-embedded corpus for repeated queries.
///
/// Build it once (it embeds every item up front) then query it as many times
/// as you like — only the query is embedded per search. This is the right tool
/// when the dataset is stable and searched often (a fixed catalog, a help
/// center). For a one-off search over an ad-hoc list, use
/// [SemanticSearch.search] instead.
class SemanticIndex<T> {
  final SearchEmbedder _embedder;
  final List<T> _items;
  final List<Float32List> _vectors;

  SemanticIndex._(this._embedder, this._items, this._vectors);

  int get length => _items.length;

  /// Embeds [items] and returns a ready index. [textOf] extracts the string to
  /// embed from each item (identity for `List<String>`).
  static Future<SemanticIndex<T>> build<T>({
    required SearchEmbedder embedder,
    required List<T> items,
    required String Function(T) textOf,
  }) async {
    final vectors = items.isEmpty
        ? <Float32List>[]
        : await embedder.embedBatch([for (final it in items) textOf(it)]);
    return SemanticIndex._(embedder, List.of(items), vectors);
  }

  /// Ranks the corpus against [query], best first.
  Future<List<SemanticResult<T>>> search(
    String query, {
    int topK = 10,
    double? threshold,
  }) async {
    if (_items.isEmpty) return [];
    final q = await _embedder.embed(query);
    final scored = Similarity.topK(q, _vectors, k: topK, threshold: threshold);
    return [
      for (final s in scored)
        SemanticResult(item: _items[s.index], score: s.score, index: s.index)
    ];
  }

  /// Diversity-aware ranking (MMR) — avoids returning near-duplicate hits.
  /// [lambda] trades relevance (1.0) against diversity (0.0).
  Future<List<SemanticResult<T>>> searchDiverse(
    String query, {
    int topK = 10,
    double lambda = 0.5,
  }) async {
    if (_items.isEmpty) return [];
    final q = await _embedder.embed(query);
    final scored = Similarity.mmr(q, _vectors, k: topK, lambda: lambda);
    return [
      for (final s in scored)
        SemanticResult(item: _items[s.index], score: s.score, index: s.index)
    ];
  }
}
