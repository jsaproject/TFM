# Plan ejecutable: modelo infantil de animales

## 1. Objetivo

Sustituir el clasificador genérico actual de ImageNet por una solución local
que reconozca 28 animales apropiados para una aplicación infantil y rechace
imágenes que no pertenecen al catálogo.

El resultado final debe:

- funcionar sin conexión en Android e iOS;
- reconocer fotografías, ilustraciones y peluches;
- devolver una de 28 clases o `otro`;
- evitar el sesgo actual que favorece a grupos con muchas clases de ImageNet;
- no superar el modelo actual de 19,4 MB y preferiblemente quedar por debajo de
  15 MB;
- conservar todas las predicciones y colecciones ya guardadas;
- incluir dataset reproducible, procedencia, licencias, métricas y pruebas;
- mantener mensajes de error y estados de la interfaz en español.

Este documento está escrito para que otro agente pueda ejecutarlo sin tomar
decisiones de producto. Si una instrucción no se puede cumplir, el agente debe
detenerse, documentar el impedimento y no sustituirla por una decisión propia.

## 2. Instrucciones obligatorias para el agente ejecutor

Antes de modificar cualquier fichero:

1. Leer completos `AGENTS.md`, `docs/code-review/firebase-ml.md`,
   `docs/code-review/flutter-dart.md`, `docs/MODELO.md` y la fase 7 de
   `ROADMAP_MEJORAS.txt`.
2. Ejecutar `git status --short` y `git diff --cached`.
3. Preservar todos los cambios del usuario. No restaurar, reformatear ni incluir
   ficheros no relacionados.
4. Ejecutar una sola fase de este plan cada vez.
5. No pasar a la fase siguiente si no se cumplen todos sus criterios de salida.
6. No descargar imágenes mediante scraping de Google, Bing, Pinterest, redes
   sociales o páginas sin API y licencia verificable.
7. No guardar credenciales, cookies, tokens ni fotografías privadas.
8. No usar fotos aportadas por usuarios de la aplicación. Solo se podrán usar
   en el futuro con consentimiento expreso y una política de retención.
9. No eliminar el modelo ni las etiquetas actuales hasta que el modelo nuevo
   haya pasado las pruebas de paridad, dispositivo y compatibilidad.
10. No mezclar este trabajo con refactors visuales, Firebase u otras mejoras.

Al terminar cada fase, el agente debe entregar:

- ficheros creados o modificados;
- comandos ejecutados;
- resultados medidos;
- criterios de salida aprobados o fallidos;
- siguiente fase permitida.

## 3. Restricciones fijas y decisiones abiertas

El plan no presupone qué arquitectura, framework o pipeline ganará. Se fija el
problema de producto, no su solución técnica.

Restricciones fijas:

- la versión 1 tendrá 29 posibilidades: 28 animales y `otro`; el número de
  salidas se derivará del catálogo versionado y podrá crecer en versiones
  posteriores sin reescribir el pipeline;
- no se reutilizará el agrupado desigual de las 1000 etiquetas de ImageNet;
- la solución final funcionará completamente en el dispositivo y sin red;
- Android e iOS producirán la misma semántica de resultados;
- se conservarán las colecciones antiguas;
- el test permanecerá independiente y cerrado hasta congelar el artefacto;
- las ilustraciones bonitas de la interfaz son una tarea visual separada y no
  entrarán automáticamente en el dataset;
- ninguna mejora de precisión puede saltarse las puertas de licencia,
  privacidad, tamaño, latencia o mantenibilidad.
- todas las herramientas, modelos y pesos del producto deben poder usarse sin
  cuotas, suscripciones ni pagos por inferencia; se priorizan licencias
  permisivas que permitan modificar y redistribuir la aplicación aunque en el
  futuro deje de ser un proyecto personal.

Decisiones deliberadamente abiertas hasta medir:

- arquitectura y familia del modelo;
- TensorFlow/Keras, PyTorch u otro framework de entrenamiento reproducible;
- clasificador directo, embeddings/prototipos, modelo visual-texto,
  detector+clasificador o detector multiclase;
- resolución de entrada; 192-320 píxeles es el rango móvil de referencia, no
  una prohibición si otra resolución demuestra mejores medidas;
- INT8, float16 u otra cuantización soportada por el runtime;
- un único modelo multiplataforma o artefactos equivalentes por plataforma;
- runtime móvil, delegados CPU/GPU/NPU y número de hilos;
- estrategia de fine-tuning, distillation y aumentos.

El agente puede proponer cualquier candidato, incluso uno no nombrado en este
documento, si antes demuestra:

1. licencia gratuita compatible con uso, modificación y redistribución de la
   aplicación fuera de un contexto académico;
2. procedencia y versión verificables;
3. conversión reproducible a un formato ejecutable localmente;
4. salida adaptable al catálogo activo sin heurísticas ocultas;
5. funcionamiento potencial en Android e iOS;
6. ausencia de servicio remoto, credenciales o envío de fotografías;
7. posibilidad de medirlo con exactamente los mismos splits.

La eficiencia se decidirá con medidas release en dispositivos. Número de
parámetros, FLOPs o latencias publicadas solo sirven para filtrar candidatos;
no sustituyen la medición dentro de esta aplicación.

## 4. Catálogo cerrado de la versión 1

Los identificadores del modelo son ASCII, en minúsculas y no se traducen. La
aplicación los convertirá al nombre español mostrado al usuario.

