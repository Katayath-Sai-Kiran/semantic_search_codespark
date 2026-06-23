import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:semantic_search_codespark/semantic_search_codespark.dart';

/// End-to-end test on a real device: downloads + runs the actual int8 MiniLM
/// model through onnxruntime and checks the embeddings rank as validated.
///
/// Run with:  flutter test integration_test/embedding_test.dart -d macos
///
/// This is the verification `flutter test` cannot do (no native libs). First
/// run downloads ~23 MB; allow a generous timeout.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late SemanticSearch search;

  setUpAll(() async {
    search = SemanticSearch();
    await search.initialize();
  });

  tearDownAll(() async => search.dispose());

  testWidgets('doctor → physician (not car/engineer)', (_) async {
    final hits = await search.search(
      query: 'doctor',
      items: ['physician', 'car', 'software engineer'],
    );
    expect(hits.first.item, 'physician');
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('car → automobile/vehicle above banana', (_) async {
    final hits = await search.search(
      query: 'car',
      items: ['automobile', 'banana', 'vehicle'],
    );
    expect(hits.first.item, anyOf('automobile', 'vehicle'));
    expect(hits.last.item, 'banana');
  });

  testWidgets('zero-overlap sentence: login → reset password', (_) async {
    final hits = await search.search(
      query: 'I forgot my login details',
      items: [
        'Reset your password',
        'Track your package',
        'Return and refund policy',
      ],
    );
    expect(hits.first.item, 'Reset your password');
  });

  testWidgets('embeddings are normalized (self-similarity ≈ 1)', (_) async {
    final v = await search.search(query: 'hello', items: ['hello']);
    expect(v.first.score, closeTo(1.0, 1e-3));
  });
}
