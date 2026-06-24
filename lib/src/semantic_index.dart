import 'dart:convert';
import 'dart:io';
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
///
/// Persist it with [save] and reload it with [SemanticSearch.loadIndex] so the
/// corpus is embedded **once, ever** — not on every app launch.
class SemanticIndex<T> {
  final SearchEmbedder _embedder;
  final List<T> _items;
  final List<Float32List> _vectors;

  SemanticIndex._(this._embedder, this._items, this._vectors);

  /// Number of indexed items.
  int get length => _items.length;

  /// The indexed items, in order (read-only view).
  List<T> get items => List.unmodifiable(_items);

  /// Embedding dimensionality (0 for an empty index).
  int get dimension => _vectors.isEmpty ? 0 : _vectors.first.length;

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
    return SemanticIndex._(embedder, List.of(items), List.of(vectors));
  }

  /// Embeds and appends [newItems] to an existing index (no full re-embed).
  Future<void> add(
    List<T> newItems, {
    required String Function(T) textOf,
  }) async {
    if (newItems.isEmpty) return;
    final vecs =
        await _embedder.embedBatch([for (final it in newItems) textOf(it)]);
    _items.addAll(newItems);
    _vectors.addAll(vecs);
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

  // ── Persistence ────────────────────────────────────────────────────────────

  static const int _formatVersion = 1;

  /// Saves the index (items + vectors) to [path] as JSON so it can be reloaded
  /// without re-embedding. [encode] serializes one item to a JSON-safe map.
  ///
  /// Uses the filesystem — available on mobile and desktop, not web.
  Future<void> save(
    String path, {
    required Map<String, dynamic> Function(T item) encode,
  }) async {
    final json = {
      'version': _formatVersion,
      'dimension': dimension,
      'records': [
        for (var i = 0; i < _items.length; i++)
          {'item': encode(_items[i]), 'v': _encodeVector(_vectors[i])},
      ],
    };
    await File(path).writeAsString(jsonEncode(json));
  }

  /// Restores an index previously written with [save]. [decode] rebuilds one
  /// item from its JSON map; [embedder] is used to embed future queries.
  ///
  /// Throws [StateError] if the saved embedding dimension doesn't match the
  /// embedder's (i.e. the model changed) — cached vectors would be invalid.
  static Future<SemanticIndex<T>> restore<T>({
    required SearchEmbedder embedder,
    required String path,
    required T Function(Map<String, dynamic> json) decode,
  }) async {
    final raw = jsonDecode(await File(path).readAsString());
    final json = raw as Map<String, dynamic>;
    final savedDim = json['dimension'] as int? ?? 0;

    if (embedder.isInitialized &&
        savedDim != 0 &&
        embedder.dimension != savedDim) {
      throw StateError(
        'Saved index dimension ($savedDim) does not match the current model '
        '(${embedder.dimension}). Re-create the index after a model change.',
      );
    }

    final items = <T>[];
    final vectors = <Float32List>[];
    for (final r in (json['records'] as List)) {
      final m = r as Map<String, dynamic>;
      items.add(decode((m['item'] as Map).cast<String, dynamic>()));
      vectors.add(_decodeVector(m['v'] as String));
    }
    return SemanticIndex._(embedder, items, vectors);
  }

  /// Float32List → base64 of its raw little-endian bytes (compact + fast).
  static String _encodeVector(Float32List v) =>
      base64Encode(v.buffer.asUint8List(v.offsetInBytes, v.lengthInBytes));

  static Float32List _decodeVector(String s) {
    final bytes = base64Decode(s);
    final out = Float32List(bytes.length ~/ 4);
    out.buffer.asUint8List(out.offsetInBytes, out.lengthInBytes).setAll(0, bytes);
    return out;
  }
}
