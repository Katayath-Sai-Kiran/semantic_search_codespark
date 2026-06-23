import 'package:ai_core_codespark/ai_core_codespark.dart';

import 'search_embedder.dart';
import 'semantic_index.dart';
import 'semantic_result.dart';

/// Offline semantic search — match by meaning, not spelling.
///
/// ```dart
/// final search = SemanticSearch();
/// await search.initialize();                 // downloads model once
/// final hits = await search.search(
///   query: 'doctor',
///   items: ['physician', 'car', 'engineer'],
/// );
/// // hits.first.item == 'physician'
/// ```
///
/// For a dataset you query repeatedly, build a [SemanticIndex] with
/// [createIndex] so items are embedded once rather than on every call.
class SemanticSearch {
  final SearchEmbedder _embedder;

  /// Uses the default on-device model (MiniLM-L6, ~23 MB, downloaded on first
  /// [initialize]). Pass a [model] to override, or [SemanticSearch.withEmbedder]
  /// to inject a custom/fake backend.
  SemanticSearch({ModelConfig? model})
      : _embedder = CodesparkBackend(
          CodesparkEngine(model: model ?? ModelCatalog.miniLmL6V2),
        );

  /// Inject any [SearchEmbedder] — used for tests and custom embedding sources.
  SemanticSearch.withEmbedder(this._embedder);

  bool get isInitialized => _embedder.isInitialized;

  /// Downloads + loads the model if needed. Idempotent; safe to await at
  /// startup or lazily before first search. [onProgress] reports download bytes.
  Future<void> initialize({ProgressCallback? onProgress}) =>
      _embedder.initialize(onProgress: onProgress);

  /// One-shot search over a list of strings.
  ///
  /// Embeds [items] on every call — fine for small or changing lists. For a
  /// stable dataset searched repeatedly, prefer [createIndex].
  Future<List<SemanticResult<String>>> search({
    required String query,
    required List<String> items,
    int topK = 10,
    double? threshold,
  }) =>
      searchObjects<String>(
        query: query,
        items: items,
        textOf: (s) => s,
        topK: topK,
        threshold: threshold,
      );

  /// One-shot search over typed objects. [textOf] selects the text to embed;
  /// results carry the original objects.
  ///
  /// ```dart
  /// final hits = await search.searchObjects<Product>(
  ///   query: 'comfortable running shoes',
  ///   items: products,
  ///   textOf: (p) => '${p.name} ${p.description}',
  /// );
  /// ```
  Future<List<SemanticResult<T>>> searchObjects<T>({
    required String query,
    required List<T> items,
    required String Function(T) textOf,
    int topK = 10,
    double? threshold,
  }) async {
    _ensureReady();
    final index = await SemanticIndex.build(
      embedder: _embedder,
      items: items,
      textOf: textOf,
    );
    return index.search(query, topK: topK, threshold: threshold);
  }

  /// Builds a reusable [SemanticIndex] (embeds items once). Use for datasets
  /// queried repeatedly.
  Future<SemanticIndex<T>> createIndex<T>({
    required List<T> items,
    required String Function(T) textOf,
  }) {
    _ensureReady();
    return SemanticIndex.build(
      embedder: _embedder,
      items: items,
      textOf: textOf,
    );
  }

  void _ensureReady() {
    if (!isInitialized) {
      throw StateError(
          'SemanticSearch.initialize() must be awaited before searching.');
    }
  }

  Future<void> dispose() => _embedder.dispose();
}
