import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/collection/presentation/collection_history_page.dart';
import 'package:animalspredictor/features/collection/presentation/prediction_edit_action.dart';
import 'package:animalspredictor/models/user_collection.dart';
import 'package:animalspredictor/services/collection_repository.dart';
import 'package:flutter/material.dart';

class AnimalDetailPage extends StatefulWidget {
  const AnimalDetailPage({
    super.key,
    required this.animal,
    required this.repository,
    required this.userId,
    required this.onEdit,
  });

  final Animal animal;
  final CollectionRepository repository;
  final String userId;
  final Future<void> Function(CollectionPrediction, PredictionEditAction)
  onEdit;

  @override
  State<AnimalDetailPage> createState() => _AnimalDetailPageState();
}

class _AnimalDetailPageState extends State<AnimalDetailPage> {
  var _refreshKey = 0;

  void _retry() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.animal.name)),
    body: StreamBuilder<UserCollection>(
      key: ValueKey(_refreshKey),
      stream: widget.repository.watch(widget.userId),
      builder: (context, collectionSnapshot) {
        if (collectionSnapshot.hasError) {
          return _DetailError(onRetry: _retry);
        }
        if (!collectionSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final collection = collectionSnapshot.data!;
        return StreamBuilder<List<CollectionPrediction>>(
          stream: widget.repository.watchPredictions(widget.userId),
          builder: (context, predictionSnapshot) {
            if (predictionSnapshot.hasError) {
              return _DetailError(onRetry: _retry);
            }
            if (!predictionSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final predictions = predictionSnapshot.data!
                .where((prediction) => prediction.animal == widget.animal.name)
                .toList(growable: false);
            return _AnimalDetailContent(
              animal: widget.animal,
              count: collection.counts[widget.animal.name] ?? 0,
              lastIdentified: collection.lastIdentified[widget.animal.name],
              predictions: predictions,
              onEdit: widget.onEdit,
            );
          },
        );
      },
    ),
  );
}

class _AnimalDetailContent extends StatelessWidget {
  const _AnimalDetailContent({
    required this.animal,
    required this.count,
    required this.lastIdentified,
    required this.predictions,
    required this.onEdit,
  });

  final Animal animal;
  final int count;
  final DateTime? lastIdentified;
  final List<CollectionPrediction> predictions;
  final Future<void> Function(CollectionPrediction, PredictionEditAction)
  onEdit;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: MichiTokens.pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(MichiTokens.radiusLarge),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.asset(
                    animal.imageAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Center(child: Icon(animal.icon)),
                  ),
                ),
              ),
              const SizedBox(height: MichiTokens.space16),
              Text(
                animal.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: MichiTokens.space16),
              Row(
                children: [
                  _Statistic(label: 'Fotos', value: '$count'),
                  const SizedBox(width: MichiTokens.space12),
                  _Statistic(
                    label: 'Última vez',
                    value: lastIdentified == null
                        ? 'Aún no'
                        : _formatDate(lastIdentified!),
                  ),
                ],
              ),
              const SizedBox(height: MichiTokens.space24),
              Text(
                'Historial de ${animal.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: MichiTokens.space8),
            ],
          ),
        ),
      ),
      if (predictions.isEmpty)
        const SliverToBoxAdapter(
          child: Padding(
            padding: MichiTokens.pagePadding,
            child: Text(
              'Aún no hay identificaciones guardadas de esta especie.',
            ),
          ),
        )
      else
        PredictionHistoryList(
          predictions: predictions,
          onEdit: onEdit,
          padding: const EdgeInsets.fromLTRB(
            MichiTokens.space24,
            0,
            MichiTokens.space24,
            MichiTokens.space24,
          ),
          asSliver: true,
        ),
    ],
  );
}

class _Statistic extends StatelessWidget {
  const _Statistic({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(MichiTokens.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: MichiTokens.space4),
            Text(value, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    ),
  );
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: MichiTokens.pagePadding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 56),
          const SizedBox(height: MichiTokens.space16),
          const Text(
            'No se ha podido cargar esta especie. Comprueba tu conexión e inténtalo de nuevo.',
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

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
