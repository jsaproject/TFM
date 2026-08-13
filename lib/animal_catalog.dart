import 'package:flutter/material.dart';

/// Fuente única de los datos que se muestran en la colección.
///
/// Los nombres deben coincidir exactamente con las claves de
/// `assets/imagenet_animal_groups.json`: son la misma entidad vista desde el
/// modelo y desde la interfaz.
class Animal {
  const Animal({
    required this.name,
    required this.description,
    required this.icon,
    this.imageAsset,
  });

  final String name;
  final String description;
  final IconData icon;

  /// Ilustración del catálogo. Nula mientras el grupo no tenga una propia.
  final String? imageAsset;
}

/// Los 28 animales que reconoce el modelo actual y que forman el progreso.
///
/// Mientras no lleguen las ilustraciones, el icono es lo único que distingue a
/// un animal de otro para un niño que no lee, así que ninguno repite icono
/// dentro de esta lista (lo comprueba `test/animal_catalog_test.dart`). Son
/// iconos de Material, no dibujos: se eligen por la pista que dan (las orejas
/// del burro, la rueda del hámster, las rayas del tigre), no por parecido.
const animalCatalog = <Animal>[
  Animal(
    name: 'Vaca',
    description: 'Tranquila, curiosa y experta en pastar.',
    icon: Icons.agriculture,
    imageAsset: 'assets/vaca.jpg',
  ),
  Animal(
    name: 'Caballo',
    description: 'Rápido, fuerte y elegante.',
    icon: Icons.directions_run,
    imageAsset: 'assets/caballo.jpg',
  ),
  Animal(
    name: 'Cerdo',
    description: 'Listo, sociable y con un gran olfato.',
    icon: Icons.savings,
  ),
  Animal(
    name: 'Oveja',
    description: 'Su lana parece una nube calentita.',
    icon: Icons.cloud_outlined,
    imageAsset: 'assets/oveja.jpg',
  ),
  Animal(
    name: 'Cabra',
    description: 'Inquieta, ágil y amiga de las alturas.',
    icon: Icons.terrain,
  ),
  Animal(
    name: 'Burro',
    description: 'Paciente, resistente y de orejas larguísimas.',
    icon: Icons.hearing,
  ),
  Animal(
    name: 'Gallina',
    description: 'Picotea, cacarea y cuida de sus pollitos.',
    icon: Icons.egg_alt,
    imageAsset: 'assets/gallina.jpg',
  ),
  Animal(
    name: 'Pato',
    description: 'Nada, vuela y camina con mucho salero.',
    icon: Icons.waves,
  ),
  Animal(
    name: 'Perro',
    description: 'Compañero fiel, juguetón y cariñoso.',
    icon: Icons.pets,
    imageAsset: 'assets/perro.jpg',
  ),
  Animal(
    name: 'Gato',
    description: 'Curioso, suave y maestro de las siestas.',
    icon: Icons.bedtime,
    imageAsset: 'assets/gato.jpg',
  ),
  Animal(
    name: 'Conejo',
    description: 'Orejas largas, nariz inquieta y grandes saltos.',
    icon: Icons.cruelty_free,
  ),
  Animal(
    name: 'Hámster',
    description: 'Pequeño, redondito y siempre atareado.',
    icon: Icons.autorenew,
  ),
  Animal(
    name: 'Tortuga',
    description: 'Lleva su casa siempre encima.',
    icon: Icons.eco,
  ),
  Animal(
    name: 'Pez',
    description: 'Nada entre burbujas y colores.',
    icon: Icons.set_meal,
  ),
  Animal(
    name: 'Loro',
    description: 'Plumas brillantes y una voz muy divertida.',
    icon: Icons.flutter_dash,
  ),
  Animal(
    name: 'León',
    description: 'Una gran melena y un rugido impresionante.',
    icon: Icons.brightness_7,
  ),
  Animal(
    name: 'Tigre',
    description: 'Cada tigre tiene un dibujo de rayas único.',
    icon: Icons.line_weight,
  ),
  Animal(
    name: 'Elefante',
    description: 'Gigante amable con una trompa muy útil.',
    icon: Icons.shower,
    imageAsset: 'assets/elefante.jpg',
  ),
  Animal(
    name: 'Jirafa',
    description: 'Su largo cuello alcanza las hojas más altas.',
    icon: Icons.park_outlined,
  ),
  Animal(
    name: 'Cebra',
    description: 'Sus rayas no se repiten jamás.',
    icon: Icons.contrast,
  ),
  Animal(
    name: 'Mono',
    description: 'Manos hábiles y mirada muy curiosa.',
    icon: Icons.back_hand,
  ),
  Animal(
    name: 'Panda',
    description: 'Un oso blanco y negro al que le encanta el bambú.',
    icon: Icons.forest,
  ),
  Animal(
    name: 'Oso',
    description: 'Grande, fuerte y sorprendentemente buen nadador.',
    icon: Icons.hive,
  ),
  Animal(
    name: 'Hipopótamo',
    description: 'Pasa el día fresquito dentro del agua.',
    icon: Icons.pool,
  ),
  Animal(
    name: 'Rinoceronte',
    description: 'Piel gruesa, gran cuerno y pasos poderosos.',
    icon: Icons.change_history,
  ),
  Animal(
    name: 'Cocodrilo',
    description: 'Espera inmóvil bajo el agua.',
    icon: Icons.visibility,
  ),
  Animal(
    name: 'Pingüino',
    description: 'Parece llevar esmoquin y nada rapidísimo.',
    icon: Icons.ac_unit,
  ),
  Animal(
    name: 'Koala',
    description: 'Abraza los eucaliptos y duerme muchas horas.',
    icon: Icons.spa,
  ),
];

