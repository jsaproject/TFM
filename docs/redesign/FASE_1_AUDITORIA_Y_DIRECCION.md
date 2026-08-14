# Fase 1 — auditoría visual y dirección creativa

Fecha de la auditoría: 14 de agosto de 2026  
Estado: en curso — no se ha modificado código de producción.

## Alcance y protección del árbol de trabajo

La fase se limita a la observación, las capturas manuales y esta documentación.
Los cambios locales ya presentes en autenticación, colección, shell, inicio,
perfil y pruebas no pertenecen a esta fase y no se editan ni se incluyen en su
delta. El índice Git estaba vacío al comenzar.

No se añade ninguna dependencia, fuente, asset ni servicio. La clasificación
sigue siendo local; Firebase, permisos, autenticación, persistencia y el
contrato del modelo quedan fuera de alcance.

## Método y matriz de revisión

La fuente de capturas es `test/design/screenshots_test.dart`. Genera de forma
manual acceso, inicio sin foto, colección y perfil con dobles de prueba: no
contacta Firebase, la cámara, la galería ni el modelo. La matriz completa que
debe recopilarse antes de cerrar la fase es la siguiente.

| Tamaño | Claro/oscuro | Escala de texto | Flujos mínimos |
| --- | --- | --- | --- |
| 320 × 568, 360 × 640 | claro y oscuro | 100 % y 200 % | acceso, inicio, foto, resultado, colección, perfil |
| 390 × 844, 430 × 932 | claro y oscuro | 100 % y 200 % | los flujos mínimos y estados de error |
| 768 × 1024, 1180 × 820 | claro y oscuro | 100 % y 200 % | shell con rail, colección, perfil y diálogos |

Además de la imagen, cada recorrido registrará foco de teclado, orden del árbol
semántico, controles menores de 48 px, overflow, texto truncado, salto de
layout, ausencia de reintento y acción duplicable. Las capturas son revisión
manual; no se convierten en goldens versionados en esta fase.

### Baseline generada

El 14 de agosto se ejecutó `MICHI_DESIGN=1 flutter test test/design
--update-goldens` correctamente. Generó cuatro capturas claras a 390 × 844:
`01-acceso.png`, `02-inicio.png`, `03-coleccion.png` y `04-perfil.png` en
`test/design/goldens/` (directorio ignorado por Git).

El arnés independiente `test/design/phase1_states_screenshots_test.dart`
amplía esa baseline sin usar un móvil, Firebase, cámara, galería ni colección
real. Genera también, a 390 × 844 en modo claro, los estados de procesamiento,
resultado reconocido, resultado incierto, error de identificación, permiso de
cámara denegado, colección vacía, colección con error, historial, detalle de
especie, ajustes de invitado y respuesta incorrecta de la puerta adulta. Sus
archivos se generan en `test/design/goldens/fase1/` y siguen sin ser goldens de
regresión versionados.

La foto de esos estados es `assets/vaca.jpg`, cargada localmente por un doble
de `PhotoPickerService`: no representa una foto del usuario ni toca la galería.
En el golden actual, sin embargo, el panel de foto queda en blanco; se registra
como incidencia de decodificación/captura del arnés. Estas imágenes sirven para
revisar estructura y estados, pero no para aprobar todavía el tratamiento de
una fotografía tomada en condiciones reales.

La matriz de inicio contiene 24 variantes: 320 × 568, 360 × 640, 390 × 844,
430 × 932, 768 × 1024 y 1180 × 820, cada una en claro/oscuro y texto 100/200
%. Ha revelado que, en 320 × 568 al 200 %, el título de la aplicación queda
truncado y la cabecera/progreso ocupan prácticamente todo el primer viewport.
No hay overflow de renderizado, pero sí un fallo de accesibilidad visual: fase
3 y fase 4 deberán ofrecer título flexible y composición compacta antes de
aprobar ese tamaño.

Las matrices de Colección y Perfil aportan otras 48 variantes y las de
Acceso y Resultado, 48 más. En total hay 120 renderizados de referencia: las
cinco vistas principales quedan comprobadas en los seis tamaños, ambos temas y
las escalas 100 % y 200 %. Los estados transitorios y de error se mantienen en
la matriz específica a 390 × 844, donde se puede revisar cada mensaje y su
acción de recuperación.

### Accesibilidad automatizada

El arnés comprueba también que las acciones `Haz una foto` y `De mis fotos`
conservan etiqueta semántica, rol de botón, estado habilitado, acción de toque
y foco. Se verifica que el foco de teclado puede entrar en la vista. La puerta
adulta conserva el texto `Solo para adultos` en la interfaz. La comprobación
con lector de pantalla en un dispositivo real queda fuera de esta fase porque
las capturas se realizan sin usar el móvil conectado.

La revisión de esta primera baseline añade estos hallazgos:

- El hero de inicio expone un damero de transparencia en `farm_animals.png`.
  Confirmado en el móvil (`captures/01-actual.png`): no es artefacto del arnés.
  El asset se retira en fase 4 y hasta entonces no se reutiliza.