| Categoría | ID del modelo | Nombre visible | Qué incluye |
|---|---|---|---|
| Granja | `vaca` | Vaca | Vacas y terneros; excluir búfalos y bisontes |
| Granja | `caballo` | Caballo | Caballos y potros; excluir cebras y burros |
| Granja | `cerdo` | Cerdo | Cerdos y lechones; excluir jabalíes |
| Granja | `oveja` | Oveja | Ovejas y corderos; excluir cabras |
| Granja | `cabra` | Cabra | Cabras y cabritos; excluir ovejas y antílopes |
| Granja | `burro` | Burro | Burros; excluir caballos y cebras |
| Granja | `gallina` | Gallina | Gallinas, gallos y pollitos domésticos |
| Granja | `pato` | Pato | Patos y patitos; excluir gansos y cisnes |
| Doméstico | `perro` | Perro | Todas las razas de perro doméstico |
| Doméstico | `gato` | Gato | Gatos domésticos; excluir felinos salvajes |
| Doméstico | `conejo` | Conejo | Conejos domésticos y silvestres; excluir liebres si son ambiguas |
| Doméstico | `hamster` | Hámster | Hámsteres; excluir cobayas, ratones y ratas |
| Doméstico | `tortuga` | Tortuga | Tortugas terrestres y acuáticas |
| Doméstico | `pez` | Pez | Peces visibles completos, especialmente peces de acuario |
| Doméstico | `loro` | Loro | Loros, periquitos, guacamayos y cacatúas |
| Zoo | `leon` | León | Leones adultos y cachorros |
| Zoo | `tigre` | Tigre | Tigres adultos y cachorros |
| Zoo | `elefante` | Elefante | Elefantes africanos y asiáticos |
| Zoo | `jirafa` | Jirafa | Jirafas adultas y crías |
| Zoo | `cebra` | Cebra | Cebras |
| Zoo | `mono` | Mono | Monos y simios; conservar diversidad visual |
| Zoo | `panda` | Panda | Panda gigante; excluir panda rojo |
| Zoo | `oso` | Oso | Oso pardo, negro y polar; excluir panda gigante |
| Zoo | `hipopotamo` | Hipopótamo | Hipopótamos adultos y crías |
| Zoo | `rinoceronte` | Rinoceronte | Rinocerontes |
| Zoo | `cocodrilo` | Cocodrilo | Cocodrilos y aligátores, agrupados para público infantil |
| Zoo | `pinguino` | Pingüino | Todas las especies de pingüino |
| Zoo | `koala` | Koala | Koalas |
| Rechazo | `otro` | No reconocido | Fondo, objetos, personas, animales no incluidos y entradas ambiguas |

No añadir ni retirar clases durante el entrenamiento de una versión ya
iniciada. Si una clase no consigue datos suficientes, registrar el problema y
detener la fase de datos.

### 4.1 Catálogo extensible y versionado

Los 28 animales anteriores son el alcance de `catalog_version: 1`, no un
límite del sistema. `ml/config/classes.yaml` será la única fuente de verdad
para datos, entrenamiento, exportación y generación de etiquetas. Ningún
script reutilizable podrá contener una constante `29` ni una lista paralela de
animales.

Reglas obligatorias:

1. La cantidad de salidas se calcula a partir de las clases activas del
   catálogo, incluida la clase de rechazo indicada por `fallback_id`.
2. Cada ID es estable, ASCII y no se reutiliza aunque una clase se retire.
3. Cada modelo guarda `catalog_version`, la lista ordenada de IDs y su hash en
   el manifiesto del artefacto.
4. El dataset, los splits y las métricas también declaran esa versión y ese
   hash. No se pueden mezclar silenciosamente catálogos distintos.
5. El código de la aplicación valida en el arranque que el número de etiquetas
   coincide con la última dimensión del tensor de salida. Una discrepancia es
   un error controlado en español, nunca un acceso fuera de rango.
6. Para añadir animales en el futuro se crea una nueva versión del catálogo,
   se incorporan y revisan sus datos, se regeneran los splits, se reentrena el
   modelo completo y se publica un artefacto nuevo. No es necesario cambiar
   los descargadores, validadores, entrenador ni evaluador.
7. La ampliación conserva los IDs anteriores y la compatibilidad de la
   colección. Retirar una clase del modelo no borra el historial del usuario.
8. Las cuotas del documento son las de v1; los scripts las aplican a cada
   clase activa y, por tanto, escalan con el catálogo.

Ejemplo: si una versión futura añade `mapache` y `erizo`, el pipeline debe
detectar automáticamente dos clases nuevas, exigir sus datos y producir un
modelo con dos salidas más. El cambio de producto se revisará por separado,
pero no requerirá editar la lógica del pipeline.

## 5. Compatibilidad con la colección existente

La colección actual persiste nombres españoles. Cambiar o borrar esos nombres
podría ocultar datos del usuario. La integración debe cumplir estas reglas:

1. No eliminar ninguna entrada existente de `animalCatalog`.
2. Añadir a `Animal` un campo estable `modelLabel` y un booleano
   `isDiscoverable` solo cuando comience la fase de integración.
3. Mantener los nombres existentes para estas clases: `Caballo`, `Cerdo`,
   `Perro`, `Gato`, `Tortuga`, `Pez`, `Loro`, `Elefante`, `Cebra`, `Oso`,
   `Hipopótamo`, `Cocodrilo` y `Pingüino`.
4. Añadir las clases nuevas sin renombrar las antiguas: `Vaca`, `Oveja`,
   `Cabra`, `Burro`, `Gallina`, `Pato`, `Conejo`, `Hámster`, `León`, `Tigre`,
   `Jirafa`, `Mono`, `Panda`, `Rinoceronte` y `Koala`.
5. Marcar como descubribles exactamente los 28 animales del modelo nuevo.
6. Mantener las categorías genéricas antiguas como elementos heredados no
   descubribles. Si tienen recuentos, deben seguir visibles en el historial o
   en una sección de datos anteriores.
7. Calcular el progreso únicamente sobre los 28 animales descubribles.
8. No convertir automáticamente, por ejemplo, `Bovino` en `Vaca` ni
   `Felino salvaje` en `León`: no existe información suficiente para hacerlo
   sin corromper datos.
9. Añadir pruebas de colección con datos antiguos antes de cambiar el catálogo.

Esta estrategia mantiene el esquema de Firestore y evita una migración
destructiva. Una futura migración de nombres a identificadores estables deberá
ser un cambio independiente.

## 6. Tamaño y composición del dataset

