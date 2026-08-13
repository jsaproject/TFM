import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/collection/presentation/animal_image.dart';
import 'package:animalspredictor/features/collection/presentation/animal_name.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:flutter/material.dart';

/// Ficha de un animal para elegirlo con el dedo: dibujo grande y nombre debajo.
///
/// Es la única forma de elegir un animal en toda la app. Sustituye a la lista
/// desplegable de la pantalla de la foto y al diálogo de nombres de la
/// colección, que un niño que no lee no podía usar.
class AnimalChoiceCard extends StatelessWidget {
  const AnimalChoiceCard({
    super.key,
    required this.animal,
    required this.selected,
    required this.onTap,
  });

  final Animal animal;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? TextosNino.elegido(animal.name) : animal.name,
      onTap: onTap,
      child: ExcludeSemantics(
        child: Card(
          color: selected ? colors.primaryContainer : null,
          shape: MichiTokens.animalCardShape.copyWith(
            side: BorderSide(
              color: selected ? colors.primary : colors.outlineVariant,
              width: selected
                  ? MichiTokens.selectionBorderWidth
                  : MichiTokens.cardBorderWidth,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimalPortrait(animal: animal),
                      if (selected)
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(MichiTokens.space8),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primary,
                              ),
                              child: Icon(
                                Icons.check,
                                size: MichiTokens.iconSizeSmall,
                                color: colors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MichiTokens.space8,
                    vertical: MichiTokens.space12,
                  ),
                  child: AnimalName(
                    name: animal.name,
                    style: Theme.of(context).textTheme.titleMedium,
                    color: selected ? colors.onPrimaryContainer : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rejilla con los 28 animales, precedida por lo que sugiere la foto.
class AnimalSelector extends StatelessWidget {
  const AnimalSelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.suggestions = const <String>[],
  });

  /// Nombre del animal marcado ahora mismo, si hay alguno.
  final String? selected;

  /// Sugerencias de la foto, la principal primero. Van arriba del todo para
  /// que el caso normal se resuelva con un solo toque.
  final List<String> suggestions;

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final sugeridos = animalsByName(suggestions);
    return CustomScrollView(
      slivers: [
        if (sugeridos.isNotEmpty) ...[
          _SectionTitle(title: TextosNino.tambienPuedeSer),
          _AnimalGrid(
            animals: sugeridos,
            selected: selected,
            onSelected: onSelected,
          ),
        ],
        _SectionTitle(title: TextosNino.todosLosAnimales),
        _AnimalGrid(
          animals: animalCatalog,
          selected: selected,
          onSelected: onSelected,
        ),
      ],
    );
  }
}

/// Traduce nombres guardados o sugeridos a animales del catálogo actual,
/// descartando los que ya no existen.
List<Animal> animalsByName(Iterable<String> names) => [
  for (final name in names) ?currentAnimalByName[resolveAnimalName(name)],
];

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: MichiTokens.space12),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}

class _AnimalGrid extends StatelessWidget {
  const _AnimalGrid({
    required this.animals,
    required this.selected,
    required this.onSelected,
  });

  final List<Animal> animals;
  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SliverGrid.builder(
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: MichiTokens.animalChoiceMaxWidth,
      mainAxisSpacing: MichiTokens.space12,
      crossAxisSpacing: MichiTokens.space12,
      mainAxisExtent: MichiTokens.animalChoiceExtent,
    ),
    itemCount: animals.length,
    itemBuilder: (context, index) {
      final animal = animals[index];
      return AnimalChoiceCard(
        animal: animal,
        selected: animal.name == selected,
        onTap: () => onSelected(animal.name),
      );
    },
  );
}

/// Abre el selector a pantalla casi completa y devuelve el animal elegido.
Future<String?> showAnimalSelector(
  BuildContext context, {
  String? selected,
  List<String> suggestions = const <String>[],
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (sheetContext) => FractionallySizedBox(
    heightFactor: MichiTokens.selectorSheetHeightFactor,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: MichiTokens.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TextosNino.cualEs,
            style: Theme.of(sheetContext).textTheme.headlineSmall,
          ),
          Expanded(
            child: AnimalSelector(
              selected: selected,
              suggestions: suggestions,
              onSelected: (animal) => Navigator.pop(sheetContext, animal),
            ),
          ),
        ],
      ),
    ),
  ),
);
