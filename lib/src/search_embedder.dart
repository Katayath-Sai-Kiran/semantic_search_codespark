import 'dart:typed_data';

import 'package:ai_core_codespark/ai_core_codespark.dart';

/// The minimal embedding contract [SemanticSearch] depends on.
///
/// Kept as an interface so the search logic can be unit-tested with a fake
/// backend (no 23 MB model download in CI) and so advanced users can plug in a
/// different embedding source later.
abstract class SearchEmbedder {
  Future<void> initialize({ProgressCallback? onProgress});
  bool get isInitialized;
  int get dimension;

  Future<Float32List> embed(String text);
  Future<List<Float32List>> embedBatch(List<String> texts);

  Future<void> dispose();
}

/// Default backend: adapts [CodesparkEngine] (ai_core_codespark) to
/// [SearchEmbedder]. This is what runs in real apps.
class CodesparkBackend implements SearchEmbedder {
  final CodesparkEngine engine;
  CodesparkBackend(this.engine);

  /// Convenience: build over the default catalog model.
  factory CodesparkBackend.miniLm() =>
      CodesparkBackend(CodesparkEngine(model: ModelCatalog.miniLmL6V2));

  @override
  Future<void> initialize({ProgressCallback? onProgress}) =>
      engine.initialize(onProgress: onProgress);

  @override
  bool get isInitialized => engine.isInitialized;

  @override
  int get dimension => engine.dimension;

  @override
  Future<Float32List> embed(String text) => engine.embed(text);

  @override
  Future<List<Float32List>> embedBatch(List<String> texts) =>
      engine.embedBatch(texts);

  @override
  Future<void> dispose() => engine.dispose();
}
