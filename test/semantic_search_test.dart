import 'dart:typed_data';

import 'package:ai_core_codespark/ai_core_codespark.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:semantic_search_codespark/semantic_search_codespark.dart';

/// A deterministic, model-free embedder. Maps known words to category
/// directions so cosine ranking reproduces the *validated* behavior
/// (car≈automobile≈vehicle, doctor≈physician) without downloading a model.
///
/// This tests the PACKAGE logic (ranking, topK, threshold, object search,
/// index reuse). The model's semantic quality is validated separately by the
/// embedding probe.
class FakeEmbedder implements SearchEmbedder {
  bool _ready = false;
  int batchCalls = 0; // lets tests assert "embedded once" for the index path.

  // [vehicle, fruit, medical, tech]
  static const _lex = {
    'car': [1.0, 0, 0, 0],
    'automobile': [1.0, 0, 0, 0.1],
    'vehicle': [1.0, 0, 0, 0],
    'banana': [0.0, 1, 0, 0],
    'fruit': [0.0, 1, 0, 0],
    'smoothie': [0.0, 1, 0, 0],
    'doctor': [0.0, 0, 1, 0],
    'physician': [0.0, 0, 1, 0],
    'nurse': [0.0, 0, 1, 0.2],
    'engineer': [0.0, 0, 0.1, 1],
    'flutter': [0.0, 0, 0, 1],
  };

  @override
  Future<void> initialize({ProgressCallback? onProgress}) async {
    onProgress?.call(100, 100);
    _ready = true;
  }

  @override
  bool get isInitialized => _ready;

  @override
  int get dimension => 4;

  @override
  Future<Float32List> embed(String text) async => _vec(text);

  @override
  Future<List<Float32List>> embedBatch(List<String> texts) async {
    batchCalls++;
    return [for (final t in texts) _vec(t)];
  }

  Float32List _vec(String text) {
    final acc = <double>[0, 0, 0, 0];
    for (final w in text.toLowerCase().split(RegExp(r'[^a-z]+'))) {
      final base = _lex[w];
      if (base == null) continue;
      for (var i = 0; i < 4; i++) {
        acc[i] += base[i];
      }
    }
    final v = Float32List.fromList(acc);
    return Pooling.l2Normalize(v); // unit vectors → cosine == dot
  }

  @override
  Future<void> dispose() async => _ready = false;
}

void main() {
  late SemanticSearch search;

  setUp(() async {
    search = SemanticSearch.withEmbedder(FakeEmbedder());
    await search.initialize();
  });

  group('search() over strings', () {
    test('ranks semantic matches above unrelated items', () async {
      final hits = await search.search(
        query: 'car',
        items: ['automobile', 'banana', 'vehicle'],
      );
      expect(hits.first.item, anyOf('automobile', 'vehicle'));
      expect(hits.last.item, 'banana');
    });

    test('doctor finds physician, not car/engineer', () async {
      final hits = await search.search(
        query: 'doctor',
        items: ['physician', 'car', 'engineer'],
      );
      expect(hits.first.item, 'physician');
    });

    test('topK caps the number of results', () async {
      final hits = await search.search(
        query: 'car',
        items: ['automobile', 'vehicle', 'banana', 'fruit'],
        topK: 2,
      );
      expect(hits.length, 2);
    });

    test('threshold filters weak matches', () async {
      final hits = await search.search(
        query: 'car',
        items: ['automobile', 'banana'],
        threshold: 0.5,
      );
      expect(hits.map((h) => h.item), isNot(contains('banana')));
      expect(hits.map((h) => h.item), contains('automobile'));
    });

    test('result carries original index and a score', () async {
      final hits = await search.search(
        query: 'car',
        items: ['banana', 'automobile'],
      );
      final top = hits.first;
      expect(top.item, 'automobile');
      expect(top.index, 1, reason: 'index into the original list');
      expect(top.score, greaterThan(0.8));
    });
  });

  group('searchObjects<T>()', () {
    test('searches typed objects via textOf and returns them', () async {
      final products = [
        (id: 1, name: 'banana smoothie'),
        (id: 2, name: 'family automobile'),
      ];
      final hits = await search.searchObjects(
        query: 'car',
        items: products,
        textOf: (p) => p.name,
      );
      expect(hits.first.item.id, 2);
    });
  });

  group('createIndex()', () {
    test('embeds the corpus once, then queries reuse it', () async {
      final fake = FakeEmbedder();
      final s = SemanticSearch.withEmbedder(fake);
      await s.initialize();

      final index = await s.createIndex(
        items: ['automobile', 'banana', 'physician'],
        textOf: (x) => x,
      );
      final before = fake.batchCalls;

      await index.search('car');
      await index.search('doctor');

      expect(fake.batchCalls, before,
          reason: 'queries must not re-embed the corpus');
      final docHit = await index.search('doctor', topK: 1);
      expect(docHit.first.item, 'physician');
    });

    test('handles an empty corpus', () async {
      final index =
          await search.createIndex<String>(items: [], textOf: (x) => x);
      expect(await index.search('anything'), isEmpty);
    });
  });

  test('searching before initialize throws', () async {
    final s = SemanticSearch.withEmbedder(FakeEmbedder());
    expect(
      () => s.search(query: 'x', items: ['y']),
      throwsStateError,
    );
  });
}
