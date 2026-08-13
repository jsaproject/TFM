/// Fuente única de los datos que se muestran en la colección.
///
/// Los nombres deben coincidir exactamente con las claves de
/// `assets/imagenet_animal_groups.json`: son la misma entidad vista desde el
/// modelo y desde la interfaz.
library;

/// Dónde vive un animal, visto por un niño.
///
/// Es lo que agrupa las medallas de "toda la granja", "todos los de casa" y
/// "todo el zoo" (ver `features/collection/domain/achievement.dart`).
enum AnimalHabitat { granja, casa, salvaje }

class Animal {
  const Animal({
    required this.name,
    required this.description,
    required this.emoji,
    this.habitat,
    this.imageAsset,
  });

  final String name;
  final String description;

  /// Retrato del animal mientras no hay ilustración propia.
  ///
  /// Sustituye a los iconos de Material que se usaban antes: una colmena para
  /// el oso o un triángulo para el rinoceronte no le dicen nada a un niño que
  /// no lee, y un dibujo del animal sí.
  final String emoji;

  /// Nulo solo en [legacyAnimalCatalog]: los grupos antiguos ya no cuentan
  /// para el progreso ni para las medallas.
  final AnimalHabitat? habitat;

  /// Fotografía del catálogo. Nula mientras el grupo no tenga una propia.
  final String? imageAsset;
}

/// Los animales del catálogo actual que viven en un sitio concreto.
List<Animal> animalsInHabitat(AnimalHabitat habitat) => [
  for (final animal in animalCatalog)
    if (animal.habitat == habitat) animal,
];

/// Los 28 animales que reconoce el modelo actual y que forman el progreso.
///
/// Mientras no lleguen las fotografías, el retrato es lo único que distingue a
/// un animal de otro para un niño que no lee, así que ninguno lo repite dentro
/// de esta lista (lo comprueba `test/animal_catalog_test.dart`).
const animalCatalog = <Animal>[
  Animal(
    name: 'Vaca',
    habitat: AnimalHabitat.granja,
    description: 'Tranquila, curiosa y experta en pastar.',
    emoji: '🐄',
    imageAsset: 'assets/vaca.jpg',
  ),
  Animal(
    name: 'Caballo',
    habitat: AnimalHabitat.granja,
    description: 'Rápido, fuerte y elegante.',
    emoji: '🐴',
    imageAsset: 'assets/caballo.jpg',
  ),
  Animal(
    name: 'Cerdo',
    habitat: AnimalHabitat.granja,
    description: 'Listo, sociable y con un gran olfato.',
    emoji: '🐖',
  ),
  Animal(
    name: 'Oveja',
    habitat: AnimalHabitat.granja,
    description: 'Su lana parece una nube calentita.',
    emoji: '🐑',
    imageAsset: 'assets/oveja.jpg',
  ),
  Animal(
    name: 'Cabra',
    habitat: AnimalHabitat.granja,
    description: 'Inquieta, ágil y amiga de las alturas.',
    emoji: '🐐',
  ),
  Animal(
    name: 'Burro',
    habitat: AnimalHabitat.granja,
    description: 'Paciente, resistente y de orejas larguísimas.',
    emoji: '🫏',
  ),
  Animal(
    name: 'Gallina',
    habitat: AnimalHabitat.granja,
    description: 'Picotea, cacarea y cuida de sus pollitos.',
    emoji: '🐔',
    imageAsset: 'assets/gallina.jpg',
  ),
  Animal(
    name: 'Pato',
    habitat: AnimalHabitat.granja,
    description: 'Nada, vuela y camina con mucho salero.',
    emoji: '🦆',
  ),
  Animal(
    name: 'Perro',
    habitat: AnimalHabitat.casa,
    description: 'Compañero fiel, juguetón y cariñoso.',
    emoji: '🐕',
    imageAsset: 'assets/perro.jpg',
  ),
  Animal(
    name: 'Gato',
    habitat: AnimalHabitat.casa,
    description: 'Curioso, suave y maestro de las siestas.',
    emoji: '🐈',
    imageAsset: 'assets/gato.jpg',
  ),
  Animal(
    name: 'Conejo',
    habitat: AnimalHabitat.casa,
    description: 'Orejas largas, nariz inquieta y grandes saltos.',
    emoji: '🐇',
  ),
  Animal(
    name: 'Hámster',
    habitat: AnimalHabitat.casa,
    description: 'Pequeño, redondito y siempre atareado.',
    emoji: '🐹',
  ),
  Animal(
    name: 'Tortuga',
    habitat: AnimalHabitat.casa,
    description: 'Lleva su casa siempre encima.',
    emoji: '🐢',
  ),
  Animal(
    name: 'Pez',
    habitat: AnimalHabitat.casa,
    description: 'Nada entre burbujas y colores.',
    emoji: '🐠',
  ),
  Animal(
    name: 'Loro',
    habitat: AnimalHabitat.casa,
    description: 'Plumas brillantes y una voz muy divertida.',
    emoji: '🦜',
  ),
  Animal(
    name: 'León',
    habitat: AnimalHabitat.salvaje,
    description: 'Una gran melena y un rugido impresionante.',
    emoji: '🦁',
  ),
  Animal(
    name: 'Tigre',
    habitat: AnimalHabitat.salvaje,
    description: 'Cada tigre tiene un dibujo de rayas único.',
    emoji: '🐅',
  ),
  Animal(
    name: 'Elefante',
    habitat: AnimalHabitat.salvaje,
    description: 'Gigante amable con una trompa muy útil.',
    emoji: '🐘',
    imageAsset: 'assets/elefante.jpg',
  ),
  Animal(
    name: 'Jirafa',
    habitat: AnimalHabitat.salvaje,
    description: 'Su largo cuello alcanza las hojas más altas.',
    emoji: '🦒',
  ),
  Animal(
    name: 'Cebra',
    habitat: AnimalHabitat.salvaje,
    description: 'Sus rayas no se repiten jamás.',
    emoji: '🦓',
  ),
  Animal(
    name: 'Mono',
    habitat: AnimalHabitat.salvaje,
    description: 'Manos hábiles y mirada muy curiosa.',
    emoji: '🐒',
  ),
  Animal(
    name: 'Panda',
    habitat: AnimalHabitat.salvaje,
    description: 'Un oso blanco y negro al que le encanta el bambú.',
    emoji: '🐼',
  ),
  Animal(
    name: 'Oso',
    habitat: AnimalHabitat.salvaje,
    description: 'Grande, fuerte y sorprendentemente buen nadador.',
    emoji: '🐻',
  ),
  Animal(
    name: 'Hipopótamo',
    habitat: AnimalHabitat.salvaje,
    description: 'Pasa el día fresquito dentro del agua.',
    emoji: '🦛',
  ),
  Animal(
    name: 'Rinoceronte',
    habitat: AnimalHabitat.salvaje,
    description: 'Piel gruesa, gran cuerno y pasos poderosos.',
    emoji: '🦏',
  ),
  Animal(
    name: 'Cocodrilo',
    habitat: AnimalHabitat.salvaje,
    description: 'Espera inmóvil bajo el agua.',
    emoji: '🐊',
  ),
  Animal(
    name: 'Pingüino',
    habitat: AnimalHabitat.salvaje,
    description: 'Parece llevar esmoquin y nada rapidísimo.',
    emoji: '🐧',
  ),
  Animal(
    name: 'Koala',
    habitat: AnimalHabitat.salvaje,
    description: 'Abraza los eucaliptos y duerme muchas horas.',
    emoji: '🐨',
  ),
];