### 6.1 Hito inicial obligatorio

Por cada uno de los 28 animales:

| Split | Fotografías | Ilustraciones | Peluches/figuras | Total |
|---|---:|---:|---:|---:|
| Entrenamiento | 140 | 40 | 20 | 200 |
| Validación | 21 | 6 | 3 | 30 |
| Prueba | 35 | 10 | 5 | 50 |
| Total por clase | 196 | 56 | 28 | 280 |

Esto produce 7.840 imágenes de animales.

Para `otro`:

| Split | Cantidad |
|---|---:|
| Entrenamiento | 800 |
| Validación | 120 |
| Prueba | 200 |

Total inicial: 8.960 imágenes originales. Los aumentos generados durante el
entrenamiento no cuentan para estas cuotas.

### 6.2 Contenido de `otro`

Distribuir `otro` de forma aproximadamente uniforme entre:

- objetos: vehículos, muebles, juguetes, comida y ropa;
- entornos: habitaciones, calles, campos, agua y cielo sin animal dominante;
- animales no soportados: serpiente, zorro, lobo, ciervo, camello, avestruz,
  tiburón, delfín, ballena, rana, lagarto, mariposa y araña;
- imágenes vacías, desenfocadas, oscuras o parcialmente tapadas;
- varios animales de clases diferentes sin uno claramente dominante;
- logos, texto, iconos y dibujos que no representan un animal soportado.

No incluir desnudos, violencia, animales heridos, muertos, cazados, en
apareamiento o cualquier contenido inadecuado para menores.

## 7. Fuentes y licencias

Usar, en este orden:

1. Open Images para fotografías y recortes con cajas delimitadoras.
2. iNaturalist para diversidad de animales reales.
3. Wikimedia Commons para ilustraciones, peluches y clases con pocos ejemplos.

Reglas:

- utilizar las API, manifiestos o descargadores oficiales;
- aplicar una lista permitida de licencias: CC0, CC BY y CC BY-SA;
- excluir licencias `NC`, `ND`, desconocidas o sin URL verificable;
- guardar autor, URL original, fuente, licencia y URL de licencia;
- conservar los requisitos de atribución en `ml/ATTRIBUTIONS.csv`;
- verificar los términos actuales de cada fuente antes de iniciar descargas;
- respetar límites de API y usar espera exponencial ante errores 429/5xx;
- no generar el test con IA generativa;
- si se usan imágenes generadas para ampliar entrenamiento, deben representar
  como máximo el 10 % de una clase, declararse como `synthetic` y excluirse de
  validación y prueba.

## 8. Estructura que debe crear la fase de datos

```text
ml/
  README.md
  ATTRIBUTIONS.csv
  requirements.in
  requirements.txt
  config/
    classes.yaml
    sources.yaml
    candidates.yaml
  data/
    raw/                 # ignorado por Git
    interim/             # ignorado por Git
    processed/           # ignorado por Git
      train/<clase>/
      validation/<clase>/
      test/<clase>/
  manifests/
    all.csv
    train.csv
    validation.csv
    test.csv
    rejected.csv
  reports/
    dataset_summary.json
    duplicate_groups.csv
    contact_sheets/      # ignorado si ocupa demasiado
  scripts/
    collect_open_images.py
    collect_inaturalist.py
    collect_wikimedia.py
    validate_downloads.py
    crop_and_normalize.py
    detect_duplicates.py
    build_splits.py
    build_contact_sheets.py
    audit_dataset.py
  training/
    discover_candidates.py
    train_candidate.py
    evaluate_candidate.py
    benchmark_candidate.py
    calibrate_rejection.py
    export_candidate.py
    compare_runtime.py
    adapters/
      base.py
      <un_adaptador_por_framework_o_pipeline>.py
  runs/                  # ignorado por Git
```

Añadir a `.gitignore` únicamente:

```gitignore
ml/.venv/
ml/data/raw/
ml/data/interim/
ml/data/processed/
ml/reports/contact_sheets/
ml/runs/
```

No ignorar `manifests`, configuraciones, scripts ni informes pequeños. No usar
una regla global `*.tflite`, porque el modelo final sí debe versionarse como
artefacto.

## 9. Contrato del manifiesto

`ml/manifests/all.csv` debe tener exactamente estas columnas:

```text
image_id,class_id,split,modality,source,source_item_id,source_page_url,
download_url,author,license,license_url,retrieved_at,sha256,phash,width,
height,bbox_xmin,bbox_ymin,bbox_xmax,bbox_ymax,subject_group_id,
review_status,rejection_reason,local_relative_path
```

Reglas de campos:

- `image_id`: SHA-256 del contenido normalizado.
- `class_id`: uno de los 29 identificadores definidos en este documento.
- `split`: vacío hasta construir los splits; después `train`, `validation` o
  `test`.
- `modality`: `photo`, `illustration`, `toy` o `synthetic`.
- `subject_group_id`: observación, ráfaga, autor/serie o imagen original que
  agrupa variantes del mismo sujeto.
- `review_status`: `pending`, `accepted` o `rejected`.
- `local_relative_path`: ruta relativa a `ml/`; nunca una ruta absoluta.

El CSV se escribe siempre en UTF-8, con cabecera y saltos de línea LF.

## 10. Reglas de calidad y etiquetado

Aceptar una imagen de una clase animal solo si:

- el animal correcto es visible y dominante;
- ocupa al menos aproximadamente el 30 % del recorte final;
- no existe otro animal de clase diferente con protagonismo similar;
- el lado menor del original o recorte tiene al menos 256 píxeles;
- no está tan borroso u oscuro que una persona dude de la etiqueta;
- no contiene marcas de agua grandes, texto dominante o collage;
- es apta para una aplicación infantil;
- la licencia y procedencia están completas.

Rechazar la imagen si falla cualquiera de esas reglas. No cambiar su etiqueta a
otra clase salvo que el contenido sea inequívoco y la procedencia/licencia siga
siendo válida.

Para imágenes con caja delimitadora:

