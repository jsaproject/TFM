import 'package:animalspredictor/animal_catalog.dart';

abstract final class ModelInformation {
  static const version = 'TinyCLIP 39M INT8 · catálogo v1';

  static final classes = List<String>.unmodifiable(
    animalCatalog.map((animal) => animal.name),
  );

  static const limitations =
      'Funciona sin internet y está optimizado para un animal visible y bien '
      'iluminado. Si la imagen es ambigua o no pertenece al catálogo, la app '
      'pedirá que lo confirmes en lugar de asegurar un resultado.';
}
