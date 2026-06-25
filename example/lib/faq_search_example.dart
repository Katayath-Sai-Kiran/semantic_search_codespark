// Scenario: search a fixed list of help-desk topics by MEANING.
//
// Notice the queries share no words with the matching topic — keyword or fuzzy
// search would return nothing here.
//
// Run after `flutter pub get`:  dart run example/lib/faq_search_example.dart
import 'package:semantic_search_codespark/semantic_search_codespark.dart';

Future<void> main() async {
  final search = SemanticSearch();
  await search.initialize(); // downloads + caches the model on first run

  const faqs = [
    'Reset your password',
    'Track your order',
    'Cancel a subscription',
    'Request a refund',
    'Update billing information',
  ];

  const queries = [
    'I forgot my login details', // -> Reset your password
    'where is my parcel', // -> Track your order
    'stop charging me every month', // -> Cancel a subscription
  ];

  for (final query in queries) {
    final hits = await search.search(query: query, items: faqs, topK: 1);
    // ignore: avoid_print
    print('"$query"  ->  "${hits.first.item}"  '
        '(${hits.first.score.toStringAsFixed(2)})');
  }

  await search.dispose();
}
