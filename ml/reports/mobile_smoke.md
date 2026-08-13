# Criba de ejecución en Android real

Fecha: 2026-08-12. Dispositivo: Samsung SM-S918B, Android API 36,
`arm64-v8a`. Se usaron cuatro hilos y cinco calentamientos. Los pesos de los
clasificadores directos todavía son aleatorios, por lo que este informe mide
únicamente compatibilidad, tamaño y velocidad; no mide acierto.

| Candidato y runtime | Resultado | Tamaño de modelo | Mediana | p95 |
|---|---|---:|---:|---:|
| MobileNetV3 Small / TFLite XNNPACK | Pasa | 1,04 MiB | 2,626 ms | 3,743 ms |
| EfficientNet-Lite0 / TFLite XNNPACK | Pasa | 3,50 MiB | 39,033 ms | 42,644 ms |
| TinyCLIP visual / TFLite | Falla al invocar | 31,77 MiB | — | — |
| TinyCLIP visual INT8 / ONNX Runtime 1.29.0 | Ejecuta, pero no pasa presupuesto | 9,00 MiB | 298,306 ms | 383,794 ms |
| DINOv2 Small INT8 / ONNX Runtime | No se instala | 23,76 MiB | — | — |

El TFLite convertido de TinyCLIP se inicializa, pero falla en Android en el
nodo `FILL` porque el grafo conserva dimensiones no válidas. No se contabilizan
como latencia sus invocaciones fallidas.

Para no confundir un problema del conversor con uno del modelo, TinyCLIP se
probó también mediante el paquete Android oficial de ONNX Runtime. La salida
`[1, 29]` fue correcta, pero el runtime `arm64-v8a` añadió 32.204.216 bytes y
el APK mínimo de prueba alcanzó 40.163.546 bytes. Además, su mediana fue unas
113 veces la de MobileNetV3 Small en el mismo teléfono. La vía ONNX es gratuita
y técnicamente válida, pero no es la más eficiente ni práctica para esta app.

DINOv2 no se ejecuta en el teléfono porque su ONNX cuantizado ya ocupa 23,76
MiB y en escritorio es más lento que TinyCLIP. Probarlo con el mismo runtime no
puede mejorar las puertas ya fallidas de tamaño y latencia; detenerlo evita
trabajo sin información útil.

Conclusión provisional: MobileNetV3 Small y EfficientNet-Lite0 pasan a la
comparación de calidad con datos reales. TinyCLIP sigue siendo útil como modelo
de escritorio para explorar etiquetas o ayudar a revisar datos, pero no como
runtime de producción en esta configuración. Aún no hay ganador: la precisión
con fotografías, dibujos y juguetes decidirá si el modelo más pequeño basta.

## Corrección (2026-08-13)

Las dos filas de TinyCLIP de la tabla anterior no miden el modelo:

- El fallo en el nodo `FILL` procede de una cadena de formas dinámicas que el
  conversor no plegaba, y del backend `flatbuffer_direct`, que además produce
  resultados numéricamente incorrectos. Con el grafo simplificado y el backend
  `tf_converter`, TinyCLIP convierte y ejecuta.
- Los 298 ms se midieron con INT8 sobre ONNX Runtime, la configuración más
  desfavorable, y sobre un artefacto cuya cabeza de clasificación contenía
  vectores aleatorios.

La conclusión de este informe queda anulada para TinyCLIP. El detalle, las
medidas nuevas y la elección de precisión están en `tinyclip_remedicion.md`.
Las filas de MobileNetV3 Small y EfficientNet-Lite0 siguen siendo válidas.