/// Grupos de versiones anteriores. Solo se muestran cuando una colección
/// existente contiene alguno; así se preservan los descubrimientos antiguos
/// sin mezclarlos con las 28 especies del modelo nuevo.
const legacyAnimalCatalog = <Animal>[
  Animal(
    name: 'Anfibio',
    description: 'Vive entre el agua y la tierra.',
    emoji: '🐸',
  ),
  Animal(
    name: 'Antílope',
    description: 'Corredor veloz de las praderas.',
    emoji: '🦌',
  ),
  Animal(
    name: 'Araña y escorpión',
    description: 'Ocho patas y mucha paciencia.',
    emoji: '🕷️',
    imageAsset: 'assets/arana.jpg',
  ),
  Animal(
    name: 'Ave acuática',
    description: 'Nada, vuela y anida junto al agua.',
    emoji: '🦢',
  ),
  Animal(
    name: 'Ave de corral',
    description: 'Un ave habitual de la granja.',
    emoji: '🐔',
    imageAsset: 'assets/gallina.jpg',
  ),
  Animal(
    name: 'Ave pequeña',
    description: 'Pequeña, inquieta y cantarina.',
    emoji: '🐦',
  ),
  Animal(
    name: 'Ave rapaz',
    description: 'Vista afilada y vuelo silencioso.',
    emoji: '🦅',
  ),
  Animal(
    name: 'Avestruz',
    description: 'El ave más grande, y no vuela.',
    emoji: '🪶',
  ),
  Animal(
    name: 'Bovino',
    description: 'Una tranquila habitante de la granja.',
    emoji: '🐄',
    imageAsset: 'assets/vaca.jpg',
  ),
  Animal(
    name: 'Caballo',
    description: 'Rápido, fuerte y elegante.',
    emoji: '🐴',
    imageAsset: 'assets/caballo.jpg',
  ),
  Animal(
    name: 'Camello y llama',
    description: 'Aguanta lo que haga falta.',
    emoji: '🐪',
  ),
  Animal(
    name: 'Cebra',
    description: 'Sus rayas no se repiten jamás.',
    emoji: '🦓',
  ),
  Animal(
    name: 'Cerdo',
    description: 'Listo, sociable y con buen olfato.',
    emoji: '🐖',
  ),
  Animal(
    name: 'Cocodrilo',
    description: 'Espera inmóvil bajo el agua.',
    emoji: '🐊',
  ),
  Animal(
    name: 'Conejo y liebre',
    description: 'Orejas largas y salto rápido.',
    emoji: '🐇',
  ),
  Animal(
    name: 'Crustáceo',
    description: 'Caparazón duro y pinzas firmes.',
    emoji: '🦀',
  ),
  Animal(
    name: 'Elefante',
    description: 'El mamífero terrestre más grande.',
    emoji: '🐘',
    imageAsset: 'assets/elefante.jpg',
  ),
  Animal(
    name: 'Escarabajo',
    description: 'Coraza brillante y andar tranquilo.',
    emoji: '🪲',
  ),
  Animal(
    name: 'Felino salvaje',
    description: 'El sigilo hecho músculo.',
    emoji: '🐆',
  ),
  Animal(
    name: 'Gato',
    description: 'Curioso, ágil e independiente.',
    emoji: '🐈',
    imageAsset: 'assets/gato.jpg',
  ),
  Animal(
    name: 'Hipopótamo',
    description: 'Enorme y sorprendentemente rápido.',
    emoji: '🦛',
  ),
  Animal(
    name: 'Invertebrado marino',
    description: 'Vida sin huesos en el fondo del mar.',
    emoji: '🦑',
  ),
  Animal(
    name: 'Lagarto',
    description: 'Toma el sol sobre las piedras.',
    emoji: '🦎',
  ),
  Animal(
    name: 'Lobo y zorro',
    description: 'El pariente salvaje del perro.',
    emoji: '🐺',
  ),
  Animal(
    name: 'Loro',
    description: 'Colorido, ruidoso y muy listo.',
    emoji: '🦜',
  ),
  Animal(
    name: 'Mamífero marino',
    description: 'Respira aire y vive en el mar.',
    emoji: '🐬',
  ),
  Animal(
    name: 'Mariposa',
    description: 'Un insecto de alas llenas de color.',
    emoji: '🦋',
    imageAsset: 'assets/mariposa.jpg',
  ),
  Animal(
    name: 'Marsupial',
    description: 'Cría a sus hijos en una bolsa.',
    emoji: '🦘',
  ),
  Animal(
    name: 'Molusco',
    description: 'Cuerpo blando, a veces con concha.',
    emoji: '🐌',
  ),
  Animal(
    name: 'Mustélido',
    description: 'Cuerpo alargado y mucha energía.',
    emoji: '🦡',
  ),
  Animal(name: 'Oso', description: 'Grande, fuerte y goloso.', emoji: '🐻'),
  Animal(
    name: 'Otros insectos',
    description: 'Seis patas y un mundo por descubrir.',
    emoji: '🐜',
  ),
  Animal(
    name: 'Otros mamíferos',
    description: 'No encaja en ningún grupo, y ahí está su gracia.',
    emoji: '🐾',
  ),
  Animal(
    name: 'Ovino y caprino',
    description: 'Su lana la protege del frío.',
    emoji: '🐑',
    imageAsset: 'assets/oveja.jpg',
  ),
  Animal(
    name: 'Perro',
    description: 'Un compañero fiel y juguetón.',
    emoji: '🐕',
    imageAsset: 'assets/perro.jpg',
  ),
  Animal(
    name: 'Pez',
    description: 'Respira bajo el agua con branquias.',
    emoji: '🐟',
  ),
  Animal(
    name: 'Pingüino',
    description: 'Nada mejor de lo que camina.',
    emoji: '🐧',
  ),
  Animal(
    name: 'Primate',
    description: 'Manos hábiles y mirada curiosa.',
    emoji: '🐒',
  ),
  Animal(
    name: 'Roedor',
    description: 'Pequeño, veloz y recolector.',
    emoji: '🐿️',
    imageAsset: 'assets/ardilla.jpg',
  ),
  Animal(
    name: 'Serpiente',
    description: 'Se mueve sin patas y sin ruido.',
    emoji: '🐍',
  ),
  Animal(
    name: 'Tiburón y raya',
    description: 'Esqueleto de cartílago, no de hueso.',
    emoji: '🦈',
  ),
  Animal(
    name: 'Tortuga',
    description: 'Lleva su casa siempre encima.',
    emoji: '🐢',
  ),
];

final currentAnimalByName = <String, Animal>{
  for (final animal in animalCatalog) animal.name: animal,
};

final animalByName = <String, Animal>{
  for (final animal in legacyAnimalCatalog) animal.name: animal,
  ...currentAnimalByName,
};

/// Nombres usados antes de agrupar las clases de ImageNet.
///
/// Las colecciones guardadas en Firestore desde 2021 usan estas claves. Se
/// traducen al leer, sin reescribir los documentos: el dato del usuario se
/// conserva y sigue contando para su colección.
const legacyAnimalNames = <String, String>{
  'Bovino': 'Vaca',
  'Ave de corral': 'Gallina',
  'Conejo y liebre': 'Conejo',
  'Primate': 'Mono',
  'Araña': 'Araña y escorpión',
  'Ardilla': 'Roedor',
};

/// Traduce un nombre guardado al grupo actual, o lo deja igual si ya lo es.
String resolveAnimalName(String stored) => legacyAnimalNames[stored] ?? stored;
