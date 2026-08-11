import 'package:animalspredictor/animal_catalog.dart';
import 'package:animalspredictor/app_theme.dart';
import 'package:animalspredictor/features/collection/presentation/prediction_edit_action.dart';
import 'package:animalspredictor/services/collection_repository.dart';
import 'package:flutter/material.dart';

class CollectionHistoryPage extends StatefulWidget {
  const CollectionHistoryPage({
    super.key,
    required this.repository,
    required this.userId,
    required this.onEdit,
  });

  final CollectionRepository repository;
  final String userId;
  final Future<void> Function(CollectionPrediction, PredictionEditAction)
  onEdit;

  @override
  State<CollectionHistoryPage> createState() => _CollectionHistoryPageState();
}

class _CollectionHistoryPageState extends State<CollectionHistoryPage> {
  var _refreshKey = 0;

  void _retry() => setState(() => _refreshKey++);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Historial')),
    body: StreamBuilder<List<CollectionPrediction>>(
      key: ValueKey(_refreshKey),
      stream: widget.repository.watchPredictions(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _HistoryError(onRetry: _retry);
        if (!snapshot.hasData) return const _HistorySkeleton();
        if (snapshot.data!.isEmpty) return const _EmptyHistory();
        return PredictionHistoryList(
          predictions: snapshot.data!,
          onEdit: widget.onEdit,
          padding: MichiTokens.pagePadding,
        );
      },
    ),
  );
}

class PredictionHistoryList extends StatefulWidget {
  const PredictionHistoryList({
    super.key,
    required this.predictions,
    required this.onEdit,
    required this.padding,
    this.asSliver = false,
  });

  final List<CollectionPrediction> predictions;
  final Future<void> Function(CollectionPrediction, PredictionEditAction)
  onEdit;
  final EdgeInsets padding;
  final bool asSliver;

  @override
  State<PredictionHistoryList> createState() => _PredictionHistoryListState();
}

class _PredictionHistoryListState extends State<PredictionHistoryList> {
  final _updatingIds = <String>{};

  Future<void> _edit(
    CollectionPrediction prediction,
    PredictionEditAction action,
  ) async {
    if (!_updatingIds.add(prediction.id)) return;
    setState(() {});
    try {
      await widget.onEdit(prediction, action);
    } finally {
      if (mounted) setState(() => _updatingIds.remove(prediction.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.asSliver) {
      return SliverPadding(
        padding: widget.padding,
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            _item,
            childCount: widget.predictions.length,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: widget.padding,
      itemCount: widget.predictions.length,
      itemBuilder: _item,
    );
  }

  Widget _item(BuildContext context, int index) {
    final prediction = widget.predictions[index];
    final animal = animalByName[prediction.animal];
    final isUpdating = _updatingIds.contains(prediction.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: MichiTokens.space8),
      child: Card(
        child: ListTile(
          leading: Icon(animal?.icon ?? Icons.pets),
          title: Text(prediction.animal),
          subtitle: Text(_dateLabel(prediction.createdAt)),
          trailing: isUpdating
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : PopupMenuButton<PredictionEditAction>(
                  tooltip: 'Acciones de identificación',
                  onSelected: (action) => _edit(prediction, action),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: PredictionEditAction.correct,
                      child: Text('Corregir'),
                    ),
                    PopupMenuItem(
                      value: PredictionEditAction.delete,
                      child: Text('Borrar'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.onRetry});
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
            'No se ha podido cargar el historial. Comprueba tu conexión e inténtalo de nuevo.',
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

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: MichiTokens.pagePadding,
    itemCount: 6,
    separatorBuilder: (_, _) => const SizedBox(height: MichiTokens.space8),
    itemBuilder: (context, _) => DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(MichiTokens.radiusMedium),
      ),
      child: const SizedBox(height: 72),
    ),
  );
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: MichiTokens.pagePadding,
      child: Text('Todavía no hay identificaciones en el historial.'),
    ),
  );
}

String _dateLabel(DateTime? date) {
  if (date == null) return 'Pendiente de sincronizar';
  return 'Identificado el ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