/// Grupos de versiones anteriores. Solo se muestran cuando una colección
/// existente contiene alguno; así se preservan los descubrimientos antiguos
/// sin mezclarlos con las 28 especies del modelo nuevo.
const legacyAnimalCatalog = <Animal>[
  Animal(
    name: 'Anfibio',
    description: 'Vive entre el agua y la tierra.',
    icon: Icons.water,
  ),
  Animal(
    name: 'Antílope',
    description: 'Corredor veloz de las praderas.',
    icon: Icons.terrain,
  ),
  Animal(
    name: 'Araña y escorpión',
    description: 'Ocho patas y mucha paciencia.',
    icon: Icons.bug_report,
    imageAsset: 'assets/arana.jpg',
  ),
  Animal(
    name: 'Ave acuática',
    description: 'Nada, vuela y anida junto al agua.',
    icon: Icons.waves,
  ),
  Animal(
    name: 'Ave de corral',
    description: 'Un ave habitual de la granja.',
    icon: Icons.egg_alt,
    imageAsset: 'assets/gallina.jpg',
  ),
  Animal(
    name: 'Ave pequeña',
    description: 'Pequeña, inquieta y cantarina.',
    icon: Icons.flutter_dash,
  ),
  Animal(
    name: 'Ave rapaz',
    description: 'Vista afilada y vuelo silencioso.',
    icon: Icons.air,
  ),
  Animal(
    name: 'Avestruz',
    description: 'El ave más grande, y no vuela.',
    icon: Icons.flutter_dash,
  ),
  Animal(
    name: 'Bovino',
    description: 'Una tranquila habitante de la granja.',
    icon: Icons.agriculture,
    imageAsset: 'assets/vaca.jpg',
  ),
  Animal(
    name: 'Caballo',
    description: 'Rápido, fuerte y elegante.',
    icon: Icons.pets,
    imageAsset: 'assets/caballo.jpg',
  ),
  Animal(
    name: 'Camello y llama',
    description: 'Aguanta lo que haga falta.',
    icon: Icons.terrain,
  ),
  Animal(
    name: 'Cebra',
    description: 'Sus rayas no se repiten jamás.',
    icon: Icons.pets,
  ),
  Animal(
    name: 'Cerdo',
    description: 'Listo, sociable y con buen olfato.',
    icon: Icons.savings,
  ),
  Animal(
    name: 'Cocodrilo',
    description: 'Espera inmóvil bajo el agua.',
    icon: Icons.water,
  ),
  Animal(
    name: 'Conejo y liebre',
    description: 'Orejas largas y salto rápido.',
    icon: Icons.cruelty_free,
  ),
  Animal(
    name: 'Crustáceo',
    description: 'Caparazón duro y pinzas firmes.',
    icon: Icons.set_meal,
  ),
  Animal(
    name: 'Elefante',
    description: 'El mamífero terrestre más grande.',
    icon: Icons.pets,
    imageAsset: 'assets/elefante.jpg',
  ),
  Animal(
    name: 'Escarabajo',
    description: 'Coraza brillante y andar tranquilo.',
    icon: Icons.bug_report,
  ),
  Animal(
    name: 'Felino salvaje',
    description: 'El sigilo hecho músculo.',
    icon: Icons.pets,
  ),
  Animal(
    name: 'Gato',
    description: 'Curioso, ágil e independiente.',
    icon: Icons.pets,
    imageAsset: 'assets/gato.jpg',
  ),
  Animal(
    name: 'Hipopótamo',
    description: 'Enorme y sorprendentemente rápido.',
    icon: Icons.water,
  ),
  Animal(
    name: 'Invertebrado marino',
    description: 'Vida sin huesos en el fondo del mar.',
    icon: Icons.waves,
  ),
  Animal(
    name: 'Lagarto',
    description: 'Toma el sol sobre las piedras.',
    icon: Icons.terrain,
  ),
  Animal(
    name: 'Lobo y zorro',
    description: 'El pariente salvaje del perro.',
    icon: Icons.forest,
  ),
  Animal(
    name: 'Loro',
    description: 'Colorido, ruidoso y muy listo.',
    icon: Icons.flutter_dash,
  ),
  Animal(
    name: 'Mamífero marino',
    description: 'Respira aire y vive en el mar.',
    icon: Icons.waves,
  ),
  Animal(
    name: 'Mariposa',
    description: 'Un insecto de alas llenas de color.',
    icon: Icons.flutter_dash,
    imageAsset: 'assets/mariposa.jpg',
  ),
  Animal(
    name: 'Marsupial',
    description: 'Cría a sus hijos en una bolsa.',
    icon: Icons.pets,
  ),
  Animal(
    name: 'Molusco',
    description: 'Cuerpo blando, a veces con concha.',
    icon: Icons.set_meal,
  ),
  Animal(
    name: 'Mustélido',
    description: 'Cuerpo alargado y mucha energía.',
    icon: Icons.pets,
  ),
  Animal(
    name: 'Oso',
    description: 'Grande, fuerte y goloso.',
    icon: Icons.pets,
  ),
  Animal(
    name: 'Otros insectos',
    description: 'Seis patas y un mundo por descubrir.',
    icon: Icons.hive,
  ),
  Animal(
    name: 'Otros mamíferos',
    description: 'No encaja en ningún grupo, y ahí está su gracia.',
    icon: Icons.pets,
  ),
  Animal(
    name: 'Ovino y caprino',
    description: 'Su lana la protege del frío.',
    icon: Icons.agriculture,
    imageAsset: 'assets/oveja.jpg',
  ),
  Animal(
    name: 'Perro',
    description: 'Un compañero fiel y juguetón.',
    icon: Icons.pets,
    imageAsset: 'assets/perro.jpg',
  ),
  Animal(
    name: 'Pez',
    description: 'Respira bajo el agua con branquias.',
    icon: Icons.set_meal,
  ),
  Animal(
    name: 'Pingüino',
    description: 'Nada mejor de lo que camina.',
    icon: Icons.ac_unit,
  ),
  Animal(
    name: 'Primate',
    description: 'Manos hábiles y mirada curiosa.',
    icon: Icons.pets,
  ),
  Animal(
    name: 'Roedor',
    description: 'Pequeño, veloz y recolector.',
    icon: Icons.forest,
    imageAsset: 'assets/ardilla.jpg',
  ),
  Animal(
    name: 'Serpiente',
    description: 'Se mueve sin patas y sin ruido.',
    icon: Icons.grass,
  ),
  Animal(
    name: 'Tiburón y raya',
    description: 'Esqueleto de cartílago, no de hueso.',
    icon: Icons.set_meal,
  ),
  Animal(
    name: 'Tortuga',
    description: 'Lleva su casa siempre encima.',
    icon: Icons.eco,
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