- En la captura de colección los retratos de especies se renderizan como imagen
  rota. Esto sí es del arnés y ya está aislado: `_Emoji` declara
  `fontFamilyFallback` a Noto, Apple y Segoe Color Emoji, y ninguna de las tres
  existe en el runner de `flutter test`, así que salen cajas vacías. En el móvil
  se ven bien (`captures/02-coleccion-real.png`). No hay nada que sustituir.
- El inicio y el perfil presentan la misma secuencia de panel de progreso,
  tarjeta principal y CTA de pastilla. Confirma la necesidad de diferenciar la
  portada infantil y el área adulta, no de aplicar otro color a la misma card.

## Inventario verificable del estado actual

| Área | Hallazgo | Impacto | Decisión de fase posterior |
| --- | --- | --- | --- |
| Sistema de superficies | Hay 17 usos de `Card` en `lib`; aparecen en clasificador, colección, celebración, perfil y puerta adulta. | La misma jerarquía visual sirve para contenido, error, ajuste y acción. | Fase 2 define `hero`, `photoFrame`, `albumPage`, `statePanel` y `adultSection`; fases 4–7 migran por flujo. |
| Forma | Hay 6 usos de `StadiumBorder`, incluido el botón global y los destinos de navegación. | Las acciones, chips y navegación compiten como pastillas. | Reservar la pastilla a chips, filtros y estados breves; botones y destinos serán rectángulos suaves. |
| Decoración | Hay 7 gradientes y 2 sombras explícitas en `lib`, incluidas navegación, progreso, retrato, resultado, medalla, perfil y bienvenida. | El brillo y el color repetidos distraen de la fotografía y no forman una gramática común. | Retirar gradientes y elevación decorativa en fase 2, salvo una excepción documentada que comunique estado. |
| Color y tipografía | `MichiTokens` centraliza una paleta cálida, espaciado, radios, motion, Andika y Atkinson Hyperlegible. | Es una base reutilizable, pero nombra colores más que roles y mantiene decisiones globales que no sirven a todas las superficies. | Conservar las dos fuentes y evolucionar los tokens a roles semánticos. |
| Responsive | El shell ya cambia a `NavigationRail` desde 840 px y conserva las pestañas con `IndexedStack`. Varios flujos limitan el contenido a 600 px. | La navegación está bien encaminada; el lienzo de tablet se desaprovecha. | Fase 3 mantiene la navegación y permite composiciones editoriales hasta 1200 px. |
| Estados | El controlador del clasificador ya diferencia carga, foto, procesamiento, resultado, no reconocido y error; colección y perfil ya tienen error y reintento. | La cobertura funcional existe, pero los estados no comparten un lenguaje visual reconocible. | Fase 2 define el panel de estado; fases 4–7 lo aplican sin cambiar reglas de negocio. |
| Lenguaje infantil | `TextosNino` evita porcentajes y expresa incertidumbre con «No lo sé», «Creo que es» y «Puedes cambiarlo». | La base es honesta y no culpabiliza; falta comprobarla en cada composición y estado visual. | Mantener el tono; revisar etiquetas de baja confianza, error y permisos al rediseñar cada flujo. |

### Assets de animales

El detalle de procedencia y la decisión por archivo está en
`docs/redesign/ASSETS_FASE_1.md`.

El catálogo vigente contiene 28 especies y siete tienen `imageAsset`: Vaca,
Caballo, Oveja, Gallina, Perro, Gato y Elefante. **En el álbum eso no se nota:
los 28 salen como emoji.** El retrato de la cuadrícula lo pinta
`AnimalPortrait`, que ignora `imageAsset` por completo (`animal_image.dart:48`);
las siete fotos solo las usa `AnimalImage`, reservado a la ficha de detalle. El
propio fichero explica por qué se hizo así: mezclar siete fotos con veintiuna
láminas dejaba la cuadrícula a medias.

Decisión: **no retirar todavía los emojis ni los assets actuales**. Los 28
dibujos ya están encargados a la hermana de Juan (docs/PLAN_UX_INFANTIL.txt,
PROBLEMA 3.0) y en fase 6 se integran: declarar `assets/animales/`, rellenar los
28 `imageAsset` y hacer que `AnimalPortrait` use la ilustración. No hay que
buscar fotos ni packs de iconos. El fallback se conserva para el catálogo
heredado.

| Asset actual | Estado | Acción futura |
| --- | --- | --- |
| `assets/vaca.jpg`, `caballo.jpg`, `oveja.jpg`, `gallina.jpg`, `perro.jpg`, `gato.jpg`, `elefante.jpg` | Solo se ven en la ficha de detalle; el álbum no las usa. | Retirar del catálogo vigente cuando lleguen los 28 dibujos, para no mezclar foto e ilustración en el mismo registro. |
| `assets/arana.jpg`, `ardilla.jpg`, `mariposa.jpg`, `granja.jpg` | Muestras del modelo y entradas heredadas, no del catálogo de 28. | Mantener donde están; no son retratos. |
| `assets/farm_animals.png` | Hero actual de Inicio, con damero de transparencia visible en el móvil. | Retirar en fase 4. No reutilizar. |
| Icono de aplicación | Marca. | Conservar; auditar aparte si algún día se publica. |
| Tipografías Andika y Atkinson Hyperlegible | Empaquetadas localmente con archivos OFL. | Conservar; probar tildes, ñ, cifras, controles y escala al 200 %. |