1. ampliar la caja un 10 % por cada lado;
2. limitarla a los bordes de la imagen;
3. conservar algo de contexto;
4. no deformar la imagen;
5. guardar el original en `raw` y el recorte en `interim`.

No redimensionar definitivamente a una resolución de modelo durante la
descarga. El redimensionado pertenece al adaptador de cada candidato.

## 11. Deduplicación y separación sin fugas

Ejecutar en este orden:

1. eliminar ficheros idénticos por SHA-256;
2. agrupar casi duplicados mediante pHash con distancia de Hamming menor o
   igual que 6;
3. agrupar todas las variantes de una misma observación o `source_item_id`;
4. agrupar series evidentes del mismo autor y sujeto cuando exista esa
   información;
5. asignar el grupo completo a un solo split.

Nunca puede haber dos recortes del mismo original en splits distintos. Si un
duplicado aparece con etiquetas incompatibles, rechazar todo el grupo y
registrarlo en `duplicate_groups.csv`.

Usar semilla fija `20260812` para cualquier operación aleatoria.

## 12. Auditoría humana mínima

Antes del entrenamiento:

- revisar visualmente el 100 % de validación y prueba;
- revisar al menos el 25 % de entrenamiento de cada clase;
- revisar el 100 % de imágenes sintéticas, si existen;
- generar hojas de contacto separadas por clase, modalidad y split;
- registrar rechazos en el manifiesto, sin borrar silenciosamente filas;
- ejecutar de nuevo las cuotas después de cada rechazo.

No aprobar un split con cuotas incompletas o con una clase visiblemente más
fácil que las demás por fondo, estilo o fuente.

## 13. Fases de ejecución

### Fase 0 — Congelar la línea base

Objetivo: conservar medidas del modelo actual para poder demostrar mejora.

Acciones:

1. Crear `ml/reports/baseline.md`.
2. Registrar modelo actual, SHA-256, tamaño, entrada, salida y normalización.
3. Ejecutar las pruebas Flutter existentes.
4. Medir una APK release actual y registrar su tamaño.
5. Si existe un dispositivo disponible, medir 50 inferencias después de 5
   calentamientos y registrar mediana y p95.
6. Guardar al menos los casos conocidos `caballo -> perro` como regresiones,
   sin usar imágenes privadas ni añadirlas si carecen de licencia.

Comandos mínimos desde la raíz:

```powershell
git status --short
git diff --cached
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --release
```

Criterio de salida: `baseline.md` contiene resultados reales, versión de
Flutter, dispositivo si existe y cualquier fallo previo. Un fallo previo no se
oculta ni se atribuye al modelo nuevo.

### Fase 1 — Crear el armazón reproducible

Objetivo: crear configuraciones, entorno Python, scripts vacíos con CLI y
pruebas unitarias básicas, sin descargar todavía miles de imágenes.

Acciones:

1. Usar Python 3.11 de 64 bits para maximizar compatibilidad con toolchains de
   TensorFlow y PyTorch. No reutilizar el Python 3.13 actual.
2. Crear el entorno en `ml/.venv`.
3. Si `py -3.11` no existe, detenerse y pedir autorización antes de instalar
   software en el sistema. No cambiar silenciosamente a otra versión.
4. Crear `requirements.in` para las utilidades compartidas. Añadir dependencias
   de TensorFlow, PyTorch o conversores en ficheros separados por candidato,
   para que un modelo descartado no contamine todo el entorno. Usar como punto
   de partida:

   ```text
   numpy==1.26.4
   Pillow==11.2.1
   pandas==2.2.3
   scikit-learn==1.6.1
   matplotlib==3.10.1
   seaborn==0.13.2
   PyYAML==6.0.2
   requests==2.32.3
   tqdm==4.67.1
   ImageHash==4.3.2
   ```

   Para el baseline Keras, crear `requirements-tensorflow.in` con:

   ```text
   -r requirements.in
   tensorflow==2.19.1
   ```

   Cada framework adicional tendrá su propio fichero `requirements-<id>.in` y
   lockfile. No instalar simultáneamente toolchains incompatibles en un mismo
   entorno; usar un entorno virtual por framework si aparece un conflicto.

   Si el índice de paquetes ya no sirve una distribución compatible, registrar
   el error exacto y actualizar solo el paquete que impide la instalación.
   Volver a ejecutar todas las pruebas después del cambio.
5. Resolver versiones compatibles y congelarlas en `requirements.txt` y en un
   lockfile adicional por framework utilizado.
6. Crear `classes.yaml` con el orden exacto de las 29 clases de la sección 4.
7. Crear `candidates.yaml` con el esquema definido en la fase 4, inicialmente
   sin declarar ganador.
8. Crear los scripts con `--help`, códigos de salida correctos y modo
   `--dry-run` para los descargadores.
9. Añadir pruebas Python para validar clases, candidatos, esquema del
   manifiesto y licencias permitidas.

Comandos esperados:

```powershell
py -3.11 -m venv ml\.venv
ml\.venv\Scripts\python -m pip install --upgrade pip
ml\.venv\Scripts\python -m pip install -r ml\requirements.in
ml\.venv\Scripts\python -m pip freeze | Set-Content -Encoding utf8 ml\requirements.txt
ml\.venv\Scripts\python -m unittest discover ml\tests
```

No usar `Set-Content` para crear código fuente; el agente debe usar el editor de
parches. Solo se permite aquí para la salida mecánica de `pip freeze`.

Criterio de salida: un entorno nuevo puede instalarse desde
`requirements.txt`, todas las CLI muestran ayuda y las pruebas pasan.

### Fase 2 — Descargar un piloto

Objetivo: validar fuentes, licencias y scripts con 10 elementos por clase.

Acciones:

1. Ejecutar cada fuente con `--dry-run`.
2. Descargar como máximo 10 candidatos por clase y 30 para `otro`.
3. Validar HTTP, MIME real, decodificación, dimensiones, hashes y licencia.
4. Generar manifiesto piloto y hojas de contacto.
5. Revisar manualmente todas las imágenes piloto.
6. Corregir consultas y exclusiones en `sources.yaml`.

