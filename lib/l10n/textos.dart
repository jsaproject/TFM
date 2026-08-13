/// Todos los textos de la interfaz, en un único fichero.
///
/// Igual que `MichiTokens` centraliza el color y el tamaño, esto centraliza el
/// lenguaje: una revisión de tono se hace de una sentada y no fichero a
/// fichero. Ningún widget escribe una cadena literal visible.
///
/// [TextosNino] es lo que lee un niño de 4 a 8 años. Se rige por las reglas de
/// la FASE 2 de `docs/PLAN_UX_INFANTIL.txt`:
///
///   - Máximo 8 palabras por frase.
///   - Verbos en imperativo y en segunda persona.
///   - Ni una palabra técnica (ver [palabrasProhibidas]).
///   - Números en cifras y redondos, nunca porcentajes ni decimales.
///
/// [TextosAdulto] es lo que solo lee un adulto: acceso a la cuenta, ajustes,
/// privacidad y borrado. Ahí sí caben las frases largas y los tecnicismos.
///
/// `test/l10n/textos_test.dart` comprueba esas reglas sobre
/// [TextosNino.revisables]. Al añadir una frase nueva para el niño hay que
/// añadirla también a esa lista.
library;

abstract final class TextosNino {
  // Marca y navegación.
  static const marca = 'La granja de Michi';
  static const navegacionInicio = 'Inicio';
  static const navegacionColeccion = 'Colección';
  static const navegacionAdultos = 'Adultos';

  // Bienvenida.
  static const bienvenidaPasoGaleria = 'O busca una foto';
  static const bienvenidaPasoColeccion = 'Guarda todos los animales';
  static const bienvenidaBoton = 'Empezar';

  // Pantalla de la foto.
  static const saludoSinNombre = 'Hola';
  static String saludo(String nombre) => 'Hola, $nombre';
  static const buscaUnAnimal = 'Busca un animal.';
  static const consejosTitulo = 'Consejos';
  static const consejoUnAnimal = 'Un animal';
  static const consejoLuz = 'Mucha luz';
  static const consejoCerca = 'De cerca';
  static String conozcoAnimales(int total) => 'Conozco $total animales.';
  static const dibujoDeAnimales = 'Dibujo de animales';
  static const tuFoto = 'Tu foto';
  static const mirandoLaFoto = 'Mirando la foto…';
  static const noVeoLaFoto = 'No puedo ver esta foto.';

  // Elegir de dónde sale la foto.
  static const hazUnaFoto = 'Haz una foto';
  static const usarGaleria = 'De mis fotos';
  static const elegirOtraFoto = 'Elige otra foto';

  // Resultado.
  static const yaLoTengo = 'Ya lo tengo';
  static const noLoReconozco = 'No lo reconozco';
  static String creoQueEs(String animal) => 'Creo que es: $animal';
  static const puedesCambiarlo = 'Puedes cambiarlo.';
  static const nivelSeguro = 'Seguro';
  static const nivelCasiSeguro = 'Casi seguro';
  static const nivelNoLoSe = 'No lo sé';
  static const tambienPuedeSer = 'También puede ser';
  static const esEste = 'Es este';
  static const esOtro = 'Es otro';
  static const todosLosAnimales = 'Todos los animales';
  static String elegido(String animal) => 'Elegido: $animal';
  static const guardar = 'Guardar';
  static const guardando = 'Guardando…';
  static const guardado = '¡Guardado!';
  static String yaTienes(String animal) => '¡Ya tienes: $animal!';
  static const noHePodidoGuardarlo = 'No he podido guardarlo. Prueba otra vez.';

  // Avisos y errores de la pantalla de la foto.
  static const pruebaOtraVez = 'Prueba otra vez';
  static const abrirAjustes = 'Abrir Ajustes';
  static const soloEnMovil = 'Solo funciono en móvil y tablet.';
  static const noHePodidoEmpezar = 'No he podido empezar. Prueba otra vez.';
  static const noHasElegidoFoto = 'No has elegido ninguna foto.';
  static const noHePodidoAbrirLaFoto = 'No he podido abrir la foto.';
  static const noHePodidoMirarLaFoto = 'No he podido mirar la foto.';
  static const dejameUsarLaCamara = 'Déjame usar la cámara.';
  static const dejameVerTusFotos = 'Déjame ver tus fotos.';

