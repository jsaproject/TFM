import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/profile/domain/adult_gate_challenge.dart';
import 'package:animalspredictor/features/profile/presentation/adult_gate.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('no abre los ajustes con un resultado incorrecto', (
    tester,
  ) async {
    var unlocked = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: MichiTheme.light(),
        home: Scaffold(
          body: AdultGate(
            challenge: const AdultGateChallenge(
              leftFactor: 14,
              rightFactor: 23,
            ),
            onUnlocked: () => unlocked = true,
          ),
        ),
      ),
    );

    expect(find.text('¿Cuánto es 14 × 23?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '321');
    await tester.tap(find.byKey(const Key('adult-gate-submit')));
    await tester.pump();

    expect(unlocked, isFalse);
    expect(find.text(TextosAdulto.puertaAdultosError), findsOneWidget);
  });

  testWidgets('abre los ajustes con el resultado correcto', (tester) async {
    var unlocked = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: MichiTheme.light(),
        home: Scaffold(
          body: AdultGate(
            challenge: const AdultGateChallenge(
              leftFactor: 14,
              rightFactor: 23,
            ),
            onUnlocked: () => unlocked = true,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '322');
    await tester.tap(find.byKey(const Key('adult-gate-submit')));
    await tester.pump();

    expect(unlocked, isTrue);
  });
}
