# Modelo de clasificación

La app identifica con **MobileNetV4-Conv-Medium** entrenado en ImageNet-1k, y
reparte sus 1000 clases entre los 42 grupos del catálogo.

| | |
|---|---|
| Fichero | `assets/model_mnv4.tflite` (19,4 MB, float16) |
| Entrada | 224×224×3, float32 |
| Normalización | `imageMean: 127.5`, `imageStd: 127.5` |
| Salida | 1000 logits **sin softmax** |
| Etiquetas | `assets/labels_imagenet.txt` |
| Agrupación | `assets/imagenet_animal_groups.json` |

Procede de [`byoussef/MobileNetV4_Conv_Medium_TFLite_224`][hf], conversión de
los pesos de [`timm/mobilenetv4_conv_medium.e500_r224_in1k`][timm].

[hf]: https://huggingface.co/byoussef/MobileNetV4_Conv_Medium_TFLite_224
[timm]: https://huggingface.co/timm/mobilenetv4_conv_medium.e500_r224_in1k

## Tres detalles que rompen la integración si se ignoran

**El modelo devuelve logits, no probabilidades.** Hay que aplicar softmax antes
de sumar por grupos; sumar logits no significa nada. Lo hace
`AnimalGroupMapping.aggregate`, que además detecta si la salida ya venía
normalizada para no aplanarla dos veces.

**El plugin filtra por `confidence > threshold`.** Como los logits son casi
siempre negativos, un umbral de cero se comería la mayor parte del vector y la
normalización saldría mal. `classifier_service.dart` pasa un umbral muy
negativo para conservar las 1000 clases.

**La normalización exacta de timm no es representable.** Usa media y desviación
por canal, y `TflitePlugin.java` aplica un único escalar a los tres. Se usa
`127.5/127.5`, medido con `--preprocess auto`: la diferencia frente a la exacta
fue de cero aciertos sobre 81 imágenes.

## Precisión medida

| Banco | Aciertos |
|---|---|
| Fotos reales (`daisy` del dataset de flores + imagen patrón de TFLite) | 74/81 (91 %) |
| Dibujos (las ilustraciones del catálogo) | 3/10 |

Los modelos de ImageNet se entrenan con fotografías y se desploman ante dibujos
de línea. Si el uso con dibujos llega a importar, la vía es un modelo tipo CLIP
(MobileCLIP), que es robusto ahí y permite describir cada clase con varias
frases. Requiere convertir con `ai-edge-torch` y sustituir el plugin
vendorizado por `tflite_flutter`.

**No hay banco de fotos propio.** Las imágenes de `assets/` son ilustraciones
del catálogo, no fotografías. Para medir sobre el uso real hay que reunir
`test_fotos/<grupo>/*.jpg` con fotos de verdad.

## Verificar un modelo antes de embarcarlo

```bash
pip install ai-edge-litert pillow numpy tflite

python3 tool/verify_model.py assets/model_mnv4.tflite \
    --groups assets/imagenet_animal_groups.json \
    --images test_fotos/ --preprocess auto
```

Comprueba estructura, correspondencia con las etiquetas, si la salida son
logits, que una entrada sin contenido no dispare una clase con alta confianza,
que las features del clasificador no estén muertas y, con `--images`, los
aciertos reales y qué normalización usar. Devuelve 1 si el modelo no debe
embarcarse.

## Por qué existe todo esto

El modelo anterior (`assets/model.tflite`, un ResNet50 de 102,4 MB) entró en el
commit inicial de junio de 2021 y **nunca funcionó**. Su backbone conservaba
los pesos de ImageNet, pero la cabeza de clasificación no llegó a entrenarse:
los bias seguían en escala de inicialización, el 56 % de las features estaban
siempre a cero, una imagen negra devolvía `Mariposa` al 100 % y seis de las diez
clases no se predecían jamás. No era un problema de normalización ni de
`labels.txt`: se descartaron ambos midiendo.

Nada de eso se ve abriendo el fichero. Por eso `tool/verify_model.py` es parte
del proyecto y no un apaño de una tarde.

## Pendiente

- [ ] Reunir `test_fotos/` con fotos reales por grupo y medir sobre uso real.
- [ ] Ilustración propia para los 32 grupos que hoy muestran solo un icono.
- [ ] Evaluar MobileCLIP si el caso de dibujos y peluches pesa lo suficiente.
