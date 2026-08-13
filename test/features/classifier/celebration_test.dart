import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/classifier/presentation/celebration_overlay.dart';
import 'package:animalspredictor/features/collection/domain/achievement.dart';
import 'package:animalspredictor/features/collection/domain/celebration.dart';
import 'package:animalspredictor/features/collection/presentation/achievement_medal.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:animalspredictor/services/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SettingsController settings;
  late _RecordingSoundService sounds;

  setUp(() async {
    sounds = _RecordingSoundService();
    settings = SettingsController(_SettingsStub(), sounds: sounds);
    await settings.load();
  });

  tearDown(() => settings.dispose());

  /// Abre la celebración desde un botón, como hace la pantalla de la foto.
  Future<void> open(WidgetTester tester, Celebration celebration) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showCelebration(
                context,
                celebration: celebration,
                settings: settings,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pump();
    await tester.pump(MichiTokens.durationShort);
  }

  testWidgets('un animal nuevo se anuncia como nuevo y suena', (tester) async {
    await open(tester, const Celebration(animal: 'Vaca', isNewAnimal: true));

    expect(find.text(TextosNino.celebracionNuevo), findsOneWidget);
    expect(find.text(TextosNino.yaTienes('Vaca')), findsOneWidget);
    expect(find.text(TextosNino.tocaParaSeguir), findsOneWidget);
    expect(sounds.played, [AppSound.saved]);

    await tester.pumpAndSettle();
  });

  testWidgets('un animal repetido no se anuncia como nuevo', (tester) async {
    await open(tester, const Celebration(animal: 'Vaca'));

    expect(find.text(TextosNino.celebracionNuevo), findsNothing);
    expect(find.text(TextosNino.celebracionOtraFoto), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('el invitado no recibe promesas de colección', (tester) async {
    await open(
      tester,
      const Celebration(animal: 'Vaca', savedToCollection: false),
    );

    expect(find.text(TextosNino.guardado), findsOneWidget);
    expect(find.text(TextosNino.yaTienes('Vaca')), findsNothing);
    expect(find.text(TextosNino.celebracionOtraFoto), findsNothing);

    await tester.pumpAndSettle();
  });

  testWidgets('la medalla nueva se enseña con su sonido', (tester) async {
    final medalla = achievementCatalog.first;
    await open(
      tester,
      Celebration(
        animal: 'Vaca',
        isNewAnimal: true,
        newAchievements: [medalla],
      ),
    );

    expect(find.text(TextosNino.medallaNueva), findsOneWidget);
    expect(find.byType(AchievementMedal), findsOneWidget);
    expect(find.text(medalla.label), findsOneWidget);
    expect(sounds.played, [AppSound.achievement]);

    await tester.pumpAndSettle();
  });

  testWidgets('se cierra sola cuando acaba la fiesta', (tester) async {
    const celebration = Celebration(animal: 'Vaca', isNewAnimal: true);
    await open(tester, celebration);

    expect(find.text(TextosNino.tocaParaSeguir), findsOneWidget);
    await tester.pump(celebration.duration);
    await tester.pumpAndSettle();

    expect(find.text(TextosNino.tocaParaSeguir), findsNothing);
  });

  testWidgets('un toque la salta antes de tiempo', (tester) async {
    await open(tester, const Celebration(animal: 'Vaca', isNewAnimal: true));

    await tester.tap(find.text(TextosNino.tocaParaSeguir));
    await tester.pumpAndSettle();

    expect(find.text(TextosNino.yaTienes('Vaca')), findsNothing);
  });

  testWidgets('con el sonido apagado no suena nada', (tester) async {
    await settings.setSoundEnabled(false);

    await open(tester, const Celebration(animal: 'Vaca'));

    expect(sounds.played, isEmpty);

    await tester.pumpAndSettle();
  });
}

class _RecordingSoundService implements SoundService {
  final played = <AppSound>[];

  @override
  Future<void> play(AppSound sound) async => played.add(sound);

  @override
  Future<void> dispose() async {}
}

class _SettingsStub implements SettingsRepository {
  @override
  Future<ProfileSettings> load() async => const ProfileSettings();

  @override
  Future<void> saveHapticsEnabled(bool enabled) async {}

  @override
  Future<void> saveSoundEnabled(bool enabled) async {}

  @override
  Future<void> saveTheme(AppThemePreference theme) async {}
}
