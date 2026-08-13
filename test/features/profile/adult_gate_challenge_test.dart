import 'package:animalspredictor/features/profile/domain/adult_gate_challenge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('acepta únicamente el resultado de la multiplicación', () {
    const challenge = AdultGateChallenge(leftFactor: 14, rightFactor: 23);

    expect(challenge.expression, '14 × 23');
    expect(challenge.accepts('322'), isTrue);
    expect(challenge.accepts(' 322 '), isTrue);
    expect(challenge.accepts('321'), isFalse);
    expect(challenge.accepts('no es un número'), isFalse);
  });
}
