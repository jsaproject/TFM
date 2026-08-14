# Especificación de assets — fase 2

Esta especificación no autoriza incorporar, redistribuir ni eliminar imágenes.
Complementa el inventario de fase 1 y será el contrato de la biblioteca local
de 28 retratos prevista para fase 6.

| Tipo | Proporción y recorte | Presupuesto técnico | Procedencia y licencia | Etiqueta semántica |
| --- | --- | --- | --- | --- |
| Retrato de especie | Maestro 4:3; sujeto completo o rostro reconocible dentro del 80 % central; sin texto incrustado. | JPEG o WebP, sRGB, lado largo 1600 px máximo, 350 KB objetivo y 500 KB máximo. | URL de origen, autor, licencia, atribución literal, fecha de descarga y responsable de revisión obligatorios. | `Retrato de {especie}`; si es decorativo, marcarlo explícitamente como decorativo. |
| Foto tomada por la persona usuaria | Marco 4:3 visible, sin recortar ni reorientar el original durante la presentación. | Vista previa limitada al tamaño del marco; no persistir una copia nueva por motivos visuales. | Propiedad de la persona usuaria; no se publica ni se añade al catálogo. | Describir el resultado solo si aporta información que no esté ya en texto cercano. |
| Imagen de apoyo editorial | 16:9 o 4:3 según composición; zona segura del 10 % en todos los bordes. | WebP preferido, lado largo 1920 px máximo, 500 KB máximo. | Misma ficha completa de origen y licencia que los retratos. | Etiqueta breve y descriptiva o decorativa si repite contenido textual. |
| Placeholder temporal | Vector o composición Material propia; no emoji. | Sin raster adicional ni dependencia nueva. | Creación propia documentada. | `Retrato pendiente de {especie}`. |

## Manifiesto requerido por archivo

Cada asset candidato llevará una entrada versionada con: identificador de
especie, ruta, dimensiones originales y publicadas, peso, formato, proporción,
recorte maestro, origen, URL, autor, licencia, atribución, fecha de descarga,
revisor, uso permitido y etiqueta semántica. Un campo desconocido bloquea su
promoción a la biblioteca final.

## Criterios de composición

- El marco `PhotoFrame` de fase 2 usa 4:3 y bordes suaves; la imagen debe
  mantener su foco principal visible con `BoxFit.cover` solo cuando el recorte
  maestro esté aprobado.
- No se usa `farm_animals.png` en composiciones nuevas, según la decisión de
  fase 1.
- No se sustituyen aún los fallbacks actuales: las fotos existentes continúan
  provisionales y los emojis no se convierten en iconos de interfaz nuevos.