  // Colección.
  static const coleccionTitulo = 'Mi colección';
  static const verMisFotos = 'Ver mis fotos';
  static const tuProgreso = 'Tu progreso';
  static String tienesAnimales(int tuyos, int total) =>
      'Tienes $tuyos animales de $total';
  static String elUltimo(String animal) => 'El último: $animal';
  static const logroPrimeraFoto = 'Primera foto';
  static const logroCincoAnimales = 'Cinco animales';
  static const logroTodos = '¡Están todos!';
  static const filtroLosQueTengo = 'Los que tengo';
  static const filtroLosQueFaltan = 'Los que faltan';
  static String fotos(int cuantas) =>
      cuantas == 1 ? '1 foto' : '$cuantas fotos';
  static String animalConFotos(String animal, int cuantas) =>
      '$animal, ${fotos(cuantas)}';
  static const entraParaGuardar = 'Entra para guardar tus animales.';
  static const noEncuentroTuColeccion =
      'No encuentro tu colección. Prueba otra vez.';
  static const aquiNoHayNada = 'Aquí no hay nada.';
  static const coleccionVaciaTitulo = 'Tu colección te espera';
  static const hazTuPrimeraFoto = 'Haz tu primera foto.';

  // Cambiar o borrar una foto guardada.
  static const borrarFotoTitulo = '¿Borrar esta foto?';
  static const borrarFotoTexto = 'Se borrará de tu colección.';
  static const cancelar = 'Cancelar';
  static const borrar = 'Borrar';
  static const cambiar = 'Cambiar';
  static const cambiarOBorrar = 'Cambiar o borrar';
  static const cualEs = '¿Cuál es?';
  static const noHePodidoCambiarlo = 'No he podido cambiarlo. Prueba otra vez.';

  // Ficha de un animal.
  static const fichaFotos = 'Fotos';
  static const fichaUltimaVez = 'Última vez';
  static const fichaAunNo = 'Aún no';
  static String tusFotosDe(String animal) => 'Tus fotos de $animal';
  static const sinFotosDeEste = 'Todavía no tienes fotos suyas.';
  static const noEncuentroEsteAnimal =
      'No encuentro este animal. Prueba otra vez.';

  // Mis fotos.
  static const misFotosTitulo = 'Mis fotos';
  static const todaviaNoTienesFotos = 'Todavía no tienes fotos.';
  static const noEncuentroTusFotos = 'No encuentro tus fotos. Prueba otra vez.';
  static const fotoSinGuardar = 'Sin guardar';
  static String fechaDeLaFoto(DateTime fecha) =>
      'El ${_dosCifras(fecha.day)}/${_dosCifras(fecha.month)}/${fecha.year}';

  static String _dosCifras(int valor) => valor.toString().padLeft(2, '0');

  /// Palabras de adulto que no pueden aparecer en una pantalla del niño.
  static const palabrasProhibidas = <String>[
    'predicción',
    'predicciones',
    'clasificación',
    'clasificar',
    'identificación',
    'identificaciones',
    'identificar',
    'confianza',
    'fiabilidad',
    'especie',
    'especies',
    'catálogo',
    'modelo',
    'dispositivo',
    'permiso',
    'permisos',
    'firestore',
    'analítica',
    'háptica',
    'sesión',
  ];

  /// Todas las frases que lee el niño, para la prueba de tono.
  ///
  /// Al añadir un texto arriba hay que añadirlo también aquí; las funciones
  /// entran con un valor de ejemplo.
  static final List<String> revisables = List.unmodifiable(<String>[
    marca,
    navegacionInicio,
    navegacionColeccion,
    navegacionAdultos,
    bienvenidaPasoGaleria,
    bienvenidaPasoColeccion,
    bienvenidaBoton,
    saludoSinNombre,
    saludo('Ana'),
    buscaUnAnimal,
    consejosTitulo,
    consejoUnAnimal,
    consejoLuz,
    consejoCerca,
    conozcoAnimales(28),
    dibujoDeAnimales,
    tuFoto,
    mirandoLaFoto,
    noVeoLaFoto,
    hazUnaFoto,
    usarGaleria,
    elegirOtraFoto,
    yaLoTengo,
    noLoReconozco,
    creoQueEs('Vaca'),
    puedesCambiarlo,
    nivelSeguro,
    nivelCasiSeguro,
    nivelNoLoSe,
    tambienPuedeSer,
    esEste,
    esOtro,
    todosLosAnimales,
    elegido('Vaca'),
    guardar,
    guardando,
    guardado,
    yaTienes('Vaca'),
    noHePodidoGuardarlo,
    pruebaOtraVez,
    abrirAjustes,
    soloEnMovil,
    noHePodidoEmpezar,
    noHasElegidoFoto,
    noHePodidoAbrirLaFoto,
    noHePodidoMirarLaFoto,
    dejameUsarLaCamara,
    dejameVerTusFotos,
    coleccionTitulo,
    verMisFotos,
    tuProgreso,
    tienesAnimales(3, 28),
    elUltimo('Vaca'),
    logroPrimeraFoto,
    logroCincoAnimales,
    logroTodos,
    filtroLosQueTengo,
    filtroLosQueFaltan,
    fotos(1),
    fotos(4),
    animalConFotos('Vaca', 2),
    entraParaGuardar,
    noEncuentroTuColeccion,
    aquiNoHayNada,
    coleccionVaciaTitulo,
    hazTuPrimeraFoto,
    borrarFotoTitulo,
    borrarFotoTexto,
    cancelar,
    borrar,
    cambiar,
    cambiarOBorrar,
    cualEs,
    noHePodidoCambiarlo,
    fichaFotos,
    fichaUltimaVez,
    fichaAunNo,
    tusFotosDe('Vaca'),
    sinFotosDeEste,
    noEncuentroEsteAnimal,
    misFotosTitulo,
    todaviaNoTienesFotos,
    noEncuentroTusFotos,
    fotoSinGuardar,
    fechaDeLaFoto(DateTime(2026, 8, 12)),
  ]);
}

