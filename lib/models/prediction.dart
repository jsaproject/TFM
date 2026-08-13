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
    this.reliable,
  }) : alternatives = List.unmodifiable(alternatives);

  final Prediction primary;
  final List<Prediction> alternatives;

  /// Evidencia de que la foto no contiene un animal admitido por el catálogo.
  final double notAnimalConfidence;

  /// Decisión calibrada por el modelo, si este dispone de rechazo abierto.
  /// Los clasificadores antiguos dejan el valor nulo y usan la heurística
  /// histórica de confianza en el controlador.
  final bool? reliable;

  /// Cierto cuando el modelo ve con más fuerza algo fuera del catálogo.
  bool get looksLikeSomethingElse => notAnimalConfidence > primary.confidence;
}
