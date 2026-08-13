# Remediación de TinyCLIP y paso a TFLite

Fecha: 2026-08-12/13. Dispositivo: Samsung SM-S918B, Android API 36, `arm64-v8a`.
Protocolo idéntico a `baseline.md`: cuatro hilos, XNNPACK, cinco calentamientos
y al menos 50 ejecuciones.

Este informe revisa el rechazo de TinyCLIP registrado en `candidate_research.md`
y `mobile_smoke.md`, y documenta la migración del clasificador de producción de
ONNX Runtime a TFLite.

Hay que distinguir dos artefactos que se habían mezclado:

- **TinyCLIP ViT-8M**, el candidato experimental de `ml/artifacts/smoke/`. Su
  exportación estaba rota. Es el que se midió y se rechazó.
- **TinyCLIP ViT-39M**, el que la aplicación tiene cableado en `assets/models/`.
  Estaba correctamente construido y es el que pasa a producción.

## Parte 1 — El artefacto de 8M estaba roto

**La cabeza de clasificación contenía vectores aleatorios.** La matriz
`onnx::MatMul_1291` de `tinyclip_vit_8m_text_3m.onnx` es de norma unitaria, pero
su coseno contra los prototipos de texto reales es ≈ 0 en las 29 clases (mínimo
−0,107, media −0,005, máximo 0,123). Los embeddings de texto nunca se
escribieron en el grafo. El smoke test de ONNX en Android solo comprobaba que la
salida tuviera forma `[1, 29]`, que se cumplía, así que el defecto no se detectó.

**Faltaba `logit_scale`.** El grafo terminaba en `MatMul → Softmax` sin
multiplicar por `logit_scale.exp()` = 50,0043. El resultado era un softmax sobre
similitudes coseno: todas las salidas valían ≈ 1/29 y el margen entre la primera
y la segunda clase era del orden de 1e-3, por debajo del error de redondeo de la
conversión.

La torre visual sí era correcta: coseno 1,000000 contra
`CLIPModel.get_image_features` en PyTorch.

**El nodo `FILL` que fallaba en Android no venía de TinyCLIP.** Procede de la
cadena `Shape → ConstantOfShape → Equal → Where → Expand` del CLS token. La
entrada ya era estática, así que la cadena es plegable, pero la pasada
`constant_fold_a5` no la propagaba. Un plegado previo con `onnxsim` la elimina
por completo (467 → 335 nodos, salida bit a bit idéntica).

**El backend `flatbuffer_direct` da resultados numéricamente incorrectos.** Con
la cabeza ya corregida, su TFLite float32 no coincidía con el ONNX en ninguna de
las 140 imágenes del piloto (diferencia máxima 9,91e-01). Con la cabeza
aleatoria el error quedaba oculto porque todas las salidas eran planas. El
backend por defecto `tf_converter` sí convierte una vez simplificado el grafo, y
necesita `-rtpo erf gelu` para no emitir `FlexErf`.

Corregido todo lo anterior, el 8M reproduce el piloto exactamente: 140/140 misma
clase, diferencia de puntuación 0,00000, acierto 126/140 (90,0 %). Medido en el
dispositivo, su float16 con fp16 forzado da 20,994 ms y 16,73 MB.

**El 8M no pasa a producción**: el 39M es más preciso (97,1 % frente a 90,0 %) y
la diferencia se concentra justo en los animales de granja, que son el tema de
la aplicación.

## Parte 2 — El artefacto de 39M estaba bien

Comprobado antes de tocarlo:

| Comprobación | Resultado |
|---|---|
| Prototipos incrustados vs reales | coseno mínimo 0,9990, media 0,9991 (la diferencia es el redondeo INT8) |
| `softmax_logit_scale` de los metadatos | 50,0043182, exacto |
| Acierto sobre el piloto | 136/140 (97,1 %) |

Su diseño ya era el correcto: el grafo devuelve similitud coseno cruda y la
aplicación aplica softmax y los umbrales de rechazo. Eso se conserva sin cambios.

## Parte 3 — Migración a TFLite

Motivo: ONNX Runtime añade 32.204.216 bytes de runtime `arm64-v8a` a la APK. La
aplicación ya no necesita ese runtime si el modelo es TFLite.

```powershell
# 1. Exportar a ONNX float32 con prototipos reales, sin softmax
python -m ml.tools.export_tinyclip_classifier --minimum-similarity 0.2091085

# 2. Plegar formas dinámicas
onnxsim tinyclip_39m_classifier.onnx tinyclip_39m_classifier.simplified.onnx

# 3. Convertir
python -m onnx2tf -i ml/artifacts/classifier/tinyclip_39m_classifier.simplified.onnx `
  -o ml/artifacts/classifier/tflite -rtpo erf gelu -odrqt
