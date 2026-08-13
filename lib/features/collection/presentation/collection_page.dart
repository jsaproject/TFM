import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/collection/presentation/animal_detail_page.dart';
import 'package:animalspredictor/features/collection/presentation/animal_image.dart';
import 'package:animalspredictor/features/collection/presentation/collection_history_page.dart';
import 'package:animalspredictor/features/collection/presentation/prediction_edit_action.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:animalspredictor/services/collection_repository.dart';
import 'package:flutter/material.dart';

enum CollectionFilter { discovered, pending, recent, amount }

class CollectionPage extends StatefulWidget {
  const CollectionPage({
    super.key,
    required this.userId,
    required this.isAnonymous,
    required this.repository,
    required this.onStartIdentifying,
  });

  final String userId;
  final bool isAnonymous;
  final CollectionRepository repository;
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
          title: const Text('¿Borrar identificación?'),
          content: const Text(
            'Se eliminará del historial y se actualizará el contador de la colección.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Borrar'),
            ),
          ],
        ),
      );
      if (!mounted || shouldDelete != true) return;
      await _updatePrediction(prediction, null);
      return;
    }

    final correctedAnimal = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Corregir animal'),
        children: animalCatalog
            .map(
              (animal) => SimpleDialogOption(
                onPressed: () => Navigator.pop(dialogContext, animal.name),
                child: Text(animal.name),
              ),
            )
            .toList(growable: false),
      ),
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
        const SnackBar(
          content: Text(
            'No se ha podido actualizar la identificación. Comprueba tu conexión e inténtalo de nuevo.',
          ),
        ),
      );
    }
  }

  void _retry() => setState(() => _refreshKey++);

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
          onOpenAnimal: (animal) => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => AnimalDetailPage(
                animal: animal,
                repository: widget.repository,
                userId: widget.userId,
                onEdit: _editPrediction,
              ),
            ),
          ),
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
          title: const Text('Mi colección'),
          actions: [
            IconButton(
              tooltip: 'Ver historial',
              onPressed: onOpenHistory,
              icon: const Icon(Icons.history),
            ),
          ],
        ),
        SliverPadding(
          padding: MichiTokens.pagePadding,
          sliver: SliverToBoxAdapter(
            child: _CollectionHeader(collection: collection),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: MichiTokens.space24),
          sliver: SliverToBoxAdapter(
            child: _CollectionFilters(
              selected: filter,
              onChanged: onFilterChanged,
            ),
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
                    maxCrossAxisExtent: 260,
                    mainAxisSpacing: MichiTokens.space12,
                    crossAxisSpacing: MichiTokens.space12,
                    mainAxisExtent: 242,
                  ),
                  itemCount: animals.length,
                  itemBuilder: (context, index) {
                    final animal = animals[index];
                    return _AnimalTile(
                      animal: animal,
                      count: collection.counts[animal.name] ?? 0,
                      onTap: () => onOpenAnimal(animal),
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
  final animals = visibleCatalog
      .where((animal) {
        final count = collection.counts[animal.name] ?? 0;
        return switch (filter) {
          CollectionFilter.discovered => count > 0,
          CollectionFilter.pending => count == 0,
          _ => true,
        };
      })
      .toList(growable: false);
  if (filter == CollectionFilter.recent) {
    return animals..sort((left, right) {
      final rightDate = collection.lastIdentified[right.name] ?? DateTime(0);
      final leftDate = collection.lastIdentified[left.name] ?? DateTime(0);
      return rightDate.compareTo(leftDate);
    });
  }
  if (filter == CollectionFilter.amount) {
    return animals..sort((left, right) {
      final countComparison = (collection.counts[right.name] ?? 0).compareTo(
        collection.counts[left.name] ?? 0,
      );
      return countComparison != 0
          ? countComparison
          : left.name.compareTo(right.name);
    });
  }
  return animals;
}

class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({required this.collection});
  final UserCollection collection;

  @override
  Widget build(BuildContext context) {
    final achievements = <String>[
      if (collection.totalPhotos > 0) 'Primera foto',
      if (collection.discovered >= 5) 'Cinco especies',
      if (collection.discovered == animalCatalog.length) 'Colección completa',
    ];
    final latest = collection.lastDiscoveredAnimal;
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(MichiTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tu progreso', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: MichiTokens.space8),
            Text(
              '${collection.discovered} de ${animalCatalog.length} especies descubiertas',
            ),
            const SizedBox(height: MichiTokens.space8),
            LinearProgressIndicator(
              value: collection.discovered / animalCatalog.length,
              semanticsLabel: 'Progreso de la colección',
            ),
            if (latest != null) ...[
              const SizedBox(height: MichiTokens.space12),
              Text('Último descubrimiento: $latest'),
            ],
            if (achievements.isNotEmpty) ...[
              const SizedBox(height: MichiTokens.space12),
              Wrap(
                spacing: MichiTokens.space8,
                runSpacing: MichiTokens.space8,
                children: achievements
                    .map(
                      (achievement) => Chip(
                        avatar: const Icon(
                          Icons.emoji_events_outlined,
                          size: 18,
                        ),
                        label: Text(achievement),
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
        label: 'Descubiertos',
        filter: CollectionFilter.discovered,
        selected: selected,
        onChanged: onChanged,
      ),
      _FilterChip(
        label: 'Pendientes',
        filter: CollectionFilter.pending,
        selected: selected,
        onChanged: onChanged,
      ),
      _FilterChip(
        label: 'Recientes',
        filter: CollectionFilter.recent,
        selected: selected,
        onChanged: onChanged,
      ),
      _FilterChip(
        label: 'Cantidad',
        filter: CollectionFilter.amount,
        selected: selected,
        onChanged: onChanged,
      ),
    ],
  );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.filter,
    required this.selected,
    required this.onChanged,
  });
  final String label;
  final CollectionFilter filter;
  final CollectionFilter? selected;
  final ValueChanged<CollectionFilter?> onChanged;

  @override
  Widget build(BuildContext context) => FilterChip(
    label: Text(label),
    selected: selected == filter,
    onSelected: (isSelected) => onChanged(isSelected ? filter : null),
  );
}

class _AnimalTile extends StatelessWidget {
  const _AnimalTile({
    required this.animal,
    required this.count,
    required this.onTap,
  });
  final Animal animal;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${animal.name}, $count ${count == 1 ? 'foto' : 'fotos'}',
    onTap: onTap,
    child: ExcludeSemantics(
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: AnimalImage(animal: animal),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(MichiTokens.space12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animal.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text('$count ${count == 1 ? 'foto' : 'fotos'}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GuestCollection extends StatelessWidget {
  const _GuestCollection();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: MichiTokens.pagePadding,
      child: Text(
        'Inicia sesión con una cuenta para guardar y consultar tu colección.',
        textAlign: TextAlign.center,
      ),
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
          const Icon(Icons.cloud_off_outlined, size: 64),
          const SizedBox(height: MichiTokens.space16),
          Text(
            'No se ha podido cargar la colección. Comprueba tu conexión e inténtalo de nuevo.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MichiTokens.space16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
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
      _SkeletonBlock(height: 190),
      SizedBox(height: MichiTokens.space16),
      _SkeletonBlock(height: 40),
      SizedBox(height: MichiTokens.space16),
      _SkeletonBlock(height: 180),
      SizedBox(height: MichiTokens.space12),
      _SkeletonBlock(height: 180),
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
    child: Text(
      'No hay especies que coincidan con este filtro.',
      textAlign: TextAlign.center,
    ),
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
          const Icon(Icons.collections_bookmark_outlined, size: 64),
          const SizedBox(height: MichiTokens.space16),
          Text(
            'Tu colección está esperando',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: MichiTokens.space8),
          const Text(
            'Haz tu primera predicción y confirma el animal para añadirlo.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MichiTokens.space24),
          FilledButton.icon(
            onPressed: onStartIdentifying,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Identificar animal'),
          ),
        ],
      ),
    ),
  );
}
