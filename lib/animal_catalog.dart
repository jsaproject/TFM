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

const animalCatalog = <Animal>[
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

final animalByName = <String, Animal>{
  for (final animal in animalCatalog) animal.name: animal,
};

/// Nombres usados antes de agrupar las clases de ImageNet.
///
/// Las colecciones guardadas en Firestore desde 2021 usan estas claves. Se
/// traducen al leer, sin reescribir los documentos: el dato del usuario se
/// conserva y sigue contando para su colección.
const legacyAnimalNames = <String, String>{
  'Gallina': 'Ave de corral',
  'Vaca': 'Bovino',
  'Oveja': 'Ovino y caprino',
  'Araña': 'Araña y escorpión',
  'Ardilla': 'Roedor',
};

/// Traduce un nombre guardado al grupo actual, o lo deja igual si ya lo es.
String resolveAnimalName(String stored) => legacyAnimalNames[stored] ?? stored;
