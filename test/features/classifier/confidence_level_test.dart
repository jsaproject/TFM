import 'package:animalspredictor/features/classifier/domain/confidence_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un resultado no fiable siempre es "no lo sé"', () {
    expect(
      ConfidenceLevel.of(reliable: false, confidence: 0.99),
      ConfidenceLevel.unsure,
    );
  });

  test('un resultado fiable y alto es "seguro"', () {
    expect(
      ConfidenceLevel.of(reliable: true, confidence: 0.9),
      ConfidenceLevel.sure,
    );
    expect(
      ConfidenceLevel.of(
        reliable: true,
        confidence: ConfidenceLevel.sureThreshold,
      ),
      ConfidenceLevel.sure,
    );
  });

  test('un resultado fiable pero justo es "casi seguro"', () {
    expect(
      ConfidenceLevel.of(reliable: true, confidence: 0.55),
      ConfidenceLevel.almostSure,
    );
  });
}
