class Prediction {
  const Prediction({required this.animal, required this.confidence});

  final String animal;
  final double confidence;
}

class ClassificationResult {
  ClassificationResult({
    required this.primary,
    required List<Prediction> alternatives,
    this.notAnimalConfidence = 0,
  }) : alternatives = List.unmodifiable(alternatives);

  final Prediction primary;
  final List<Prediction> alternatives;

  /// Probabilidad de que la foto no contenga ninguno de los animales del
  /// catálogo, sumando las clases de ImageNet que no son animales.
  final double notAnimalConfidence;

  /// Cierto cuando el modelo ve con más fuerza algo que no es un animal.
  bool get looksLikeSomethingElse => notAnimalConfidence > primary.confidence;
}
