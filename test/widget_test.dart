import 'package:animalspredictor/sign_in_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el acceso', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SignInPage()));
    expect(find.text('La granja de Michi'), findsOneWidget);
  });
}
