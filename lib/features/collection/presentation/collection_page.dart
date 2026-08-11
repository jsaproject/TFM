import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:animalspredictor/services/collection_repository.dart';
import 'package:flutter/material.dart';

enum CollectionOrder { name, amount, latest }

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
  CollectionOrder _order = CollectionOrder.name;

  Future<void> _editPrediction(
    CollectionPrediction prediction,
    String action,
  ) async {
    if (action == 'delete') {
      final shouldDelete = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Borrar identificación?'),
          content: const Text(
            'Se eliminará del historial y se actualizará el contador de la colección.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Borrar'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (shouldDelete != true) return;
      await _updatePrediction(prediction, null);
      return;
    }

    final correctedAnimal = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Corregir animal'),
        children: animalCatalog
            .map(
              (animal) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, animal.name),
                child: Text(animal.name),
              ),
            )
            .toList(),
      ),
    );
    if (!mounted) return;
    if (correctedAnimal != null && correctedAnimal != prediction.animal) {
      await _updatePrediction(prediction, correctedAnimal);
    }
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
            'No se ha podido actualizar la identificación. Inténtalo de nuevo.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isAnonymous) return const _GuestCollection();
    return Scaffold(
      appBar: AppBar(title: const Text('Mi colección')),
      body: StreamBuilder<UserCollection>(
        stream: widget.repository.watch(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const _CollectionError();
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final collection = snapshot.data!;
          if (collection.isEmpty) {
            return _EmptyCollection(
              onStartIdentifying: widget.onStartIdentifying,
            );
          }
          final entries =
              collection.counts.entries
                  .where((entry) => animalByName.containsKey(entry.key))
                  .toList()
                ..sort((left, right) => _compare(left, right, collection));
          return ListView(
            padding: MichiTokens.pagePadding,
            children: [
              _CollectionSummary(collection: collection, entries: entries),
              const SizedBox(height: MichiTokens.space16),
              DropdownButtonFormField<CollectionOrder>(
                initialValue: _order,
                decoration: const InputDecoration(labelText: 'Ordenar fichas'),
                items: const [
                  DropdownMenuItem(
                    value: CollectionOrder.name,
                    child: Text('Por nombre'),
                  ),
                  DropdownMenuItem(
                    value: CollectionOrder.amount,
                    child: Text('Por cantidad'),
                  ),
                  DropdownMenuItem(
                    value: CollectionOrder.latest,
                    child: Text('Último identificado'),
                  ),
                ],
                onChanged: (value) =>
                    setState(() => _order = value ?? CollectionOrder.name),
              ),
              const SizedBox(height: MichiTokens.space16),
              ...entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: MichiTokens.space12),
                  child: _AnimalCard(
                    animal: animalByName[entry.key]!,
                    count: entry.value,
                  ),
                ),
              ),
              _PredictionHistory(
                repository: widget.repository,
                userId: widget.userId,
                onEdit: _editPrediction,
              ),
            ],
          );
        },
      ),
    );
  }

  int _compare(
    MapEntry<String, int> left,
    MapEntry<String, int> right,
    UserCollection collection,
  ) => switch (_order) {
    CollectionOrder.name => left.key.compareTo(right.key),
    CollectionOrder.amount => right.value.compareTo(left.value),
    CollectionOrder.latest =>
      (collection.lastIdentified[right.key] ?? DateTime(0)).compareTo(
        collection.lastIdentified[left.key] ?? DateTime(0),
      ),
  };
}

class _GuestCollection extends StatelessWidget {
  const _GuestCollection();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Padding(
        padding: MichiTokens.pagePadding,
        child: Text(
          'Inicia sesión con una cuenta para guardar tu colección.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

class _CollectionError extends StatelessWidget {
  const _CollectionError();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: MichiTokens.pagePadding,
      child: Text(
        'No se ha podido cargar la colección. Comprueba tu conexión e inténtalo de nuevo.',
        textAlign: TextAlign.center,
      ),
    ),
  );
}

class _CollectionSummary extends StatelessWidget {
  const _CollectionSummary({required this.collection, required this.entries});
  final UserCollection collection;
  final List<MapEntry<String, int>> entries;

  @override
  Widget build(BuildContext context) {
    final achievements = <String>[
      if (collection.totalPhotos > 0) 'Primera foto',
      if (collection.discovered >= 5) 'Cinco especies',
      if (collection.discovered == animalCatalog.length) 'Colección completa',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MichiTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progreso de la colección',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: MichiTokens.space8),
            Text(
              '${collection.discovered} de ${animalCatalog.length} especies descubiertas',
            ),
            const SizedBox(height: MichiTokens.space8),
            LinearProgressIndicator(
              value: collection.discovered / animalCatalog.length,
            ),
            if (achievements.isNotEmpty) ...[
              const SizedBox(height: MichiTokens.space16),
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
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimalCard extends StatelessWidget {
  const _AnimalCard({required this.animal, required this.count});
  final Animal animal;
  final int count;

  @override
  Widget build(BuildContext context) => Card(
    child: SizedBox(
      height: 120,
      child: Row(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Image.asset(animal.imageAsset, fit: BoxFit.cover),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(MichiTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: MichiTokens.space4),
                  Expanded(child: Text(animal.description)),
                  Text(
                    '$count ${count == 1 ? 'foto' : 'fotos'} coleccionada${count == 1 ? '' : 's'}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PredictionHistory extends StatelessWidget {
  const _PredictionHistory({
    required this.repository,
    required this.userId,
    required this.onEdit,
  });
  final CollectionRepository repository;
  final String userId;
  final Future<void> Function(CollectionPrediction prediction, String action)
  onEdit;

  @override
  Widget build(BuildContext context) =>
      StreamBuilder<List<CollectionPrediction>>(
        stream: repository.watchPredictions(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const SizedBox.shrink();
          }
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(MichiTokens.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Identificaciones recientes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ...snapshot.data!.map(
                    (prediction) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        animalByName[prediction.animal]?.icon ?? Icons.pets,
                      ),
                      title: Text(prediction.animal),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) => onEdit(prediction, action),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'correct',
                            child: Text('Corregir'),
                          ),
                          PopupMenuItem(value: 'delete', child: Text('Borrar')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
            label: const Text('Hacer una predicción'),
          ),
        ],
      ),
    ),
  );
}
