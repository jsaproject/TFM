# Línea base antes del modelo nuevo

Fecha: 2026-08-12.

## Artefacto actual

| Campo | Valor medido o verificado |
|---|---|
| Arquitectura | MobileNetV4-Conv-Medium, ImageNet-1k |
| Modelo | `assets/model_mnv4.tflite` |
| SHA-256 | `3240c1d77bf5b534736bf8c19a86b78fe87c2198010327c2b46cf53cff36cb90` |
| Tamaño | 19.427.662 bytes (18,53 MiB) |
| Entrada | `[1, 224, 224, 3]`, float32 |
| Normalización de la app | `(pixel - 127,5) / 127,5` |
| Salida | `[1, 1000]`, float32, logits |
| Etiquetas | 1.000 líneas en `assets/labels_imagenet.txt` |
| Agrupación posterior | 42 grupos en `assets/imagenet_animal_groups.json` |

La comprobación con el intérprete local confirma la forma y tipos de los
tensores. La documentación existente registra 74/81 aciertos en su banco de
fotografías y 3/10 en ilustraciones. No existe aún un conjunto de prueba
cerrado y representativo de los 28 animales nuevos.

El caso comunicado `caballo -> perro` se conserva como regresión requerida,
pero la imagen original no se ha copiado al repositorio porque no consta su
licencia. Tendrá que reproducirse con imágenes del futuro test autorizado.

## Medición en Android

Dispositivo Samsung SM-S918B, Android API 36, `arm64-v8a`, cuatro hilos,
XNNPACK, cinco calentamientos y al menos 50 ejecuciones. La herramienta terminó
81 ejecuciones para satisfacer también su duración mínima.

| Métrica | Resultado |
|---|---:|
| Inicialización | 52,871 ms |
| Primera inferencia | 43,249 ms |
| Media | 12,352 ms |
| Mediana | 12,415 ms |
| p95 | 12,816 ms |
| Incremento aproximado de memoria | 65,84 MiB |

## Estado previo de Flutter

- Flutter 3.44.9 estable, Dart 3.12.2.
- `flutter analyze`: falla con 57 incidencias. La causa dominante son imports
  a tres ficheros de perfil que no existen en el árbol de trabajo actual:
  `settings_repository.dart`, `permission_service.dart` y
  `model_information.dart`.
- `flutter test`: 26 pruebas pasan y 2 fallan. Una no compila por los mismos
  imports ausentes; otra no encuentra la semántica esperada `Perro, 1 foto`.
- No se intenta atribuir estos fallos al trabajo de ML ni corregirlos aquí: ya
  estaban en los cambios locales de interfaz que se están desarrollando.
- No puede generarse una APK release representativa mientras la aplicación no
  compile. Además, el build release exige correctamente una clave local fuera
  del repositorio. No se debilita esa protección para obtener la medida.

La fase de modelos puede continuar de forma aislada porque sus scripts,
artefactos y pruebas no dependen de esos ficheros Flutter.
