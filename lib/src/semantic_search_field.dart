import 'dart:async';

import 'package:flutter/material.dart';

import 'semantic_index.dart';
import 'semantic_result.dart';

/// A drop-in search field that ranks a [SemanticIndex] by meaning as the user
/// types — debounced, off-the-UI-thread, with your own result widgets.
///
/// Build the index once (see [SemanticSearch.createIndex] /
/// [SemanticSearch.loadIndex]), then hand it to this widget:
///
/// ```dart
/// SemanticSearchField<Faq>(
///   index: faqIndex,
///   hintText: 'Ask a question…',
///   onResultTap: (r) => openFaq(r.item),
///   resultBuilder: (context, r) => ListTile(
///     title: Text(r.item.title),
///     trailing: Text(r.score.toStringAsFixed(2)),
///   ),
/// )
/// ```
class SemanticSearchField<T> extends StatefulWidget {
  const SemanticSearchField({
    super.key,
    required this.index,
    required this.resultBuilder,
    this.onResultTap,
    this.controller,
    this.topK = 10,
    this.threshold,
    this.debounce = const Duration(milliseconds: 250),
    this.decoration,
    this.hintText = 'Search by meaning…',
    this.autofocus = false,
    this.padding = const EdgeInsets.all(12),
    this.expandResults = true,
    this.idleBuilder,
    this.loadingBuilder,
    this.emptyBuilder,
  });

  /// The pre-built, ready-to-query index.
  final SemanticIndex<T> index;

  /// Builds the widget for one ranked result.
  final Widget Function(BuildContext context, SemanticResult<T> result)
      resultBuilder;

  /// Called when a result is tapped. If null, results are not tappable
  /// (wrap them yourself inside [resultBuilder]).
  final void Function(SemanticResult<T> result)? onResultTap;

  /// Optional external controller for the text field.
  final TextEditingController? controller;

  /// Max results to show.
  final int topK;

  /// Optional minimum cosine score (0–1).
  final double? threshold;

  /// How long to wait after the last keystroke before searching.
  final Duration debounce;

  /// Overrides the default [InputDecoration].
  final InputDecoration? decoration;

  /// Hint shown when [decoration] is not provided.
  final String hintText;

  final bool autofocus;

  /// Padding around the field and the results list.
  final EdgeInsetsGeometry padding;

  /// When true, results fill the remaining space (use in a [Scaffold] body).
  /// When false, the list shrink-wraps (use inline inside a scroll view).
  final bool expandResults;

  /// Shown before the user has typed anything.
  final WidgetBuilder? idleBuilder;

  /// Shown while a search is running and there are no prior results.
  final WidgetBuilder? loadingBuilder;

  /// Shown when a query returns no results.
  final WidgetBuilder? emptyBuilder;

  @override
  State<SemanticSearchField<T>> createState() => _SemanticSearchFieldState<T>();
}

class _SemanticSearchFieldState<T> extends State<SemanticSearchField<T>> {
  late final TextEditingController _controller;
  Timer? _debounce;
  List<SemanticResult<T>> _results = const [];
  bool _searching = false;
  bool _dirty = false; // a non-empty query has been issued
  int _seq = 0; // guards against out-of-order async results

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      setState(() {
        _results = const [];
        _dirty = false;
        _searching = false;
      });
      return;
    }
    if (widget.debounce == Duration.zero) {
      _run(q);
    } else {
      _debounce = Timer(widget.debounce, () => _run(q));
    }
  }

  Future<void> _run(String query) async {
    final seq = ++_seq;
    setState(() {
      _searching = true;
      _dirty = true;
    });
    final hits = await widget.index
        .search(query, topK: widget.topK, threshold: widget.threshold);
    if (!mounted || seq != _seq) return; // superseded by a newer keystroke
    setState(() {
      _results = hits;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final results = _buildResults(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: widget.expandResults ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Padding(padding: widget.padding, child: _buildField(context)),
        if (widget.expandResults) Expanded(child: results) else results,
      ],
    );
  }

  Widget _buildField(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: widget.decoration ??
          InputDecoration(
            hintText: widget.hintText,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: _searching
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      )
                    : null),
          ),
    );
  }

  Widget _buildResults(BuildContext context) {
    if (!_dirty) {
      return widget.idleBuilder?.call(context) ?? const SizedBox.shrink();
    }
    if (_searching && _results.isEmpty) {
      return widget.loadingBuilder?.call(context) ?? const SizedBox.shrink();
    }
    if (_results.isEmpty) {
      return widget.emptyBuilder?.call(context) ??
          const Center(
            child: Padding(padding: EdgeInsets.all(24), child: Text('No matches.')),
          );
    }
    return ListView.builder(
      shrinkWrap: !widget.expandResults,
      physics:
          widget.expandResults ? null : const NeverScrollableScrollPhysics(),
      padding: widget.padding,
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final r = _results[i];
        final child = widget.resultBuilder(context, r);
        if (widget.onResultTap == null) return child;
        return InkWell(onTap: () => widget.onResultTap!(r), child: child);
      },
    );
  }
}