Criterio de salida: cada clase tiene al menos 5 imágenes aceptadas, ninguna
licencia desconocida y las atribuciones se pueden reconstruir desde el
manifiesto.

### Fase 3 — Construir el dataset completo

Objetivo: alcanzar las cuotas de la sección 6.

Acciones:

1. Descargar con margen del 30 % para compensar rechazos.
2. Validar y recortar.
3. Deduplicar.
4. Generar hojas de contacto.
5. Revisar y marcar aceptación/rechazo.
6. Repetir solo para las clases que no alcancen cuota.
7. Crear splits por grupos, no por ficheros individuales.
8. Ejecutar `audit_dataset.py`.

El auditor debe fallar con código distinto de cero si:

- falta una clase;
- falta una cuota por modalidad o split;
- existe una licencia no permitida;
- falta atribución;
- hay hash o pHash compartido entre splits;
- un fichero no se puede decodificar;
- las rutas del manifiesto no existen;
- una fila aceptada carece de dimensiones o procedencia.

Criterio de salida: `dataset_summary.json` informa 8.960 imágenes aceptadas o
más, mantiene las proporciones y no encuentra fugas.

### Fase 4 — Descubrir y validar candidatos

Objetivo: crear una lista abierta de opciones viables antes de gastar tiempo en
entrenamiento completo.

Buscar en documentación primaria, repositorios oficiales, papers y model cards
actuales. Considerar, sin limitarse a:

- clasificadores supervisados móviles como MobileNet, EfficientNet-Lite,
  MobileNetV4 u otras familias equivalentes;
- modelos de embeddings con prototipos por clase;
- modelos visual-texto eficientes como MobileCLIP/MobileCLIP2;
- clasificadores destilados o cuantizados ya optimizados para edge;
- detector multiclase o detector+clasificador si resuelve encuadre y fondo;
- un modelo común o dos artefactos equivalentes, uno por plataforma.

MobileNetV3 Small será únicamente un baseline de control porque tiene una ruta
Keras sencilla. No tiene preferencia en la selección final.

Registrar cada opción en `ml/config/candidates.yaml` con:

```yaml
- id: identificador_estable
  approach: direct_classifier|embedding|vision_language|detector|two_stage
  architecture: nombre_y_variante
  framework: tensorflow|pytorch|otro
  source_url: url_primaria
  checkpoint: version_o_hash
  code_license: licencia
  weights_license: licencia
  commercial_redistribution: true|false|unknown
  input_resolution: numero_o_lista
  training_mode: fine_tune|linear_probe|prototype|zero_shot
  export_path: litert|coreml|onnx|otro
  runtime_android: nombre
  runtime_ios: nombre
  expected_artifacts: lista
  known_custom_ops: lista
  notes: texto
```

Reglas de admisión:

1. Rechazar inmediatamente licencia `unknown`, no comercial o incompatible
   con redistribución. No interpretar silencio como permiso.
2. Rechazar dependencias de nube o envío de fotografías.
3. Rechazar un modelo sin versión/checkpoint reproducible.
4. Hacer una conversión mínima con pesos originales y una inferencia de humo
   antes de entrenar.
5. Rechazar custom ops que obliguen a mantener un runtime nativo propio sin una
   ventaja medida y documentada.
6. Rechazar una ruta que no pueda cubrir Android e iOS, salvo que exista otro
   artefacto equivalente y mantenible para la plataforma restante.
7. No admitir más de seis candidatos a la criba para evitar exploración sin
   límite. Si hay más, conservar los seis con mejor evidencia publicada de
   precisión/latencia y menor complejidad de integración.

La lista debe incluir, si sus licencias y conversiones lo permiten, al menos:

- un CNN supervisado pequeño y sencillo;
- un clasificador móvil moderno distinto del baseline;
- un enfoque de embeddings o visual-texto para comprobar dibujos;
- un pipeline con localización será obligatorio en la criba si el piloto
  muestra que el animal ocupa menos del 30 % en al menos el 20 % de las
  imágenes representativas; también puede incluirse antes si existe evidencia
  técnica suficiente.

Criterio de salida: entre tres y seis candidatos tienen licencia verificada,
inferencia de humo y ruta móvil documentada. El test no se ha leído.

### Fase 5 — Criba barata y comparable

Objetivo: descartar pronto opciones lentas, enormes, inexportables o claramente
imprecisas.

Crear una submuestra estratificada fija del 25 % de entrenamiento y usar la
validación completa. Mantener semilla `20260812` y los mismos `image_id` para
todos los candidatos. No usar test.

Para cada candidato:

1. usar su preprocesado y resolución nativos; justificar resoluciones fuera del
   rango de referencia 192-320 con evidencia de calidad o rendimiento;
2. ejecutar como máximo 10 épocas o 2 horas de entrenamiento, lo que ocurra
   antes; un modelo zero-shot/prototípico usa su proceso equivalente;
3. permitir un único conjunto razonable de hiperparámetros tomado de la fuente
   oficial, sin búsqueda específica;
4. exportar un artefacto preliminar al runtime objetivo;
5. medir tamaño, tiempo de carga e inferencia aproximada;
6. calcular macro F1 global, F1 por modalidad, recall de `otro` y fallos
   caballo/perro en validación;
7. registrar tiempo humano estimado de integración y número de dependencias
   nativas nuevas.

Rechazar en la criba si:

- no se puede exportar o abrir el artefacto móvil;
- el artefacto preliminar supera 25 MB;
- p95 preliminar supera 200 ms en un dispositivo disponible;
- macro F1 de validación es inferior a 0,65;
- no existe una forma calibrable de devolver `otro`;
- la conversión cambia más del 5 % de las predicciones top-1;
- requiere pasos manuales no reproducibles.

