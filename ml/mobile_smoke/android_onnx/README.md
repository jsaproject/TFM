# Smoke test Android de ONNX Runtime

Aplicación mínima separada de Flutter para comprobar que el artefacto ONNX de
TinyCLIP 39M con los 28 prototipos reales puede cargarse y ejecutarse en un dispositivo Android real. No es
código de producción ni mide calidad: usa una entrada determinista y registra
tamaño, inicialización, mediana, p95 y forma de salida.

El modelo se copia desde `ml/artifacts/smoke` durante el build y no se versiona.
La dependencia es el paquete Android oficial de ONNX Runtime publicado en
Maven Central.

Desde la raíz del repositorio:

```powershell
android\gradlew.bat -p ml\mobile_smoke\android_onnx :app:assembleDebug
adb install -r ml\mobile_smoke\android_onnx\app\build\outputs\apk\debug\app-debug.apk
adb logcat -s ANIMAL_ONNX_SMOKE:I *:S
```
