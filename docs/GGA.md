# Gentleman Guardian Angel en TFM

Este repositorio usa [Gentleman Guardian Angel](https://github.com/Gentleman-Programming/gentleman-guardian-angel) como revisor IA antes de publicar cambios. El pre-commit ejecuta comprobaciones deterministas y el pre-push usa GGA contra `AGENTS.md`; no sustituye al build de CI.

## Configuración del proyecto

- Proveedor: Codex CLI.
- Reglas principales: `AGENTS.md`.
- Reglas especializadas: `docs/code-review/`.
- Configuración: `.gga`.
- Modo estricto: una respuesta ambigua o un fallo del proveedor bloquea el commit.
- Timeout máximo del proveedor: 300 segundos.
- Tests Dart incluidos en la revisión; archivos generados, secretos locales y configuración Firebase generada excluidos.

## Preparación de una máquina nueva

1. Instalar Codex CLI e iniciar sesión.
2. Instalar GGA siguiendo la documentación oficial. En Windows se necesita Git Bash.
3. Desde la raíz del repositorio, ejecutar:

```bash
gga config
git config --local core.hooksPath .githooks
```

4. Confirmar que Git usa los hooks versionados:

```bash
git config --get core.hooksPath
```

Debe devolver `.githooks`. El pre-commit ejecuta formato, análisis y tests; el pre-push ejecuta GGA en modo CI sobre los commits desde el upstream.

La instalación local validada usa GGA `v2.10.1`. Al actualizar GGA, revisar primero su changelog y volver a ejecutar una prueba pequeña.

## Uso

El flujo normal no requiere comandos adicionales:

```bash
git add <archivos>
git commit -m "tipo: descripción"
```

Al confirmar, Git ejecuta formato, análisis y tests. Al publicar, Git ejecuta GGA. También puede ejecutarse manualmente:

```bash
gga run --no-cache
gga cache status
gga config
```

Mantener los commits pequeños y centrados en una responsabilidad. Una auditoría con muchos archivos puede superar el timeout y es menos precisa que varias revisiones acotadas.

## Si una revisión supera el tiempo límite

El pre-push usa `gga run --ci`, por lo que Git recibe directamente el resultado
de la revisión. Si Codex no responde antes del valor `TIMEOUT` configurado (300
segundos), el push falla de forma segura, pero el commit local se conserva.
Reintenta cuando el proveedor responda o ejecuta `gga run --ci` manualmente
para diagnosticarlo. No omitas el hook como solución habitual.

## Qué bloquea

- Regresiones de seguridad, autenticación, permisos o privacidad.
- Pérdida o corrupción de datos sin migración.
- Errores async/lifecycle, éxitos falsos y excepciones silenciadas.
- Nueva lógica Firebase/TFLite dentro de widgets.
- UI no responsive o inaccesible.
- Cambios de comportamiento sin pruebas proporcionales.
- Incompatibilidades entre el modelo TFLite, etiquetas y preprocessing.

## Validación determinista

El pre-commit ejecuta los tres primeros comandos. Antes de publicar una rama o PR también deben pasar:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

GitHub Actions ejecuta estas comprobaciones en cada push y pull request mediante `.github/workflows/flutter.yml`.

## CI con revisión IA

GGA admite `gga run --pr-mode`, pero no se activa en GitHub Actions hasta disponer de una credencial segura para el proveedor y de un presupuesto de uso. No se debe versionar ninguna credencial para habilitarlo.