Seleccionar como máximo tres finalistas. Conservar los candidatos no dominados
en calidad, tamaño y latencia. Si dos son casi iguales, conservar el más fácil
de convertir e integrar. Se puede mantener un candidato especialmente bueno en
ilustraciones aunque su resultado global sea ligeramente inferior.

Criterio de salida: `ml/reports/candidate_screening.md` explica con medidas por
qué cada candidato continúa o se descarta. No declara todavía un ganador.

### Fase 6 — Entrenar, exportar y medir finalistas

Objetivo: comparar los finalistas con todo el entrenamiento y la misma
validación, incluyendo sus artefactos móviles reales.

El adaptador de cada candidato debe implementar operaciones equivalentes:

```text
prepare -> train_or_fit -> predict -> export -> runtime_predict -> benchmark
```

Reglas comunes:

- semilla `20260812`;
- splits y etiquetas idénticos;
- aumentos solo en entrenamiento;
- nada de test;
- máximo dos configuraciones completas por candidato;
- parada temprana sobre validación;
- guardar pesos, configuración, historial, hashes, dependencias y duración;
- documentar cualquier preprocesado diferente;
- no favorecer un candidato dándole más imágenes o revisión manual.

Aumentos iniciales recomendados, ajustables solo con justificación común:

- volteo horizontal;
- rotación máxima aproximada de 10 grados;
- zoom máximo de 15 %;
- traslación máxima de 10 %;
- contraste máximo de 15 %;
- brillo moderado;
- resize conservando proporción y relleno neutro.

No usar volteo vertical, recortes que eliminen cabeza/cuerpo ni aumentos en
validación o prueba.

Para modelos entrenables, comenzar con linear probe/cabeza congelada y después
fine-tuning parcial. Para embeddings o visual-texto, precomputar en build los
textos o prototipos que no cambian; no enviar un codificador de texto al móvil
si no es necesario. Un detector debe medirse como pipeline completo, no solo su
clasificador posterior.

Exportar y probar las variantes razonables de cuantización que soporte cada
candidato: INT8, float16 u otra opción estable. Usar al menos 200 imágenes
representativas de entrenamiento para cuantización calibrada. No asumir que
INT8 será siempre el ganador: medir pérdida de calidad y velocidad real.

Para cada artefacto móvil calcular en validación:

- accuracy top-1;
- macro precision, macro recall y macro F1;
- precision, recall y F1 por clase;
- matriz de confusión absoluta y normalizada;
- recall de `otro` y falsos positivos sobre `otro`;
- macro F1 separado para foto, ilustración y juguete;
- porcentaje de imágenes no-perro identificadas como Perro;
- distribución top-1 y margen top-1/top-2 o medida equivalente;
- paridad con el modelo fuente;
- tamaño total de todos los artefactos necesarios;
- tiempo de carga, mediana y p95 en Android e iOS disponibles;
- memoria máxima aproximada;
- complejidad de integración y mantenimiento.

Calibrar el rechazo por candidato solo con validación. Para softmax, explorar
top-1 de 0,40 a 0,90 y margen de 0,05 a 0,40 en pasos de 0,01. Para embeddings,
detectores o similitudes, implementar el barrido equivalente y documentarlo.

Puertas mínimas:

- macro F1 global >= 0,87;
- recall de cada animal >= 0,75;
- recall de `otro` >= 0,90;
- falsos positivos sobre `otro` <= 0,05;
- macro F1 de ilustraciones >= 0,80;
- macro F1 de juguetes >= 0,75;
- `Perro` incorrecto en menos del 5 % del conjunto no-perro;
- caballo no devuelve Perro como resultado fiable;
- caída del artefacto móvil frente al modelo fuente <= 0,01 de macro F1;
- artefactos totales <= 19,4 MB; objetivo preferido <= 15 MB;
- p95 release <= 100 ms en el Android objetivo;
- carga inicial <= 1.500 ms;
- ningún tensor o score contiene NaN o infinito;
- runtime disponible y reproducible para Android e iOS.

Un candidato entre 15 y 19,4 MB solo puede continuar si mejora al menos 0,03 de
macro F1 frente al mejor candidato de 15 MB o menos. Ninguno puede superar el
tamaño del modelo actual.

Asignar además una puntuación de practicidad de 0, 1 o 2 en cada dimensión:

- conversión reproducible;
- una sola canalización para Android/iOS;
- madurez y mantenimiento del runtime;
- cantidad de código nativo/dependencias;
- claridad de licencia y atribución;
- facilidad para volver a entrenar;
- facilidad para inspeccionar y probar salidas.

Publicar la frontera de Pareto: ningún candidato oculto y ninguna media que
compense una puerta fallida. Entre los candidatos que superan todo y quedan a
0,02 de macro F1 del mejor, elegir el de mayor practicidad. Empates: menor p95,
después menor tamaño y después menor tiempo de entrenamiento.

Criterio de salida: `ml/reports/model_selection.md` contiene la tabla completa,
la frontera de Pareto, el ganador, el artefacto, umbrales y hashes congelados.
El test sigue sin leerse.

### Fase 7 — Prueba final única y promoción

Objetivo: comprobar una sola vez el ganador ya congelado y promoverlo sin
ajustes posteriores.

Acciones:

1. Verificar forma, tipos, cuantización, etiquetas, metadata y hashes.
2. Abrir el test por primera vez.
3. Ejecutar el pipeline móvil final sobre todo el test.
4. Aplicar las mismas puertas de calidad de la fase 6.
5. Comparar una vez con el modelo fuente para documentar paridad.
6. Generar `test_metrics.json`, matriz de confusión y hojas de errores.

Si falla una puerta, declarar el modelo no publicable. No modificarlo mirando
esos errores y volver a presentar el mismo test como independiente. Para otra
iteración se necesitará un nuevo test con sujetos y procedencias diferentes.

Promover los artefactos aprobados bajo `assets/models/` con nombres estables y
un `animal_classifier_v1_manifest.json` que indique qué carga cada plataforma.
Si gana LiteRT/TFLite, usar:

