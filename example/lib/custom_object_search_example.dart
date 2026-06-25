// Scenario: rank a list of typed `Product` objects by meaning and get the
// objects back — no untyped metadata maps. `textOf` selects what to embed;
// results carry your original object via `hit.item`.
//
// Run after `flutter pub get`:
//   dart run example/lib/custom_object_search_example.dart
import 'package:semantic_search_codespark/semantic_search_codespark.dart';

/// A typical app model.
class Product {
  const Product(this.id, this.name, this.description);
  final String id;
  final String name;
  final String description;
}

Future<void> main() async {
  final search = SemanticSearch();
  await search.initialize();

  const catalog = [
    Product('p1', 'Trail Running Shoes',
        'Lightweight, breathable, cushioned for long runs'),
    Product('p2', 'Leather Office Loafers',
        'Formal slip-on shoes for the workplace'),
    Product('p3', 'Wireless Earbuds', 'Noise-cancelling, 24h battery life'),
    Product('p4', 'Yoga Mat', 'Non-slip, extra thick'),
  ];

  // Embed name + description; rank the whole catalog by the query's meaning.
  final hits = await search.searchObjects<Product>(
    query: 'comfy shoes for jogging',
    items: catalog,
    textOf: (p) => '${p.name}. ${p.description}',
    topK: 2,
  );

  for (final hit in hits) {
    // hit.item is a fully-typed Product.
    // ignore: avoid_print
    print('${hit.item.id}  ${hit.item.name}  '
        '(${hit.score.toStringAsFixed(2)})');
  }
  // Expected top result: p1  Trail Running Shoes

  await search.dispose();
}
