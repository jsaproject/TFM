# Pipeline extensible de clasificación animal

Este directorio contiene el trabajo reproducible de datos y modelos. Los 28
animales actuales pertenecen al catálogo v1; no son un límite técnico.

## Contrato principal

`config/classes.yaml` es la única fuente de verdad para las clases y el orden
de la salida. Todo script debe leer ese fichero y calcular el número de salidas
a partir de las clases activas. `otro` se identifica mediante `fallback_id`, no
por una posición escrita a mano.

Cada artefacto publicable incluirá:

- versión y hash del catálogo;
- IDs ordenados de salida;
- procedencia, licencia y versión de la arquitectura y pesos iniciales;
- configuración de preprocesado;
- tamaño, latencia y métricas medidas;
- hash SHA-256 del modelo exportado.

## Cómo ampliar el catálogo

1. Crear una versión nueva de `config/classes.yaml` conservando los IDs
   existentes y añadiendo las clases al final.
2. Reunir, revisar y dividir los datos de las clases nuevas.
3. Regenerar el manifiesto completo y reentrenar todas las salidas.
4. Ejecutar evaluación, exportación y pruebas móviles.
5. Publicar el modelo, las etiquetas y el manifiesto como una unidad.

No se añade una clase modificando constantes del entrenador o de la app.

## Prueba cero-shot con TinyCLIP

El candidato TinyCLIP pequeño puede evaluarse sin entrenamiento sobre el
piloto revisado. Sus pesos y el procesador se guardan en `ml/cache/`, que no se
versiona:

```powershell
.\ml\.venv-pytorch\Scripts\python.exe -m ml.tools.evaluate_tinyclip_pilot --allow-download
```

Después de la primera descarga, omitir `--allow-download` fuerza una ejecución
completamente local. Los prompts se definen en
`config/tinyclip_prompts.yaml`; añadir clases exige actualizar el catálogo y
ese mapa, pero no modificar el evaluador.
