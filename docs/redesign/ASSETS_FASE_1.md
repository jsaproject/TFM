# Inventario de assets visuales — fase 1

Fecha: 14 de agosto de 2026  
Estado: auditoría; este documento no autoriza eliminar ni redistribuir assets.

## Regla de decisión

La app no se publica ni se distribuye, así que la procedencia de un asset no es
hoy un problema legal. Lo que sí importa es que se vea bien y que el conjunto
sea coherente: un recorte de banco de imágenes con damero de transparencia sobra
por cómo se ve, no por su licencia.

Regla práctica: un asset heredado se conserva mientras no estorbe, y se retira
en cuanto tenga sustituto o se note. Si algún día se publica, esta tabla es el
punto de partida para revisar procedencias.

## Fotografías y gráficos de interfaz

| Archivo | Uso actual | Procedencia/licencia registrada | Estado de fase 1 | Decisión |
| --- | --- | --- | --- | --- |
| `assets/vaca.jpg` | Retrato de Vaca y muestra de modelo. | No documentada. | Pendiente. | Conservar temporalmente; sustituir o acreditar. |
| `assets/caballo.jpg` | Retrato de Caballo y muestra de modelo. | No documentada. | Pendiente. | Conservar temporalmente; sustituir o acreditar. |
| `assets/oveja.jpg` | Retrato de Oveja y muestra de modelo. | No documentada. | Pendiente. | Conservar temporalmente; sustituir o acreditar. |
| `assets/gallina.jpg` | Retrato de Gallina y muestra de modelo. | No documentada. | Pendiente. | Conservar temporalmente; sustituir o acreditar. |
| `assets/perro.jpg` | Retrato de Perro y muestra de modelo. | No documentada. | Pendiente. | Conservar temporalmente; sustituir o acreditar. |
| `assets/gato.jpg` | Retrato de Gato y muestra de modelo. | No documentada. | Pendiente. | Conservar temporalmente; sustituir o acreditar. |
| `assets/elefante.jpg` | Retrato de Elefante y muestra de modelo. | No documentada. | Pendiente. | Conservar temporalmente; sustituir o acreditar. |
| `assets/arana.jpg`, `ardilla.jpg`, `mariposa.jpg` | Entradas heredadas y muestras de rechazo del modelo. | No documentada. | Pendiente; no completan el catálogo vigente. | Mantener para pruebas de modelo; no usar como retrato final. |
| `assets/granja.jpg` | Muestra de rechazo del modelo. | No documentada. | Pendiente. | Mantener para prueba; no reutilizar en UI sin acreditar. |
| `assets/farm_animals.png` | Hero actual de Inicio. | No documentada. | Sustituir. | No usar en el rediseño: expone un damero de transparencia en la captura. |
| `assets/icon/icon.png` | Icono de la aplicación. | No documentada. | Pendiente. | Conservar hasta su auditoría específica. |

## Fuentes y sonido

| Recurso | Evidencia | Decisión |
| --- | --- | --- |
| Andika | `assets/fonts/Andika-OFL.txt` (SIL OFL 1.1). | Conservar. |
| Atkinson Hyperlegible | `assets/fonts/OFL.txt` (SIL OFL 1.1). | Conservar. |
| Voces de animales | `assets/sonidos/animales/ATTRIBUTIONS.md`. | Conservar; mantener la atribución con cada redistribución. |

## Estrategia para fase 6

Los 28 retratos no se buscan: los dibuja la hermana de Juan y el encargo está en
`docs/PLAN_UX_INFANTIL.txt`, PROBLEMA 3.0. Del lado del código queda declarar
`assets/animales/` en `pubspec.yaml`, rellenar los 28 `imageAsset` y hacer que
`AnimalPortrait` use la ilustración en vez del emoji.

Lo que hay que cerrar con ella antes de la fase 2 está en la sección 5 del plan:
cuadrados con escala normalizada, estilo único, legibles a 96 dp, fondo
transparente, maestro de 1024x1024, WebP de unos 120 KB, nombre de fichero
derivado del catálogo, y superficie clara detrás en los dos temas para que un
dibujo de línea oscura no se pierda en modo oscuro.

Cuando lleguen, se retiran los siete JPG del catálogo vigente: mezclar foto e
ilustración en la misma cuadrícula es justo lo que ya se descartó una vez.
