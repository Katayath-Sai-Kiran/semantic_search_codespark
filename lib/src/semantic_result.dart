/// One ranked hit: the original [item], its semantic similarity [score]
/// (cosine, roughly 0–1 — higher is closer), and its [index] in the input list.
class SemanticResult<T> {
  final T item;
  final double score;
  final int index;

  const SemanticResult({
    required this.item,
    required this.score,
    required this.index,
  });

  @override
  String toString() => 'SemanticResult($item, ${score.toStringAsFixed(3)})';
}
