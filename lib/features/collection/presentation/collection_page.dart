import 'dart:async';

import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_animations.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/collection/presentation/animal_detail_page.dart';
import 'package:animalspredictor/features/collection/presentation/animal_image.dart';
import 'package:animalspredictor/features/collection/presentation/animal_name.dart';
import 'package:animalspredictor/features/collection/presentation/animal_selector.dart';
import 'package:animalspredictor/features/collection/presentation/collection_history_page.dart';
import 'package:animalspredictor/features/collection/presentation/collection_progress.dart';
import 'package:animalspredictor/features/collection/presentation/prediction_edit_action.dart';
import 'package:animalspredictor/features/profile/data/settings_repository.dart';
import 'package:animalspredictor/l10n/textos.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:animalspredictor/services/collection_repository.dart';
import 'package:animalspredictor/services/sound_service.dart';
import 'package:flutter/material.dart';

/// Solo dos filtros: para un niño, "los que tengo" y "los que faltan" son las
/// dos preguntas que se hace. Ordenar por fecha o por cantidad era ruido.
enum CollectionFilter { discovered, pending }

class CollectionPage extends StatefulWidget {
  const CollectionPage({
    super.key,
    required this.userId,
    required this.isAnonymous,
    required this.repository,
    required this.settings,
    required this.onStartIdentifying,
  });

  final String userId;
  final bool isAnonymous;
  final CollectionRepository repository;
  final SettingsController settings;
  final VoidCallback onStartIdentifying;

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  CollectionFilter? _filter;
  var _refreshKey = 0;