abstract final class TextosAdulto {
  // Acceso.
  static const marca = 'La granja de Michi';
  static const marcaDescripcion =
      'Descubre animales con una foto y crea tu propia colección.';
  static const marcaSemantica =
      'La granja de Michi. Identifica animales y completa tu colección.';
  static const accesoTitulo = 'Bienvenido de nuevo';
  static const accesoSubtitulo = 'Identifica animales y continúa tu colección.';
  static const accesoBoton = 'Iniciar sesión';
  static const registroTitulo = 'Crea tu cuenta';
  static const registroSubtitulo =
      'Guarda tus descubrimientos y sigue completando tu colección.';
  static const registroBoton = 'Crear cuenta';
  static const irARegistro = 'Crear una cuenta';
  static const irAAcceso = 'Ya tengo una cuenta';
  static const correo = 'Correo electrónico';
  static const contrasena = 'Contraseña';
  static const mostrarContrasena = 'Mostrar contraseña';
  static const ocultarContrasena = 'Ocultar contraseña';
  static const olvideContrasena = 'He olvidado mi contraseña';
  static const recuperarTitulo = 'Recuperar contraseña';
  static const recuperarBoton = 'Enviar enlace';
  static String recuperacionEnviada(String correo) =>
      'Hemos enviado un enlace de recuperación a $correo.';
  static const cuentaCreadaTitulo = 'Cuenta creada';
  static const cuentaCreadaTexto =
      'Tu colección se guardará con esta cuenta cuando confirmes tus '
      'identificaciones.';
  static const continuar = 'Continuar';
  static const invitadoTitulo = '¿Quieres probar primero?';
  static const invitadoTexto =
      'Como invitado no guardaremos tu correo ni tus descubrimientos en una '
      'colección.';
  static const invitadoBoton = 'Continuar como invitado';
  static const correoInvalido = 'Escribe un correo válido.';
  static const contrasenaCorta =
      'La contraseña debe tener al menos 6 '
      'caracteres.';
  static const sesionNoComprobada =
      'No se ha podido comprobar la sesión. Vuelve a abrir la aplicación.';
  static const errorArranque =
      'No se pudo iniciar la aplicación. Comprueba la conexión e inténtalo de '
      'nuevo.';
  static const errorSinSesion = 'No hay una sesión activa.';
  static const errorContrasenaNecesaria =
      'Es necesaria la contraseña para eliminar la cuenta.';

  // Errores de autenticación.
  static const errorCorreoInvalido = 'El correo electrónico no es válido.';
  static const errorCredenciales =
      'El correo o la contraseña no son correctos.';
  static const errorCorreoEnUso = 'Ya existe una cuenta con ese correo.';
  static const errorContrasenaDebil =
      'La contraseña debe tener al menos 6 caracteres.';
  static const errorSinConexion =
      'No hay conexión a internet. Comprueba tu red y reintenta.';
  static const errorDemasiadosIntentos =
      'Has hecho demasiados intentos. Espera unos minutos y vuelve a probar.';
  static const errorMetodoNoPermitido =
      'Este método de acceso no está habilitado.';
  static const errorAutenticacion =
      'No se ha podido autenticar. Inténtalo de nuevo.';
  static const errorGuardarCuenta =
      'No se ha podido guardar la cuenta. Inténtalo de nuevo.';
  static const errorInesperado =
      'Ha ocurrido un error inesperado. Inténtalo de nuevo.';
  static const errorInvitado =
      'No se ha podido iniciar como invitado. Inténtalo de nuevo.';
  static const errorRecuperacion =
      'No se ha podido enviar el correo de recuperación. Inténtalo de nuevo.';

