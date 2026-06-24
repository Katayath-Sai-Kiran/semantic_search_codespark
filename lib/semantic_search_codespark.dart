/// semantic_search_codespark — offline semantic search for Flutter.
///
/// Match by meaning, not spelling. No API keys, no cloud. Built on
/// ai_core_codespark + a local MiniLM model.
library;

export 'src/semantic_search.dart';
export 'src/semantic_index.dart';
export 'src/semantic_result.dart';
export 'src/search_embedder.dart';
export 'src/semantic_search_field.dart';

// Re-export the bits of the core a typical user needs, so they don't have to
// add ai_core_codespark as a direct dependency for common cases.
export 'package:ai_core_codespark/ai_core_codespark.dart'
    show ModelConfig, ModelCatalog, ProgressCallback;