```

`ml/tools/export_tinyclip_classifier.py` es nuevo y hace reproducible el paso que
antes no estaba versionado. Ampliar el catálogo sigue sin exigir reentrenar:
basta añadir textos en `tinyclip_prompts.yaml` y volver a ejecutarlo.

### Elección de precisión

Verificado sobre las 140 imágenes de `tinyclip_pilot/predictions.csv`, contra el
ONNX float32 como referencia:

| Variante | Tamaño | Top-1 igual al fp32 | Acierto | Diferencia máxima |
|---|---:|---:|---:|---:|
| **TFLite dynamic range int8** | **39 MB** | **140/140** | **136/140 (97,1 %)** | 9,50e-03 |
| TFLite float32 | 148 MB | 140/140 | 136/140 (97,1 %) | 3,43e-07 |
| TFLite float16 | 74 MB | 126/140 | 122/140 (87,1 %) | **NaN** |
| *(anterior)* ONNX int8 | 40,6 MB | 140/140 | 136/140 (97,1 %) | 1,60e-02 |

Se elige **dynamic range int8**: conserva el acierto del float32 exacto, ocupa
menos que el ONNX al que sustituye y se aproxima más al float32 que aquel. El
float16 queda descartado porque produce NaN; no se ha investigado su causa
porque la variante elegida no lo necesita.

Con el umbral `minimum_similarity` = 0,2091085 la variante elegida responde
140/140 y acierta 136, igual que el float32: los umbrales calibrados siguen
siendo válidos sin recalibrar.

### Medición en el dispositivo

| Modelo en producción | Tamaño | Mediana | p95 | Memoria | Init |
|---|---:|---:|---:|---:|---:|
| **TinyCLIP 39M int8, TFLite XNNPACK** | 39,98 MB | **55,911 ms** | 76,847 ms | 106,5 MB | 116,6 ms |
| *(referencia)* TinyCLIP 8M corregido, fp16 | 16,73 MB | 20,994 ms | 23,470 ms | 59,4 MB | 30,1 ms |
| *(anterior)* MobileNetV4 | 19,43 MB | 12,674 ms | 15,246 ms | 64,5 MB | 44,3 ms |

La configuración elegida es 4,4 veces más lenta que el MobileNetV4 que se
distribuía antes, pero se mantiene muy por debajo de 100 ms sobre una acción que
el usuario inicia haciendo una foto. La contrapartida es memoria: 106,5 MB
frente a 64,5 MB, que conviene vigilar en dispositivos con menos RAM que el S23.

No existe medida comparable del 39M sobre ONNX Runtime: nunca se cronometró en
el dispositivo. La única referencia de esa vía es el 8M a 298 ms.

APK release resultante: 113.060.680 bytes (107,8 MB), con
`libtensorflowlite_jni.so` en `arm64-v8a`, `armeabi-v7a` y `x86_64`, y sin
ninguna biblioteca de ONNX Runtime.

### Cambios en la aplicación

- `TinyClipClassifier.kt` pasa de `ai.onnxruntime` a `org.tensorflow.lite`. Se
  conservan sin cambios el preprocesado bicúbico, la orientación EXIF, el
  softmax y los umbrales. El búfer de entrada pasa de NCHW a NHWC.
- `android/app/build.gradle.kts`: `com.microsoft.onnxruntime:onnxruntime-android`
  se sustituye por `org.tensorflow:tensorflow-lite:2.17.0`.
- `assets/models/`: `tinyclip_39m_classifier.int8.onnx` se sustituye por
  `tinyclip_39m_classifier.tflite`. El ONNX anterior se conserva en
  `ml/artifacts/classifier/`.
- Los metadatos declaran ahora `layout: NHWC_RGB`, la precisión y el SHA-256 del
  artefacto distribuido.

El contrato con Dart no cambia: `TinyClipClassifierService` sigue leyendo los
mismos metadatos y recibiendo `rejected`, `indices`, `scores`, `topSimilarity` y
`margin`.

## Qué no cambia

- El 97,1 % se mide sobre 140 fotografías curadas de OpenImages e iNaturalist,
  no sobre fotos hechas por un niño. Sigue sin existir un test independiente.
- Los dibujos sí están medidos, en `tinyclip_39m_stress/`: 16/16 en
  `open_images_depiction`, frente al 3/10 del MobileNetV4 anterior. Lo que sigue
  sin medirse son peluches y fotos hechas por niños. Ese banco se evaluó sobre
  el modelo en PyTorch, no sobre el TFLite distribuido.
- El umbral `minimum_similarity` se hereda del artefacto anterior. Es válido
  porque el modelo y los prototipos no han cambiado. Su calibración sí está
  documentada, en `tinyclip_39m_export/summary.json`: estrategia
  `best_macro_meeting_quality_gates` sobre 192 imágenes, con
  `balanced_accuracy` 0,9079 y `rejection_recall` 0,8667. Ese mismo informe
  advierte de que el banco es pequeño y necesita validación independiente.

## Conclusión

El rechazo de TinyCLIP registrado en `candidate_research.md` y `mobile_smoke.md`
no se sostiene: sus dos medidas justificaban descartar el artefacto de 8M
exportado, no el modelo ni la familia. El 39M, que ya estaba bien construido,
funciona en TFLite con el mismo acierto que en float32, ocupa menos que antes y
elimina 32 MB de runtime de la APK.
