import 'dart:math';

import 'package:flutter/foundation.dart';

/// Operación breve que separa los ajustes de la zona del niño.
///
/// No es una medida de autenticación: solo evita que un niño pequeño llegue
/// por accidente a acciones de cuenta o de borrado.
@immutable
class AdultGateChallenge {
  const AdultGateChallenge({
    required this.leftFactor,
    required this.rightFactor,
  }) : assert(leftFactor >= 10 && leftFactor <= 99),
       assert(rightFactor >= 10 && rightFactor <= 99);

  final int leftFactor;
  final int rightFactor;

  int get answer => leftFactor * rightFactor;

  String get expression => '$leftFactor × $rightFactor';

  bool accepts(String value) => int.tryParse(value.trim()) == answer;

  factory AdultGateChallenge.random([Random? random]) {
    final generator = random ?? Random();
    return AdultGateChallenge(
      leftFactor: 12 + generator.nextInt(28),
      rightFactor: 12 + generator.nextInt(28),
    );
  }
}