  // Perfil y ajustes.
  static const perfilTitulo = 'Perfil y ajustes';
  static const cuentaInvitado = 'Invitado';
  static const cuentaUsuario = 'Usuario';
  static const cuentaInvitadoTexto =
      'Tus descubrimientos no se guardan en una colección.';
  static const cuentaTexto = 'Tu colección está asociada a esta cuenta.';
  static const aparienciaTitulo = 'Apariencia y respuesta';
  static const tema = 'Tema';
  static const temaTexto = 'Elige claro, oscuro o el del sistema.';
  static const temaSistema = 'Sistema';
  static const temaClaro = 'Claro';
  static const temaOscuro = 'Oscuro';
  static const hapticaTitulo = 'Respuesta háptica';
  static const hapticaTexto =
      'Vibrar brevemente al confirmar acciones compatibles.';
  static const permisosTitulo = 'Permisos';
  static const permisoCamara = 'Cámara';
  static const permisoFotos = 'Fotos';
  static const permisoConcedido = 'Permitido';
  static const permisoLimitado = 'Acceso limitado';
  static const permisoNoDisponible = 'No disponible en web';
  static const permisoBloqueado = 'Bloqueado en Ajustes';
  static const permisoRestringido = 'Restringido por el dispositivo';
  static const permisoDenegado = 'No concedido';
  static String permisoSemantica(String permiso, String estado) =>
      '$permiso: $estado';
  static const permisosError =
      'No se ha podido comprobar el estado de los permisos.';
  static const abrirAjustes = 'Abrir Ajustes';
  static const ajustesNoAbiertos =
      'No se han podido abrir los Ajustes del dispositivo.';
  static const reintentar = 'Reintentar';

  // Privacidad y modelo.
  static const privacidadTitulo = 'Privacidad';
  static const privacidadResumen = 'Tus fotos no salen del dispositivo.';
  static const privacidadDetalle =
      'La clasificación se realiza localmente. Si usas una cuenta, Firestore '
      'guarda solo tu correo, la colección de especies, las fechas de '
      'identificación y el historial; no guarda las imágenes.';
  static const privacidadBorrado =
      'La app no incorpora analítica. Puedes eliminar permanentemente tu '
      'cuenta y colección desde esta pantalla.';
  static const modeloTitulo = 'Modelo de identificación';
  static String modeloVersion(String version) => 'Versión: $version';
  static String modeloClases(String clases) => 'Clases compatibles: $clases.';

  // Cerrar sesión y borrado de cuenta.
  static const cerrarSesion = 'Cerrar sesión';
  static const cerrandoSesion = 'Cerrando sesión…';
  static const errorCerrarSesion =
      'No se ha podido cerrar sesión. Inténtalo de nuevo.';
  static const eliminarCuenta = 'Eliminar cuenta y colección';
  static const eliminandoCuenta = 'Eliminando cuenta…';
  static const eliminarCuentaTitulo = '¿Eliminar cuenta?';
  static const eliminarCuentaTexto =
      'Esta acción elimina permanentemente tu cuenta y toda tu colección. No '
      'se puede deshacer.';
  static const eliminarCuentaContrasena = 'Contraseña para confirmar';
  static const eliminarCuentaCasilla =
      'Entiendo que no podré recuperar estos datos.';
  static const eliminarCuentaBoton = 'Eliminar permanentemente';
  static const cancelar = 'Cancelar';
  static const errorEliminarCuenta =
      'No se ha podido eliminar la cuenta y la colección. Inténtalo de nuevo.';
  static const errorContrasenaIncorrecta =
      'La contraseña no es correcta. Vuelve a intentarlo.';
  static const errorEsperaUnosMinutos =
      'Hay demasiados intentos. Espera unos minutos antes de volver a '
      'intentarlo.';
  static const errorCompruebaInternet =
      'No hay conexión. Comprueba internet y vuelve a intentarlo.';
  static const errorVuelveAIniciarSesion =
      'Vuelve a iniciar sesión antes de eliminar la cuenta.';
  static const errorIdentidad =
      'No se ha podido verificar tu identidad. Vuelve a intentarlo.';

  // Ajustes guardados en el dispositivo.
  static const errorCargarAjustes =
      'No se han podido cargar los ajustes. Se usarán los valores '
      'predeterminados.';
  static const errorGuardarTema =
      'No se ha podido guardar el tema. Inténtalo de nuevo.';
  static const errorGuardarHaptica =
      'No se ha podido guardar la respuesta háptica. Inténtalo de nuevo.';
}