```text
assets/models/animal_classifier_v1.tflite
assets/models/animal_classifier_v1_labels.txt
assets/models/animal_classifier_v1_manifest.json
```

Si gana otro formato, usar nombres equivalentes y documentar su empaquetado. No
añadir dos runtimes a producción salvo que el ganador realmente necesite
artefactos distintos por plataforma.

Actualizar `tool/verify_model.py` si gana TFLite; si no, crear un verificador
equivalente con las mismas comprobaciones. No borrar todavía los artefactos
anteriores.

### Fase 8 — Integración Flutter aislada

Objetivo: cambiar únicamente el servicio de clasificación y el catálogo.

Acciones en orden:

1. Añadir pruebas de compatibilidad de colección con categorías heredadas.
2. Añadir `modelLabel` e `isDiscoverable` al modelo local `Animal`.
3. Añadir las 15 entradas nuevas y conservar las 42 anteriores.
4. Crear mapas separados por nombre persistido y por `modelLabel`.
5. Cambiar el servicio para cargar el modelo y las 29 etiquetas nuevas.
6. Validar tipo, forma, cuantización, rango y longitud del tensor de salida.
7. Aplicar softmax solo si el modelo no la incluye; no aplicar dos veces.
8. Aplicar umbral y margen congelados en la fase 6.
9. Convertir `otro` o una salida bajo umbral en estado `unrecognized`.
10. Mostrar como máximo dos alternativas válidas.
11. Ejecutar preprocesado e inferencia fuera del método `build` y sin bloquear
    el isolate de interfaz.
12. Mantener `ClassifierService` inyectable y disponer el intérprete.
13. Mantener confirmación manual antes de guardar en la colección.
14. Actualizar el progreso para usar solo animales descubribles.
15. Mostrar datos heredados sin contarlos como nuevos descubrimientos.

Mensajes requeridos:

- rechazo: `No hemos reconocido uno de los animales del catálogo. Prueba con el animal más cerca y con buena luz.`
- error de inferencia: `No se ha podido identificar el animal. Inténtalo de nuevo.`
- modelo no cargado: `No se ha podido cargar el modelo. Inténtalo de nuevo.`

No introducir Firebase, permisos o lógica del modelo dentro de widgets.

### Fase 9 — Pruebas Flutter

Añadir como mínimo:

- etiquetas: 29 líneas, sin duplicados y en orden esperado;
- tensor con longitud distinta de 29 produce error controlado;
- índice, tipo o valor no finito produce error controlado;
- `otro` produce `unrecognized`;
- top-1 bajo umbral produce `unrecognized`;
- margen insuficiente produce `unrecognized`;
- resultado fiable produce `success`;
- no se puede iniciar una segunda inferencia mientras hay otra activa;
- caballo de regresión no se confirma como Perro;
- colecciones antiguas conservan todos sus recuentos;
- progreso usa 28 clases descubribles;
- el intérprete se cierra al disponer el servicio;
- errores y acciones permanecen en español.

Ejecutar:

```powershell
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --release
```

No aceptar supresiones del analizador ni `print`/`debugPrint` de producción.

### Fase 10 — Medición en dispositivos

Probar como mínimo:

- un Android físico de prestaciones medias o bajas;
- un Android físico moderno o emulador solo como comparación;
- un iPhone físico si el proyecto mantiene soporte iOS.

Por dispositivo:

1. build release;
2. 5 inferencias de calentamiento;
3. 50 inferencias medidas;
4. registrar mediana y p95;
5. registrar tiempo de carga del modelo;
6. registrar tamaño APK/AAB/IPA;
7. probar cámara y galería;
8. probar rotaciones EXIF;
9. probar imagen muy grande, oscura, vacía y corrupta;
10. probar sin red para confirmar funcionamiento local.

Puertas:

- p95 de inferencia <= 100 ms en Android objetivo;
- carga inicial <= 1.500 ms;
- ninguna congelación visible de interfaz;
- sin crecimiento de memoria continuo tras 20 inferencias;
- el artefacto release no aumenta respecto a la línea base; si aumenta, detener
  y justificar antes de continuar.

### Fase 11 — Documentación y retirada del modelo anterior

Crear `docs/models/animal_classifier_v1.md` con:

- propósito y limitaciones;
- 29 clases y orden;
- fuentes, licencias y fecha de recuperación;
- cantidades por clase, modalidad y split;
- arquitectura y entrenamiento;
- entrada, normalización, salida y cuantización;
- umbral y margen;
- métricas globales, por clase y modalidad;
- matriz de confusión;
- tamaño, SHA-256 y latencias;
- versión de código y hash de manifiestos;
- dispositivos probados;
- errores conocidos;
- instrucciones de reproducción.

Actualizar `docs/MODELO.md`, información del modelo en la app y la fase 7 del
roadmap.

Solo después de que Android, iOS, análisis y pruebas estén verdes:

1. retirar del `pubspec.yaml` el modelo, etiquetas y agrupado antiguos;
2. eliminar los artefactos antiguos en un cambio explícito y revisable;
3. confirmar que ningún código los referencia con `rg`;
4. volver a ejecutar análisis, pruebas y builds;
5. registrar cuánto tamaño se ha reducido.

## 14. Contrato técnico del pipeline final

La solución final debe publicar un fichero JSON junto al informe con este
esquema conceptual:

```json
{
  "pipeline_id": "animal_classifier_v1",
  "approach": "REEMPLAZAR_CON_ENFOQUE_REAL",
  "runtime": {
    "android": "REEMPLAZAR",
    "ios": "REEMPLAZAR"
  },
  "artifacts": [
    {
      "platform": "android_ios_o_both",
      "path": "REEMPLAZAR",
      "sha256": "REEMPLAZAR"
    }
  ],
  "input": {
    "resolution": "REEMPLAZAR_CON_RESOLUCION_REAL",
    "dtype": "REEMPLAZAR",
    "color_order": "RGB",
    "resize": "REEMPLAZAR",
    "normalization": "REEMPLAZAR"
  },
  "app_result": {
    "labels_count": 29,
    "score_kind": "softmax_similarity_o_equivalente",
    "labels_sha256": "REEMPLAZAR_CON_HASH_REAL"
  },
  "decision": {
    "minimum_top1": "REEMPLAZAR_CON_VALOR_VALIDADO",
    "minimum_margin": "REEMPLAZAR_CON_VALOR_VALIDADO",
    "fallback_label": "otro"
  }
}
```