  Future<void> _editPrediction(
    CollectionPrediction prediction,
    PredictionEditAction action,
  ) async {
    if (action == PredictionEditAction.delete) {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text(TextosNino.borrarFotoTitulo),
          content: const Text(TextosNino.borrarFotoTexto),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text(TextosNino.cancelar),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(TextosNino.borrar),
            ),
          ],
        ),
      );
      if (!mounted || shouldDelete != true) return;
      await _updatePrediction(prediction, null);
      return;
    }

    final correctedAnimal = await showAnimalSelector(
      context,
      selected: prediction.animal,
    );
    if (!mounted ||
        correctedAnimal == null ||
        correctedAnimal == prediction.animal) {
      return;
    }
    await _updatePrediction(prediction, correctedAnimal);
  }

  Future<void> _updatePrediction(
    CollectionPrediction prediction,
    String? animal,
  ) async {
    try {
      await widget.repository.updatePrediction(
        widget.userId,
        prediction,
        animal,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(TextosNino.noHePodidoCambiarlo)),
      );
    }
  }

  void _retry() => setState(() => _refreshKey++);

  void _openAnimal(Animal animal) {
    final sound = AppSound.forAnimal(animal.name);
    if (sound != null) unawaited(widget.settings.playSound(sound));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AnimalDetailPage(
          animal: animal,
          repository: widget.repository,
          userId: widget.userId,
          onEdit: _editPrediction,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAnonymous) return const _GuestCollection();
    return StreamBuilder<UserCollection>(
      key: ValueKey(_refreshKey),
      stream: widget.repository.watch(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _CollectionError(onRetry: _retry);
        if (!snapshot.hasData) return const _CollectionSkeleton();
        final collection = snapshot.data!;
        if (collection.isEmpty) {
          return _EmptyCollection(
            onStartIdentifying: widget.onStartIdentifying,
          );
        }
        return _CollectionContent(
          collection: collection,
          filter: _filter,
          onFilterChanged: (filter) => setState(() => _filter = filter),
          onOpenAnimal: _openAnimal,
          onOpenHistory: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CollectionHistoryPage(
                repository: widget.repository,
                userId: widget.userId,
                onEdit: _editPrediction,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CollectionContent extends StatelessWidget {
  const _CollectionContent({
    required this.collection,
    required this.filter,
    required this.onFilterChanged,
    required this.onOpenAnimal,
    required this.onOpenHistory,
  });

  final UserCollection collection;
  final CollectionFilter? filter;
  final ValueChanged<CollectionFilter?> onFilterChanged;
  final ValueChanged<Animal> onOpenAnimal;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final animals = _filteredAnimals(collection, filter);
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: const Text(TextosNino.coleccionTitulo),
          actions: [
            IconButton(
              tooltip: TextosNino.verMisFotos,
              onPressed: onOpenHistory,
              icon: const Icon(Icons.history),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            MichiTokens.space24,
            MichiTokens.space8,
            MichiTokens.space24,
            MichiTokens.space20,
          ),
          sliver: SliverToBoxAdapter(
            child: CollectionProgress(
              collection: collection,
              detailed: true,
            ).entrance(),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            MichiTokens.space24,
            0,
            MichiTokens.space24,
            MichiTokens.space20,
          ),
          sliver: SliverToBoxAdapter(
            child: CollectionMedals(collection: collection).entrance(step: 1),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: MichiTokens.space24),
          sliver: SliverToBoxAdapter(
            child: _CollectionFilters(
              selected: filter,
              onChanged: onFilterChanged,
            ).entrance(step: 2),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            MichiTokens.space24,
            MichiTokens.space16,
            MichiTokens.space24,
            MichiTokens.space24,
          ),
          sliver: animals.isEmpty
              ? const SliverToBoxAdapter(child: _NoFilteredAnimals())
              : SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent:
                        MichiTokens.collectionGridMaxCrossAxisExtent,
                    mainAxisSpacing: MichiTokens.space12,
                    crossAxisSpacing: MichiTokens.space12,
                    mainAxisExtent: MichiTokens.collectionGridMainAxisExtent,
                  ),
                  itemCount: animals.length,
                  itemBuilder: (context, index) {
                    final animal = animals[index];
                    return _AnimalTile(
                      animal: animal,
                      count: collection.counts[animal.name] ?? 0,
                      onTap: () => onOpenAnimal(animal),
                      // Las primeras fichas entran escalonadas; a partir de
                      // ahí ya está el ojo puesto y no hace falta.
                      entranceStep: index < 6 ? index : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

List<Animal> _filteredAnimals(
  UserCollection collection,
  CollectionFilter? filter,
) {
  final visibleCatalog = <Animal>[
    ...animalCatalog,
    for (final animal in legacyAnimalCatalog)
      if (!currentAnimalByName.containsKey(animal.name) &&
          (collection.counts[animal.name] ?? 0) > 0)
        animal,
  ];
  return visibleCatalog
      .where((animal) {
        final count = collection.counts[animal.name] ?? 0;
        return switch (filter) {
          CollectionFilter.discovered => count > 0,
          CollectionFilter.pending => count == 0,
          null => true,
        };
      })
      .toList(growable: false);
}

class _CollectionFilters extends StatelessWidget {
  const _CollectionFilters({required this.selected, required this.onChanged});
  final CollectionFilter? selected;
  final ValueChanged<CollectionFilter?> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: MichiTokens.space8,
    runSpacing: MichiTokens.space8,
    children: [
      _FilterChip(
        label: TextosNino.filtroLosQueTengo,
        icon: Icons.check_circle_outline,
        filter: CollectionFilter.discovered,
        selected: selected,
        onChanged: onChanged,
      ),
      _FilterChip(
        label: TextosNino.filtroLosQueFaltan,
        icon: Icons.help_outline,
        filter: CollectionFilter.pending,
        selected: selected,
        onChanged: onChanged,
      ),
    ],
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.icon,
    required this.filter,
    required this.selected,
    required this.onChanged,
  });
  final String label;
  final IconData icon;
  final CollectionFilter filter;
  final CollectionFilter? selected;
  final ValueChanged<CollectionFilter?> onChanged;

  // Los dos filtros caben en una línea; con la letra de las pastillas del
  // resto de la app se partían en dos filas y empujaban la cuadrícula fuera de
  // la pantalla. El alto sigue siendo el de un dedo pequeño.
  @override
  Widget build(BuildContext context) => FilterChip(
    avatar: Icon(icon, size: MichiTokens.iconSizeSmall),
    label: Text(label),
    labelStyle: Theme.of(context).textTheme.labelMedium,
    padding: const EdgeInsets.symmetric(
      horizontal: MichiTokens.space12,
      vertical: MichiTokens.chipCompactVerticalPadding,
    ),
    selected: selected == filter,
    onSelected: (isSelected) => onChanged(isSelected ? filter : null),
  );
}

class _AnimalTile extends StatelessWidget {
  const _AnimalTile({
    required this.animal,
    required this.count,
    required this.onTap,
    this.entranceStep,
  });
  final Animal animal;
  final int count;
  final VoidCallback onTap;

  /// Puesto en la entrada escalonada. Nulo si la ficha aparece sin animación.
  final int? entranceStep;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final owned = count > 0;
    final tile = Semantics(
      button: true,
      label: TextosNino.animalConFotos(animal.name, count),
      onTap: onTap,
      child: ExcludeSemantics(
        child: Card(
          shape: MichiTokens.animalCardShape.copyWith(
            side: BorderSide(
              color: owned ? colors.secondary : colors.outlineVariant,
              width: MichiTokens.cardBorderWidth,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    // Los que faltan se ven apagados: la diferencia entre lo
                    // conseguido y lo pendiente se nota sin leer nada.
                    child: Opacity(
                      opacity: owned ? 1 : 0.5,
                      child: AnimalPortrait(animal: animal),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    MichiTokens.space12,
                    MichiTokens.space12,
                    MichiTokens.space12,
                    MichiTokens.space12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimalName(
                        name: animal.name,
                        textAlign: TextAlign.start,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: MichiTokens.space8),
                      AnimalCountBadge(
                        label: TextosNino.fotos(count),
                        owned: owned,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final step = entranceStep;
    return step == null ? tile : tile.entrance(step: step);
  }
}

class _GuestCollection extends StatelessWidget {
  const _GuestCollection();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: MichiTokens.pagePadding,
      child: Text(TextosNino.entraParaGuardar, textAlign: TextAlign.center),
    ),
  );
}

class _CollectionError extends StatelessWidget {
  const _CollectionError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: MichiTokens.pagePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: MichiTokens.iconSizeLarge),
          const SizedBox(height: MichiTokens.space16),
          const Text(
            TextosNino.noEncuentroTuColeccion,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MichiTokens.space16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text(TextosNino.pruebaOtraVez),
          ),
        ],
      ),
    ),
  );
}

class _CollectionSkeleton extends StatelessWidget {
  const _CollectionSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: MichiTokens.pagePadding,
    children: const [
      _SkeletonBlock(height: MichiTokens.collectionHeaderSkeletonHeight),
      SizedBox(height: MichiTokens.space16),
      _SkeletonBlock(height: MichiTokens.collectionFilterSkeletonHeight),
      SizedBox(height: MichiTokens.space16),
      _SkeletonBlock(height: MichiTokens.collectionCardSkeletonHeight),
      SizedBox(height: MichiTokens.space12),
      _SkeletonBlock(height: MichiTokens.collectionCardSkeletonHeight),
    ],
  );
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: const BorderRadius.all(MichiTokens.radiusMedium),
    ),
    child: SizedBox(height: height),
  );
}

class _NoFilteredAnimals extends StatelessWidget {
  const _NoFilteredAnimals();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: MichiTokens.space32),
    child: Text(TextosNino.aquiNoHayNada, textAlign: TextAlign.center),
  );
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection({required this.onStartIdentifying});
  final VoidCallback onStartIdentifying;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: MichiTokens.pagePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.collections_bookmark_outlined,
            size: MichiTokens.iconSizeLarge,
          ),
          const SizedBox(height: MichiTokens.space16),
          Text(
            TextosNino.coleccionVaciaTitulo,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: MichiTokens.space8),
          const Text(TextosNino.hazTuPrimeraFoto, textAlign: TextAlign.center),
          const SizedBox(height: MichiTokens.space24),
          FilledButton.icon(
            onPressed: onStartIdentifying,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text(TextosNino.hazUnaFoto),
          ),
        ],
      ),
    ),
  );
}
