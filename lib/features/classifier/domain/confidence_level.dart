/// Cómo de seguro está el resultado, en tres niveles y sin números.
///
/// Un niño de 4 a 8 años no lee "confianza: 87,3 %". Esta es la única
/// traducción de la probabilidad del modelo a algo que se pueda enseñar en
/// pantalla; las pantallas no vuelven a mirar el número.
enum ConfidenceLevel {
  /// El modelo acierta y va sobrado.
  sure,

  /// El modelo acierta, pero por poco: conviene invitar a corregir.
  almostSure,

  /// El modelo no reconoce la foto con garantías.
  unsure;

  /// A partir de aquí el resultado se enseña como seguro.
  static const sureThreshold = 0.8;

  static ConfidenceLevel of({
    required bool reliable,
    required double confidence,
  }) {
    if (!reliable) return ConfidenceLevel.unsure;
    return confidence >= sureThreshold
        ? ConfidenceLevel.sure
        : ConfidenceLevel.almostSure;
  }
}
