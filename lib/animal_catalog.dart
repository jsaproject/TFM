import 'package:flutter/material.dart';

/// Fuente única de los datos que se muestran en la colección.
class Animal {
  const Animal({
    required this.name,
    required this.description,
    required this.imageAsset,
    required this.icon,
  });

  final String name;
  final String description;
  final String imageAsset;
  final IconData icon;
}

const animalCatalog = <Animal>[
  Animal(
    name: 'Perro',
    description: 'Un compañero fiel y juguetón.',
    imageAsset: 'assets/perro.jpg',
    icon: Icons.pets,
  ),
  Animal(
    name: 'Caballo',
    description: 'Rápido, fuerte y elegante.',
    imageAsset: 'assets/caballo.jpg',
    icon: Icons.pets,
  ),
  Animal(
    name: 'Elefante',
    description: 'El mamífero terrestre más grande.',
    imageAsset: 'assets/elefante.jpg',
    icon: Icons.pets,
  ),
  Animal(
    name: 'Mariposa',
    description: 'Un insecto de alas llenas de color.',
    imageAsset: 'assets/mariposa.jpg',
    icon: Icons.flutter_dash,
  ),
  Animal(
    name: 'Gallina',
    description: 'Un ave habitual de la granja.',
    imageAsset: 'assets/gallina.jpg',
    icon: Icons.egg_alt,
  ),
  Animal(
    name: 'Gato',
    description: 'Curioso, ágil e independiente.',
    imageAsset: 'assets/gato.jpg',
    icon: Icons.pets,
  ),
  Animal(
    name: 'Vaca',
    description: 'Una tranquila habitante de la granja.',
    imageAsset: 'assets/vaca.jpg',
    icon: Icons.agriculture,
  ),
  Animal(
    name: 'Oveja',
    description: 'Su lana la protege del frío.',
    imageAsset: 'assets/oveja.jpg',
    icon: Icons.pets,
  ),
  Animal(
    name: 'Araña',
    description: 'Una experta tejedora de telas.',
    imageAsset: 'assets/arana.jpg',
    icon: Icons.bug_report,
  ),
  Animal(
    name: 'Ardilla',
    description: 'Pequeña, veloz y recolectora.',
    imageAsset: 'assets/ardilla.jpg',
    icon: Icons.forest,
  ),
];

final animalByName = <String, Animal>{
  for (final animal in animalCatalog) animal.name: animal,
};