## Tablero local de dirección creativa

### Principios aprobables

- **Cuaderno de campo, no disfraz:** papel cálido, etiquetas de observación y
  marcos fotográficos solo cuando expliquen contenido, procedencia o progreso.
- **Una protagonista por vista:** en exploración y resultado manda la foto; en
  álbum manda la cuadrícula; en ajustes manda la organización y la legibilidad.
- **Color con función:** terracota para una acción primaria, verde para avance
  confirmado, miel para hallazgo y rojo únicamente para peligro o error.
- **Dos niveles de expresividad:** infantil, luminoso y editorial al explorar;
  adulto, sobrio y denso para cuenta, privacidad y acciones sensibles.
- **Honestidad amable:** cuando el modelo no reconoce una foto, se ofrece
  repetir, mejorar la toma o elegir manualmente sin atribuir el resultado al
  niño.

### Paleta y letra de referencia

| Rol | Claro | Oscuro | Uso |
| --- | --- | --- | --- |
| Papel | `#FFFAF3` | `#16130F` | Fondo de lectura y páginas de álbum. |
| Tinta | `#231C15` | `#F3E9DD` | Texto principal y contorno con contraste. |
| Acción primaria | `#F76707` | `#FFB077` | Una CTA principal por estado. |
| Progreso | `#37B24D` | `#7CD98F` | Colección conseguida y confirmación. |
| Hallazgo | `#F5A623` | `#FFD166` | Medallas y descubrimientos nuevos. |
| Riesgo | `#C92A2A` | `#FFB4AB` | Error, borrado y zona sensible. |

Andika queda reservada para titulares y nombres de animal; Atkinson
Hyperlegible para cuerpo, formularios, filtros, metadatos y controles. Los
tamaños no se fijarán en contenedores de altura rígida y deben revisarse con
`TextScaler` al 200 %.

### Tres composiciones clave

| Composición | Estructura | Jerarquía | Restricciones |
| --- | --- | --- | --- |
| Portada de exploración | Saludo breve + progreso compacto + marco de foto dominante + CTA integrada + alternativa de galería. | Foto/CTA, después progreso, después consejos. | Sin pila de tarjetas; cámara y galería siguen detrás de `PhotoPickerService`. |
| Resultado | Foto tomada en marco editorial + nombre propuesto + explicación sencilla + confirmar/corregir. | Foto y decisión, después alternativas y sonido. | Incertidumbre no usa verde ni éxito; la confirmación conserva bloqueo ante doble envío. |
| Álbum | Cabecera de progreso continua + filtros compactos + cuadrícula de láminas. | Colección y próxima oportunidad, después filtros, después fichas. | Grid lazy, retratos locales y pendiente legible sin depender solo de opacidad o color. |

### Estados y área adulta

Los estados de carga, error, vacío, offline y permiso compartirán icono con
nombre accesible, explicación breve, consecuencia clara y una acción de
recuperación. No se usarán como una tarjeta genérica con un color distinto.

El área adulta agrupará cuenta, apariencia, permisos, privacidad e información
en secciones con divisores. El cierre de sesión queda al final y la eliminación
en una zona sensible separada, con rojo limitado al aviso y la acción
destructiva.

## Componentes cerrados para fase 2

1. Tokens semánticos de color, superficie, borde, foco, spacing, radio,
   tamaño táctil, breakpoint y motion.
2. Botón primario, secundario y destructivo de rectángulo suave; chip de filtro
   y badge de estado como únicas pastillas intencionadas.
3. `StatePanel`, único para carga, vacío, error, offline y permisos.
4. Marco de foco visible.

`PhotoFrame`, `HeroSection`, `AlbumPage` y `AdultSection` **no** entran en la
fase 2: nacen en la fase que las estrena (4, 6 y 7), con su primer consumidor
delante. Definirlas antes es inventar componentes a ciegas, que es un riesgo que
esta misma auditoría ya señalaba.

El contrato de los 28 dibujos se cierra con la hermana de Juan antes de la fase
2, con los añadidos de la sección 5 del plan (modo oscuro, tamaño maestro, peso
y nombre de fichero).

## Riesgos, pendientes y criterio de salida

La fase queda lista para aprobación: cada flujo principal tiene captura, las
120 variantes cubren tema y escala de texto en los tamaños acordados, y el
inventario conserva la decisión y la trazabilidad disponible de cada candidato.
La única reserva es la validación de lector de pantalla en un dispositivo real,
que requeriría usar el móvil y no forma parte de este arnés local.

Verificación final superada el 14 de agosto de 2026:

- `dart format --output=none --set-exit-if-changed lib test` sin cambios.
- `flutter analyze` sin incidencias.
- `flutter test`: 109 pruebas superadas y 18 capturas de diseño omitidas por
  defecto (solo se generan con `MICHI_DESIGN=1`).
- `flutter build apk --debug`: APK de depuración generado correctamente.