El manifiesto puede añadir tensores, cajas, prototipos, prompts o componentes
si gana un pipeline complejo. La aplicación, el informe y las pruebas deben
compartir exactamente el mismo contrato observable de 29 resultados. No copiar
los valores de ejemplo sin medirlos.

## 15. Informes que deben existir al terminar

```text
ml/reports/baseline.md
ml/reports/dataset_summary.json
ml/reports/duplicate_groups.csv
ml/reports/candidate_screening.md
ml/reports/model_selection.md
ml/reports/test_metrics.json
ml/reports/per_class_metrics.csv
ml/reports/confusion_matrix.csv
ml/reports/confusion_matrix.png
ml/reports/runtime_parity.json
ml/reports/device_benchmarks.csv
docs/models/animal_classifier_v1.md
```

No escribir métricas a mano. Deben proceder de scripts reproducibles.

## 16. Condiciones de parada

Detener el trabajo y no integrar el modelo si ocurre cualquiera de estas
condiciones:

- no se puede verificar la licencia de alguna imagen aceptada;
- faltan cuotas de una clase o modalidad;
- hay duplicados entre splits;
- se ha usado el test para elegir el modelo o el umbral;
- macro F1, recall por clase o rechazo de `otro` no superan las puertas;
- el artefacto móvil pierde más de 0,01 de macro F1 frente al modelo fuente;
- etiquetas y salida no coinciden;
- los artefactos superan 19,4 MB o superan 15 MB sin la mejora exigida en la
  fase 6;
- la latencia p95 supera 100 ms en el Android objetivo;
- falla el build de una plataforma soportada;
- se pierden o dejan de mostrar datos antiguos;
- la interfaz presenta un resultado dudoso como identificación fiable;
- aparecen credenciales, datos personales o imágenes sin procedencia.

Ante un fallo de calidad, mejorar primero los datos de las clases confundidas.
No cambiar simultáneamente arquitectura, aumentos, clases y umbrales porque se
perdería la capacidad de atribuir la mejora.

## 17. Secuencia recomendada de cambios revisables

No crear un único cambio gigante. Separar, como mínimo, en:

1. infraestructura y scripts de dataset;
2. manifiestos, auditoría y documentación de datos;
3. entrenamiento, evaluación y selección;
4. artefactos móviles, etiquetas/manifiesto y model card;
5. integración del servicio y catálogo compatible;
6. pruebas de regresión y estados de interfaz;
7. retirada de artefactos antiguos y medidas finales.

Cada cambio debe poder revisarse y revertirse sin depender de refactors no
relacionados.

## 18. Estimación realista

| Trabajo | Tiempo estimado |
|---|---:|
| Armazón y descargadores | 1 día |
| Descarga, limpieza y licencias | 2-3 días |
| Revisión visual y splits | 1-2 días |
| Descubrimiento y criba de candidatos | 1-2 días |
| Entrenamiento, exportación y selección | 2-3 días |
| Integración Flutter del ganador | 1-2 días |
| Pruebas físicas y documentación | 1 día |
| Total esperado | 9-14 días laborables |

La descarga automática no elimina la revisión visual. La calidad y la licencia
de los datos son la parte que más tiempo consume.

## 19. Definición final de terminado

El proyecto solo puede declarar completada esta mejora cuando:

- [ ] existen exactamente 28 animales descubribles y `otro`;
- [ ] el dataset cumple cuotas, licencias, deduplicación y revisión;
- [ ] el test permaneció cerrado hasta congelar modelo y umbrales;
- [ ] todas las puertas de calidad están verdes;
- [ ] el artefacto móvil mantiene paridad con su modelo fuente;
- [ ] tamaño y latencia están medidos en release;
- [ ] Android e iOS funcionan sin conexión;
- [ ] caballo no se identifica de forma fiable como Perro;
- [ ] entradas dudosas muestran `No reconocido`;
- [ ] las colecciones antiguas conservan sus datos;
- [ ] formato, analizador, tests y builds relevantes están verdes;
- [ ] el modelo, dataset y licencias están documentados;
- [ ] el modelo anterior solo se retiró después de todas las comprobaciones.

## 20. Referencias técnicas primarias

El agente debe preferir estas referencias frente a blogs o ejemplos de
terceros:

- Clasificación de imágenes en Google AI Edge:
  <https://developers.google.com/edge/mediapipe/solutions/vision/image_classifier>
- Entrenamiento y exportación de clasificación para LiteRT/TFLite:
  <https://developers.google.com/edge/litert/libraries/modify/image_classification>
- Modelos EfficientNet-Lite y medidas de referencia:
  <https://github.com/tensorflow/tpu/tree/master/models/official/efficientnet/lite>
- API oficial de MobileNetV3 en Keras:
  <https://keras.io/api/applications/mobilenet/>
- Paper oficial de MobileNetV4:
  <https://arxiv.org/abs/2404.10518>
- Repositorio oficial de MobileCLIP y MobileCLIP2:
  <https://github.com/apple/ml-mobileclip>
- Conversión desde varios frameworks a LiteRT:
  <https://developers.google.com/edge/litert/conversion/overview>
- Plugin Flutter publicado por `tensorflow.org`:
  <https://pub.dev/packages/tflite_flutter>
- Detección de objetos en Google AI Edge:
  <https://developers.google.com/edge/mediapipe/solutions/vision/object_detector>

Las versiones y requisitos de plataforma pueden cambiar. Antes de integrar un
runtime, comprobar su documentación oficial actual y registrar la versión
exacta usada.
