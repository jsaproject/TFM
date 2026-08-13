# Modelo de clasificación

La app identifica 28 animales con **TinyCLIP ViT-39M/16 Text-19M**, y rechaza lo
que no pertenece al catálogo en lugar de forzar una respuesta.

| | |
|---|---|
| Fichero | `assets/models/tinyclip_39m_classifier.tflite` (39,98 MB, int8 dynamic range) |
| Metadatos | `assets/models/tinyclip_39m_classifier.metadata.json` |
| Entrada | `[1, 224, 224, 3]` float32, NHWC, RGB |
| Preprocesado | lado corto a 224 bicúbico → recorte central 224 → `/255` → media y desviación de CLIP |
| Salida | `[1, 28]` float32, **similitud coseno**, sin softmax |
| Clases | derivadas de `ml/config/classes.yaml`; el orden del tensor es el de ese fichero |
| Procedencia | [`wkcn/TinyCLIP-ViT-39M-16-Text-19M-YFCC15M`](https://huggingface.co/wkcn/TinyCLIP-ViT-39M-16-Text-19M-YFCC15M), revisión `07a4b0bc…`, licencia MIT |

## Cómo funciona

No es un clasificador normal. Un clasificador corriente aprende una salida por
clase durante el entrenamiento, y añadir un animal obliga a reentrenar. CLIP
funciona de otra manera:

1. **En la compilación**, cada clase se describe con frases en inglés
   (`ml/config/tinyclip_prompts.yaml`): *"a photo of a cow"*, *"a children's
   illustration of a cow"*, *"a toy shaped like a cow"*… El codificador de texto
   convierte cada frase en un vector, se promedian los de una misma clase y se
   normaliza. Ese vector es el **prototipo** de la clase.
2. Los 28 prototipos se incrustan en el grafo como una matriz `[512, 28]`. **El
   codificador de texto no viaja en la app**: su trabajo ya está hecho.
3. **En el teléfono**, la imagen pasa por la torre visual, se proyecta al mismo
   espacio de 512 dimensiones y se normaliza. Multiplicarla por la matriz de
   prototipos da la similitud coseno con cada clase.

```
imagen ──► torre visual ──► proyección ──► normalización L2 ──┐
                                                              ├─► [1, 28] similitudes
prompts ─► codificador de texto ─► promedio ─► prototipos ────┘
           (solo en la compilación)              [512, 28]
```

Consecuencia práctica: **añadir un animal cuesta escribir unas frases, no
reunir fotos ni reentrenar**.

## Qué hace la app con esas similitudes

El grafo devuelve similitud cruda a propósito. La decisión es de la aplicación,
en `TinyClipClassifier.kt`:

- **Rechazo.** Si la similitud más alta no llega a `minimum_similarity`
  (0,2091085) o el margen con la segunda no llega a `minimum_margin` (0,0), el
  resultado se marca `rejected` y la interfaz muestra "no estoy seguro" en vez de
  una identificación. Es el mecanismo del `fallback_id: otro`: no hay una clase
  "otro" en el tensor, hay un umbral.
- **Probabilidades.** Solo para mostrarlas, se aplica
  `softmax(similitudes × logit_scale)` con `logit_scale` = 50,0043182.

Los tres umbrales viven en los metadatos, no en el código.

### Por qué el `logit_scale` importa

Sin multiplicar por 50, un softmax sobre similitudes coseno (que se mueven entre
~0,1 y ~0,35) devuelve valores casi idénticos: con 28 clases, todo sale en torno
a 1/28 = 0,036. Parece que funciona —el orden es correcto— pero el margen entre
la primera y la segunda clase cae al orden de 1e-3, por debajo del error de
redondeo de cualquier cuantización. Un artefacto así pasa cualquier prueba de
forma y falla en cuanto se convierte.

## Ampliar el catálogo

`ml/config/classes.yaml` es la única fuente de verdad del catálogo y del orden de
salida. Ningún script debe codificar el número de clases.

1. Añade la clase **al final** de `classes.yaml`, conservando los IDs
   existentes. Cambiar el orden invalida las predicciones ya guardadas.
2. Añade sus frases en `ml/config/tinyclip_prompts.yaml`. Varias descripciones
   por clase funcionan mejor que una: se promedian. Incluye sinónimos y crías
   (*a cow, cattle* / *a chicken, a rooster, a chick*).
3. Añade la entrada al catálogo tipado de Dart (`lib/animal_catalog.dart`) con
   nombre e imagen. El servicio valida que cada `display_name` del modelo exista
   en el catálogo y falla al cargar si no coinciden.
4. Reexporta y reconvierte:

```powershell
.\ml\.venv-pytorch\Scripts\python.exe -m ml.tools.export_tinyclip_classifier `
  --minimum-similarity 0.2091085 --layout NHWC_RGB

.\ml\.venv-onnx2tf\Scripts\python.exe -m onnx2tf `
  -i ml/artifacts/classifier/tinyclip_39m_classifier.simplified.onnx `
  -o ml/artifacts/classifier/tflite -rtpo erf gelu -odrqt
```

   El ONNX hay que simplificarlo con `onnxsim` entre ambos pasos; sin eso la
   conversión arrastra formas dinámicas que fallan en el dispositivo.

5. Mide antes de embarcarlo (ver más abajo) y actualiza los metadatos con el
   SHA-256 del artefacto nuevo.

**Recalibra el umbral** al ampliar. `minimum_similarity` se fijó para 28 clases;
con más clases las similitudes se reparten distinto.

## Mejorarlo

Por orden de esfuerzo frente a beneficio esperado:

- **Reescribir prompts.** Es gratis y a veces mueve varios puntos. Las clases que
  se confunden entre sí suelen mejorar añadiendo contexto discriminante (*a pig,
  a pink farm animal with a snout* frente a *a pig*). Se mide en minutos con
  `evaluate_tinyclip_pilot.py`, sin reconvertir nada.
- **Ampliar el banco de calibración.** Los umbrales ya están calibrados (ver
  abajo), pero sobre 192 imágenes. El propio informe lo advierte: *"necesitan
  validación independiente antes de publicar"*. Más imágenes fuera de catálogo
  mejorarían sobre todo el `rejection_recall`.
- **Linear probe.** Congelar la torre visual y entrenar una capa lineal sobre
  sus embeddings con fotos revisadas. Suele superar bastante al cero-shot y
  conserva la robustez ante dibujos, pero pierde la propiedad de ampliar el
  catálogo sin datos.
- **Modelo mayor.** TinyCLIP publica variantes por encima de 39M. Cuesta tamaño
  y latencia; el 39M ya está en 55,9 ms y 39,98 MB.

## Verificar antes de embarcar

El artefacto se compara contra el piloto revisado. La comprobación que importa
no es la forma del tensor, es el **valor**:

| Comprobación | Criterio |
|---|---|
| Prototipos incrustados vs recalculados | coseno > 0,99 por clase |
| `softmax_logit_scale` de los metadatos | igual a `model.logit_scale.exp()` |
| TFLite vs ONNX float32 sobre el piloto | misma clase en las 140 imágenes |
| Acierto sobre el piloto | ≥ el del float32 |
| Comportamiento del umbral | cobertura y acierto sin degradar |

`tool/verify_model.py` **no sirve para este modelo**: se escribió para el
MobileNetV4 de ImageNet y espera 1000 logits y un fichero de grupos. Queda
pendiente adaptarlo.

## Precisión y rendimiento medidos

Sobre las 140 fotografías revisadas del piloto (`ml/reports/tinyclip_pilot/`):

| | Resultado |
|---|---|
| Acierto | 136/140 (97,1 %) |
| Coincidencia con el float32 | 140/140 |
| Mediana en Samsung SM-S918B | 55,9 ms (4 hilos, XNNPACK) |
| p95 | 76,8 ms |
| Memoria | 106,5 MB |

No hay desglose por clase del 39M: `ml/reports/tinyclip_pilot/` corresponde a la
evaluación del candidato de 8M, que acertó 90,0 % sobre el mismo piloto y falla
sobre todo en cerdo, perro e hipopótamo. Generar el desglose del 39M con
`evaluate_tinyclip_pilot.py --model-id/--model-revision` queda pendiente.

### Banco de estrés y umbrales

Los umbrales no son arbitrarios. Se eligieron con la estrategia
`best_macro_meeting_quality_gates` sobre 192 imágenes (140 del piloto + 52 de
estrés), y sus métricas están en `ml/reports/tinyclip_39m_export/summary.json`:

| Métrica | Valor |
|---|---:|
| `balanced_accuracy` | 0,9079 |
| `positive_accuracy` | 0,9492 |
| `rejection_recall` | 0,8667 |

El banco de estrés (`ml/reports/tinyclip_39m_stress/`) mide justo lo que el
piloto no cubre:

| Grupo | Acierto | Qué comprueba |
|---|---:|---|
| `open_images_depiction` | 16/16 | **dibujos e ilustraciones** |
| `unsupported_animal` | 9/10 | rechazar animales fuera del catálogo |
| `weak_class_photo` | 11/14 | las clases que más se confunden |
| `app_asset_supported` | 5/7 | las propias ilustraciones de `assets/` |
| `app_asset_rejection` | 2/5 | rechazar las ilustraciones no soportadas |

El 16/16 en ilustraciones confirma el motivo de haber elegido un modelo CLIP: el
MobileNetV4 anterior acertaba 3/10 ahí. El punto flojo es `app_asset_rejection`.

**Lo que sigue sin medirse:** peluches, y fotos hechas por niños en condiciones
reales. El propio informe de calibración avisa de que el banco es pequeño y
necesita validación independiente antes de publicar.

## Por qué se desconfía de los modelos aquí

Dos veces en este proyecto se ha estado a punto de embarcar un modelo cuya
cabeza de clasificación no contenía nada útil:

- El `assets/model.tflite` original (ResNet50, 102,4 MB) entró en el commit
  inicial de junio de 2021 y **nunca funcionó**. El backbone conservaba los pesos
  de ImageNet, pero la cabeza no llegó a entrenarse: los bias seguían en escala
  de inicialización, el 56 % de las features estaban siempre a cero, una imagen
  negra devolvía `Mariposa` al 100 % y seis de diez clases no se predecían jamás.
- El candidato TinyCLIP de 8M de `ml/artifacts/smoke/` llevaba **prototipos
  aleatorios**: vectores de norma unitaria sin ninguna relación con las clases
  (coseno ≈ 0 con los correctos). Se midió, se cronometró y se rechazó por lento
  sin que nadie notara que sus respuestas no significaban nada. El smoke test
  comprobaba que la salida tuviera forma `[1, 29]`, y la tenía.

Ninguno de los dos casos se ve abriendo el fichero, y ambos pasan las pruebas de
estructura. Por eso la verificación de esta página compara **valores** contra una
referencia conocida, y no solo formas.

## Pendiente

- [ ] Conjunto de prueba independiente, con fotos reales de uso infantil.
- [ ] Medir peluches, que el banco de estrés no cubre.
- [ ] Ampliar el banco de rechazo: `app_asset_rejection` va 2/5.
- [ ] Adaptar `tool/verify_model.py` al contrato actual.
- [ ] Desglose por clase del 39M sobre el piloto (existe el agregado, no el detalle por clase del artefacto TFLite).
