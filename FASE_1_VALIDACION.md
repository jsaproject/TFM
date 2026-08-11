# Validación de la fase 1

## Comprobaciones que requieren acceso al proyecto Firebase

- En **Authentication > Sign-in method**, habilita **Correo electrónico/contraseña** y **Anónimo**.
- Publica las reglas de `firestore.rules`. Solo conceden operaciones sobre el documento cuyo identificador coincide con `request.auth.uid`; cualquier otra ruta queda denegada.

## Prueba manual en Android físico

Instala una compilación de desarrollo y verifica, en este orden:

1. Registro, inicio de sesión, cierre de sesión e inicio como invitado.
2. Cámara: conceder permiso, denegarlo y cancelar el selector.
3. Galería: seleccionar una imagen y cancelar el selector.
4. Colección: comprobar que la cuenta ve únicamente sus propios animales y que un invitado ve el aviso para iniciar sesión.
5. Sin conexión: activar modo avión, repetir inicio de sesión, clasificación y apertura de colección; los mensajes deben indicar claramente la falta de conexión. Tras recuperar la red, comprueba que las predicciones pendientes aparecen en la colección.

## Distribución

Sigue [android/RELEASE.md](android/RELEASE.md) para generar una APK release firmada. La clave y `android/key.properties` se excluyen de Git deliberadamente.
