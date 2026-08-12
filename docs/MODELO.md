# Modelo de clasificación

## Estado actual: `assets/model.tflite` no sirve

El modelo que acompaña al proyecto desde el commit inicial (`dcc8276`, junio de
2021) es un ResNet50 de 102,4 MB con una cabeza `Dense(1024) → Dense(10)`. El
backbone conserva los pesos de ImageNet en buen estado, pero **la cabeza de
clasificación nunca llegó a entrenarse**:

- Los bias de la capa final siguen en escala de inicialización (±0,02).
- El 56 % de las features que alimentan al clasificador están siempre a cero.
- Una imagen completamente negra devuelve `Mariposa` con un 100 % de confianza;
  el ruido aleatorio devuelve `Mariposa` entre el 95 % y el 99 %.
- Solo tres de las diez clases ganan alguna vez. `Caballo`, `Gallina`, `Vaca`,
  `Oveja`, `Ardilla` y `Elefante` no se predicen nunca, con ninguna entrada.

No es un problema de normalización: se probaron cinco preprocesados habituales
(`raw`, `/255`, `[-1,1]`, caffe/BGR y normalización ImageNet) y ninguno cambia
el diagnóstico. Tampoco es un problema de `labels.txt`, cuyo orden coincide
exactamente con las carpetas de Animals-10 ordenadas alfabéticamente.

La app, por tanto, nunca ha clasificado bien.

## Verificar un modelo antes de embarcarlo

```bash
pip install ai-edge-litert pillow numpy tflite

python3 tool/verify_model.py assets/model.tflite --labels assets/labels.txt
python3 tool/verify_model.py candidato.tflite \
    --groups tool/imagenet_animal_groups.json --images test_fotos/
```

Comprueba estructura y correspondencia con las etiquetas, que una entrada sin
contenido no dispare una clase con alta confianza, que las features del
clasificador no estén muertas y, si se le pasa `--images`, los aciertos reales.
Devuelve 1 si el modelo no debe embarcarse.

`test_fotos/` espera una subcarpeta por clase esperada: `test_fotos/Perro/*.jpg`.

**Falta el banco de fotos.** Las imágenes de `assets/` son las ilustraciones del
catálogo, no fotografías, y no sirven para medir: un modelo de ImageNet sano
falla ante un dibujo de línea igual que ante ruido. Cualquier cifra de precisión
medida sobre ellas es engañosa.

## Dirección elegida

Sustituir el modelo por uno preentrenado y verificado, sin reentrenar nada.

**`tool/imagenet_animal_groups.json`** agrupa las clases de animales de
ImageNet-1k en 42 grupos mostrables (396 de las 398 clases de animales;
quedan fuera `triceratops` y `trilobite`). Permite usar cualquier clasificador
de ImageNet sumando las probabilidades de cada grupo, y da gratis la detección
de "esto no es un animal" con las 602 clases restantes.

- **MobileNetV4-Conv-Medium** (ECCV 2024) como opción directa: ~80 % de top-1
  frente al ~75 % de MobileNetV3, mismas 1000 clases, unos 5-9 MB. El plugin
  TFLite vendorizado vale tal cual: `GetTopN` recorre todas las clases, así que
  basta pedir `numResults: 1000` y agregar los grupos en Dart.
- **MobileCLIP** como opción preferida por el uso real de la app, que mezcla
  animales reales con dibujos, peluches y libros infantiles. Los modelos de
  ImageNet se desploman ante representaciones no fotográficas; los de tipo CLIP
  son robustos ahí, y admiten describir cada clase con varias frases ("una foto
  de un perro", "un dibujo de un perro", "un peluche de un perro"). La lista de
  animales pasa a ser un fichero de texto editable en vez de estar dentro del
  modelo. Requiere convertir con `ai-edge-torch` y sustituir el plugin
  vendorizado por `tflite_flutter`, que es lo que ya pide el roadmap.

## Pendiente

- [ ] Reunir `test_fotos/` con fotografías reales y con dibujos, por grupo.
- [ ] Descargar los candidatos y pasarlos por `tool/verify_model.py`.
- [ ] Elegir modelo con datos y sustituir `assets/model.tflite`.
- [ ] Ampliar `animal_catalog.dart` a los grupos elegidos, con imagen por grupo.
- [ ] Umbral de confianza y estado "no es un animal" en la interfaz.
