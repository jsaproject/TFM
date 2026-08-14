# Prompt — Fase 2: sistema de diseño profesional

Actúa como desarrollador Flutter senior, diseñador de sistemas y especialista
en accesibilidad. Implementa **únicamente la fase 2** del rediseño visual de
La granja de Michi: el sistema de diseño profesional. No inicies las fases 3 a
8 ni rediseñes flujos completos de producto.

## Contexto ya aprobado

La fase 1 está documentada en `docs/redesign/FASE_1_AUDITORIA_Y_DIRECCION.md`
y el plan completo en `docs/PLAN_REDISENO_VISUAL.txt`. La dirección de arte es
«el cuaderno de campo de Michi»: papel cálido, fotografía como protagonista,
composición editorial con aire, Andika para titulares y Atkinson Hyperlegible
para lectura y controles. La app es para niños de 6 a 10 años; el área adulta
debe ser más sobria, sin perder coherencia de marca.

Hallazgo obligatorio de fase 1: en Inicio a 320 × 568 con texto al 200 %, el
título se trunca. El sistema debe evitar estilos o componentes con alturas
rígidas que perpetúen ese problema.

## Límites no negociables

- Antes de decidir, ejecuta `git diff --cached`, `git status --short` y revisa
  solo el delta que sea de esta fase. El árbol contiene cambios locales ajenos:
  no los sobrescribas, reformatees ni mezcles.
- No cambies el modelo local, sus umbrales, permisos, Firebase, autenticación,
  persistencia, navegación, contratos de servicios ni comportamiento de los
  flujos.
- No añadas dependencias, fuentes, fotos ni otros assets. Reutiliza Flutter
  Material 3, `flutter_animate`, Andika y Atkinson ya presentes. Si crees que
  hace falta una dependencia, detente y presenta antes su ficha de evaluación;
  no la instales.
- No introduzcas I/O, Firebase, cámara, galería, permisos, TFLite o reglas de
  negocio en widgets nuevos. Los componentes serán presentacionales y puros.
- No uses emojis como iconos de interfaz, gradientes saturados, brillos o
  sombras decorativas. No uses `StadiumBorder` salvo en chips o badges breves.
- Mantén modo claro/oscuro, contraste WCAG AA, foco visible, semántica,
  navegación por teclado y dianas táctiles de al menos 48 × 48 px.
- Mantén todos los textos y etiquetas accesibles en español, centralizados en
  `lib/l10n/textos.dart` cuando se incorporen textos nuevos.

## Objetivo concreto

Crear una gramática visual compacta, reutilizable y verificable. Debe permitir
que las fases posteriores compongan una portada, un marco de foto, un álbum,
paneles de estado y ajustes de adulto sin convertir toda la app en una pila de
cards genéricas.

## Implementa

1. Evoluciona `MichiTokens`/`MichiTheme` hacia tokens semánticos, sin romper
   consumidores existentes. Puedes crear `lib/design_system/` si reduce
   acoplamiento; conserva reexportaciones o adaptadores temporales para una
   migración incremental.

2. Define para claro y oscuro, como mínimo:

   - color: `paper`, `ink`, `actionPrimary`, `progress`, `discovery`, `danger`,
     `border`, `focus` y superficies tonales;
   - tipografía: Andika para títulos/nombres de especie y Atkinson para cuerpo,
     formularios, metadatos y controles;
   - espaciado, radios suaves, borde, elevación mínima, dianas táctiles,
     breakpoints, proporciones de imagen y duración de movimiento;
   - estados enabled, disabled, pressed, hovered y focused.

3. Crea componentes presentacionales pequeños y documentados, sin servicios:

   - botón primario, secundario y destructivo de rectángulo suave;
   - chip de filtro y badge de estado como únicas pastillas intencionadas;
   - `PhotoFrame`, `HeroSection`, `AlbumPage`, `StatePanel` y `AdultSection`;
   - encabezado editorial y progreso compacto;
   - estilo de navegación Material adaptativa que conserve su comportamiento
     actual, pero sin gradientes, brillo ni destinos tipo pastilla.

4. Aplica el sistema solo donde sea necesario para demostrarlo: tema, piezas
   compartidas y catálogo de pruebas. No conviertas todavía Inicio, Resultado,
   Colección o Perfil en los rediseños completos de fases posteriores.

5. Respeta la reducción de movimiento con
   `MediaQuery.disableAnimations`: la animación no esencial se reduce o se
   elimina. No anuncies progreso ficticio ni cambies la duración de operaciones
   reales.

6. Prepara una especificación de assets en documentación: proporción, recorte,
   peso, compresión, licencia, procedencia y etiqueta semántica. No incorpores
   aún fotos para las 28 especies; sigue la decisión de
   `docs/redesign/ASSETS_FASE_1.md`.

## Pruebas obligatorias

- Añade o actualiza tests de tema, contraste y componentes. Comprueba estados
  disabled/focused/pressed, semántica y foco por teclado.
- Añade un catálogo de widgets exclusivamente para pruebas, no una ruta de
  depuración en release.
- Genera capturas o goldens deterministas del catálogo a 320, 390, 768 y
  1180 px, en claro/oscuro y texto 100/200 %.
- Verifica en especial que los títulos y las CTAs no se truncan al 200 % y que
  no hay overflow.
- Ejecuta y comunica el resultado de:

  ```text
  dart format --output=none --set-exit-if-changed lib test
  flutter analyze
  flutter test
  flutter build apk --debug
  ```

## Criterios de cierre

- No quedan colores hexadecimales ni medidas visuales repetidas en componentes
  compartidos, salvo una razón semántica documentada.
- Todos los pares de texto/superficie usados por el sistema alcanzan WCAG AA.
- Botón, filtro, marco editorial, panel de estado y sección adulta se
  distinguen por estructura además de color.
- No hay emojis como iconos de interfaz, ni gradientes/brillos no justificados.
- Claro, oscuro, foco, reducción de movimiento y texto al 200 % pasan las
  pruebas del catálogo.
- La app termina formateada, analizable, testeable y compilable.

Al finalizar, entrega: qué cambió, archivos modificados, dependencias/assets
añadidos (deberían ser ninguno), capturas generadas, resultados exactos de las
comprobaciones, riesgos o pendientes. Espera aprobación antes de empezar la
fase 3.
