import 'package:flutter/material.dart';
import 'package:semantic_search_codespark/semantic_search_codespark.dart';

void main() => runApp(const DemoApp());

/// A small fixed corpus chosen to exercise the validated demos:
/// synonyms (car→automobile, doctor→physician) and a zero-overlap
/// sentence match (I forgot my login details → Reset your password).
const _corpus = <String>[
  'Automobile',
  'Bicycle',
  'Physician',
  'Registered nurse',
  'Software engineer',
  'Reset your password',
  'Track your package',
  'Return and refund policy',
  'Shipping and delivery times',
  'Banana smoothie recipe',
  'Mountain hiking trip',
  'Update account information',
];

const _suggestions = <String>[
  'car',
  'doctor',
  'I forgot my login details',
  'when will it arrive',
];

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'semantic_search_codespark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF5B6CFF),
        useMaterial3: true,
      ),
      home: const SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _search = SemanticSearch();
  final _controller = TextEditingController();

  SemanticIndex<String>? _index;
  String _status = 'Starting…';
  double? _progress; // 0..1 download progress, null when indeterminate/done
  bool _ready = false;
  List<SemanticResult<String>> _results = const [];

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      setState(() => _status = 'Downloading model (first run only)…');
      await _search.initialize(onProgress: (received, total) {
        if (total > 0) setState(() => _progress = received / total);
      });
      setState(() => _status = 'Indexing ${_corpus.length} items…');
      _index = await _search.createIndex(items: _corpus, textOf: (s) => s);
      setState(() {
        _ready = true;
        _status = 'Ready — search by meaning, offline.';
      });
    } catch (e) {
      setState(() => _status = 'Failed to start: $e');
    }
  }

  Future<void> _runSearch(String query) async {
    if (!_ready || query.trim().isEmpty) {
      setState(() => _results = const []);
      return;
    }
    final hits = await _index!.search(query, topK: 5, threshold: 0.15);
    // Printed so a headless run can verify the real model end-to-end.
    debugPrint('QUERY "$query" -> '
        '${hits.map((h) => '${h.item}(${h.score.toStringAsFixed(3)})').join(', ')}');
    if (mounted) setState(() => _results = hits);
  }

  @override
  void dispose() {
    _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Semantic Search — offline, no API keys'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              enabled: _ready,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Type a query, e.g. "doctor"',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: _runSearch,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final s in _suggestions)
                  ActionChip(
                    label: Text(s),
                    onPressed: _ready
                        ? () {
                            _controller.text = s;
                            _runSearch(s);
                          }
                        : null,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _StatusBar(status: _status, ready: _ready, progress: _progress),
            const Divider(),
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Text(
                        _ready
                            ? 'Try a query or tap a suggestion.'
                            : 'Preparing…',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ResultTile(_results[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String status;
  final bool ready;
  final double? progress;
  const _StatusBar(
      {required this.status, required this.ready, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (!ready)
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, value: progress),
          ),
        if (!ready) const SizedBox(width: 10),
        Expanded(
          child: Text(
            !ready && progress != null
                ? '$status ${(progress! * 100).round()}%'
                : status,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  final SemanticResult<String> result;
  const _ResultTile(this.result);

  @override
  Widget build(BuildContext context) {
    final score = result.score.clamp(0.0, 1.0);
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(result.item),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: LinearProgressIndicator(value: score),
        ),
        trailing: Text(result.score.toStringAsFixed(3),
            style: Theme.of(context).textTheme.labelLarge),
      ),
    );
  }
}
