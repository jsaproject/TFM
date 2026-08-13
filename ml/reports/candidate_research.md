# Investigación inicial de candidatos

Fecha de corte: 2026-08-12.

> **Corrección (2026-08-13).** El rechazo de TinyCLIP que recoge este informe no
> se sostiene. Se apoyaba en un artefacto de 8M mal exportado, no en el modelo.
> Ver `tinyclip_remedicion.md`. El clasificador de producción es TinyCLIP 39M en
> TFLite int8, con 97,1 % sobre el piloto y sin runtime adicional.

## Requisitos interpretados

La aplicación es un proyecto personal por nostalgia, no un trabajo académico.
El requisito económico es coste monetario cero: sin API de pago, suscripción ni
coste por inferencia. Para no cerrar opciones futuras, los pesos también deben
permitir uso y redistribución fuera de la investigación académica.

## Resultado

Se han localizado seis candidatos o referencias y se han aplicado primero las
puertas de licencia y tamaño:

| Candidato | Resultado | Motivo |
|---|---|---|
| TinyCLIP ViT-8M/16 Text-3M | ~~Rechazado para producción móvil~~ Rechazo inválido | El fallo de TFLite y los 298 ms venían del artefacto exportado y de la ruta de conversión, no del modelo. Corregido rinde 20,994 ms y 16,73 MB. Se descarta igualmente frente al 39M, que es más preciso |
| DINOv2 Small con prototipos | Rechazado por dominancia | Su ONNX es mayor y más lento que TinyCLIP con el mismo runtime |
| MobileNetV3 Small, pesos propios | Pasa a criba de calidad | Baseline móvil Apache-2.0, 1,04 MiB y mediana de 2,626 ms |
| EfficientNet-Lite0, pesos propios | Pasa a criba de calidad | Arquitectura móvil Apache-2.0, 3,50 MiB y mediana de 39,033 ms |
| SigLIP2 Base Patch32 | Rechazado | Licencia Apache-2.0, pero el checkpoint completo es demasiado grande |
| MobileCLIP2-S0 | Rechazado | Gratuito, pero restringido a investigación no comercial |

Los cuatro candidatos técnicamente elegibles se exportaron o cribaron. La
medición reproducible se encuentra en `mobile_smoke.md`. Los dos finalistas
móviles son clasificadores directos; TinyCLIP se conserva como posible
herramienta local de apoyo para preparar datos, no como dependencia de la app.

## Evidencias verificadas

- El modelo oficial [TinyCLIP ViT-8M/16 Text-3M](https://huggingface.co/wkcn/TinyCLIP-ViT-8M-16-Text-3M-YFCC15M)
  declara licencia MIT y 41,1 % de top-1 ImageNet cero-shot. Su
  [licencia](https://github.com/wkcn/TinyCLIP/blob/main/LICENSE) permite usar,
  modificar y distribuir. Los embeddings de texto se pueden generar durante
  la compilación: la app solo tendría que ejecutar la rama visual.
- El repositorio oficial de [DINOv2](https://github.com/facebookresearch/dinov2)
  indica expresamente que su código y sus pesos generales se publican bajo
  Apache-2.0. No debe confundirse con variantes médicas posteriores que tienen
  licencias diferentes. Se probará exclusivamente `dinov2-small`.
- [Keras ofrece MobileNetV3Small](https://keras.io/api/applications/mobilenet/)
  y su repositorio usa [Apache-2.0](https://github.com/keras-team/keras/blob/master/LICENSE).
- [EfficientNet-Lite](https://github.com/tensorflow/tpu/blob/master/models/official/efficientnet/lite/README.md)
  fue diseñado para dispositivos móviles/IoT. La referencia publica 4,7 M de
  parámetros para Lite0 y exportación TFLite; el repositorio usa
  [Apache-2.0](https://github.com/tensorflow/tpu/blob/master/LICENSE).
- [SigLIP2 Base Patch32](https://huggingface.co/google/siglip2-base-patch32-256)
  declara Apache-2.0 y sería flexible, pero la familia Base no encaja de entrada
  en el presupuesto de una app infantil móvil. Se descarta antes de convertir.
- Apple publica código MIT para MobileCLIP, pero su
  [licencia de modelos](https://github.com/apple/ml-mobileclip/blob/main/LICENSE_MODELS)
  restringe pesos, fine-tuning y derivados a investigación no comercial y
  excluye desarrollo de producto. Que la descarga sea gratis no elimina esa
  condición.
- LiteRT documenta rutas de conversión para
  [TensorFlow y PyTorch](https://ai.google.dev/edge/litert/conversion/overview),
  por lo que las toolchains admitidas tienen al menos una ruta móvil oficial.

## Qué significa ampliar animales

- TinyCLIP: añadir textos y recalcular sus embeddings; no exige reentrenar.
- DINOv2: añadir varios ejemplos revisados y recalcular el prototipo; se puede
  empezar sin reentrenar y ajustar después si la precisión lo requiere.
- Clasificadores directos: añadir datos y reentrenar la cabeza/modelo. El
  pipeline ya obtiene el número de salidas de `classes.yaml`.

La facilidad para ampliar clases es una métrica, pero no sustituye la prueba de
caballo/perro, dibujos, peluches, fondos y latencia real.
