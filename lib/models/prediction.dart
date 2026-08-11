class Prediction {
  const Prediction({required this.animal, required this.confidence});

  final String animal;
  final double confidence;
}

class ClassificationResult {
  ClassificationResult({
    required this.primary,
    required List<Prediction> alternatives,
  }) : alternatives = List.unmodifiable(alternatives);

  final Prediction primary;
  final List<Prediction> alternatives;
}
