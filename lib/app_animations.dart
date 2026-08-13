import 'package:animalspredictor/app_theme.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Entrada de los bloques de una pantalla.
///
/// Aparecen subiendo un poco y uno detrás de otro, de arriba abajo, para que
/// la pantalla se lea en orden en vez de aterrizar de golpe. Es la única
/// animación de la interfaz de fondo: las fiestas (celebración y medallas)
/// tienen la suya.
extension MichiEntrance on Widget {
  /// [step] es el puesto del bloque en la pantalla: 0 el primero, 1 el
  /// siguiente… Cada puesto entra un pelín después que el anterior.
  Widget entrance({int step = 0}) => animate()
      .fadeIn(
        duration: MichiTokens.durationEntrance,
        delay: MichiTokens.delayEntranceStep * step,
      )
      .slideY(
        begin: MichiTokens.entranceOffset,
        end: 0,
        duration: MichiTokens.durationEntrance,
        delay: MichiTokens.delayEntranceStep * step,
        curve: Curves.easeOutCubic,
      );
}
