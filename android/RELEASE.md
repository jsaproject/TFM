# Preparar una APK firmada

La clave de firma es necesaria para actualizar la aplicación en el futuro. Guárdala fuera del repositorio en un gestor de secretos o almacenamiento cifrado con copia de seguridad.

1. Genera un almacén de claves en una ubicación segura:

   ```powershell
   keytool -genkeypair -v -keystore ..\keys\granja-michi-upload.jks -alias upload -keyalg RSA -keysize 2048 -validity 10000
   ```

2. Copia `android/key.properties.example` como `android/key.properties` y completa las contraseñas, alias y ruta del almacén.
3. Genera y prueba el artefacto:

   ```powershell
   flutter build apk --release
   ```

   La APK se crea en `build/app/outputs/flutter-apk/app-release.apk`. Para Google Play usa tambi\u00e9n `flutter build appbundle --release`.

La compilación release se detiene si falta `key.properties`; así nunca se distribuye por error una APK firmada con la clave de depuración.
