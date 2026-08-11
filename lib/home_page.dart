import 'package:animalspredictor/auth_service.dart';
import 'package:animalspredictor/animal_catalog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tensorflow_lite_flutter/tensorflow_lite_flutter.dart';

enum CollectionOrder { name, amount, latest }

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});
  final User user;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _picker = ImagePicker();
  Uint8List? _image;
  String? _predictedAnimal;
  double? _confidence;
  String? _selectedAnimal;
  String? _error;
  bool _loading = true;
  bool _modelReady = false;
  bool _saving = false;
  bool _permissionDenied = false;
  var _index = 0;
  CollectionOrder _collectionOrder = CollectionOrder.name;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (kIsWeb) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'La clasificación está disponible en Android e iOS.';
        });
      }
      return;
    }
    try {
      await Tflite.loadModel(
        model: 'assets/model.tflite',
        labels: 'assets/labels.txt',
      );
      _modelReady = true;
    } catch (_) {
      _error = 'No se ha podido cargar el modelo.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pick(ImageSource source) async {
    if (!_modelReady) {
      setState(() => _error = 'El modelo aún no está disponible.');
      return;
    }
    if (!kIsWeb && !await _requestPermission(source)) return;
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 224,
        maxHeight: 224,
      );
      if (image == null) return;
      setState(() {
        _loading = true;
        _error = null;
        _permissionDenied = false;
        _predictedAnimal = null;
        _selectedAnimal = null;
      });
      final results = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 3,
        threshold: 0,
        imageMean: 0,
        imageStd: 1,
      );
      final result = results?.isEmpty ?? true ? null : results!.first;
      if (result is! Map<dynamic, dynamic> ||
          result['label'] is! String ||
          result['confidence'] is! num) {
        throw StateError('Resultado del modelo inválido');
      }
      final label = result['label'] as String;
      final bytes = await image.readAsBytes();
      if (mounted) {
        HapticFeedback.selectionClick();
        setState(() {
          _image = bytes;
          _predictedAnimal = label;
          _selectedAnimal = label;
          _confidence = (result['confidence'] as num).toDouble();
        });
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() => _error = _firebaseErrorMessage(error));
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se ha podido clasificar la imagen.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<bool> _requestPermission(ImageSource source) async {
    final permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;
    final status = await permission.request();
    if (status.isGranted || status.isLimited) return true;
    if (mounted) {
      setState(() {
        _permissionDenied = true;
        _error = source == ImageSource.camera
            ? 'El permiso de cámara es necesario para hacer una foto.'
            : 'El permiso de fotos es necesario para elegir una imagen.';
      });
    }
    return false;
  }

  Future<void> _confirmPrediction() async {
    final animal = _selectedAnimal;
    if (animal == null) return;
    setState(() => _saving = true);
    try {
      await _saveToCollection(animal);
      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.user.isAnonymous
                ? 'Resultado confirmado.'
                : '$animal se ha añadido a tu colección.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveToCollection(String label) async {
    if (widget.user.isAnonymous) return;
    try {
      final firestore = FirebaseFirestore.instance;
      final user = firestore.collection('users').doc(widget.user.uid);
      final prediction = user.collection('predictions').doc();
      final batch = firestore.batch();
      batch.set(user, {
        'collection.$label': FieldValue.increment(1),
        'lastIdentifiedAt': FieldValue.serverTimestamp(),
        'lastIdentified.$label': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      batch.set(prediction, {
        'animal': label,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _error = _collectionErrorMessage(error));
    }
  }

  String _firebaseErrorMessage(FirebaseException error) => switch (error.code) {
    'permission-denied' => 'No tienes permiso para guardar en tu colección.',
    'unavailable' => 'No hay conexión. La imagen no se ha podido clasificar.',
    _ => 'No se ha podido clasificar la imagen. Inténtalo de nuevo.',
  };

  String _collectionErrorMessage(
    FirebaseException error,
  ) => switch (error.code) {
    'permission-denied' =>
      'La predicción se ha hecho, pero no tienes permiso para guardarla.',
    'unavailable' =>
      'La predicción se ha hecho. Se guardará cuando vuelva la conexión.',
    _ =>
      'La predicción se ha hecho, pero no se ha podido guardar en la colección.',
  };

  @override
  void dispose() {
    if (!kIsWeb) Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_index == 0 ? 'La granja de Michi' : 'Mi colección'),
    ),
    drawer: _drawer(),
    body: _index == 0 ? _classifier() : _collection(),
  );

  Widget _drawer() => Drawer(
    child: Material(
      color: const Color(0xFF324BCD),
      child: SafeArea(
        child: ListView(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF324BCD)),
              accountName: Text(
                widget.user.isAnonymous
                    ? 'Invitado'
                    : (widget.user.email ?? 'Usuario'),
              ),
              accountEmail: null,
            ),
            _navItem(Icons.image_search, 'Predecir', 0),
            _navItem(Icons.collections_bookmark, 'Colección', 1),
            ListTile(
              minVerticalPadding: 14,
              leading: const Icon(
                Icons.logout,
                color: Colors.white,
                semanticLabel: 'Cerrar sesión',
              ),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await AuthService(
                    FirebaseAuth.instance,
                    FirebaseFirestore.instance,
                  ).signOut();
                } on FirebaseAuthException {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('No se ha podido cerrar sesión.'),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    ),
  );

  Widget _navItem(IconData icon, String label, int index) => ListTile(
    minVerticalPadding: 14,
    leading: Icon(icon, color: Colors.white, semanticLabel: label),
    title: Text(label, style: const TextStyle(color: Colors.white)),
    onTap: () {
      Navigator.pop(context);
      setState(() => _index = index);
    },
  );

  Widget _classifier() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFA8E063), Color(0xFF56AB2F)],
      ),
    ),
    child: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: LayoutBuilder(
            builder: (context, constraints) => ListView(
              padding: EdgeInsets.symmetric(
                horizontal: constraints.maxWidth < 380 ? 16 : 24,
                vertical: 24,
              ),
              children: [
                Text(
                  'Identifica animales en una foto',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF172238),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                AspectRatio(
                  aspectRatio: 1,
                  child: Semantics(
                    label: _image == null
                        ? 'Imagen de ejemplo de animales de granja'
                        : 'Imagen seleccionada para clasificar',
                    image: true,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_image != null)
                            Image.memory(_image!, fit: BoxFit.cover)
                          else
                            Image.asset(
                              'assets/farm_animals.png',
                              fit: BoxFit.contain,
                            ),
                          if (_loading)
                            const ColoredBox(color: Color(0x55000000)),
                          if (_loading)
                            const Center(child: CircularProgressIndicator()),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_predictedAnimal != null) _predictionCard(),
                if (_error != null) _errorCard(),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _loading || !_modelReady
                        ? null
                        : () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt, semanticLabel: 'Cámara'),
                    label: const Text('Hacer una foto'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _loading || !_modelReady
                        ? null
                        : () => _pick(ImageSource.gallery),
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      semanticLabel: 'Galería',
                    ),
                    label: const Text('Elegir de la galería'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _predictionCard() => Card(
    margin: const EdgeInsets.only(top: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resultado de la predicción',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Detectado: $_predictedAnimal',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text('Confianza: ${((_confidence ?? 0) * 100).toStringAsFixed(1)} %'),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedAnimal,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: '¿Es el animal correcto?',
            ),
            items: animalCatalog
                .map(
                  (animal) => DropdownMenuItem(
                    value: animal.name,
                    child: Text(animal.name),
                  ),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (value) => setState(() => _selectedAnimal = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _saving ? null : _confirmPrediction,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(
                _saving
                    ? 'Guardando...'
                    : _selectedAnimal == _predictedAnimal
                    ? 'Confirmar resultado'
                    : 'Guardar corrección',
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _errorCard() => Card(
    color: Theme.of(context).colorScheme.errorContainer,
    margin: const EdgeInsets.only(top: 16),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _error!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          if (_permissionDenied) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: openAppSettings,
              icon: const Icon(Icons.settings),
              label: const Text('Abrir Ajustes'),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _collection() {
    if (widget.user.isAnonymous) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Inicia sesión con una cuenta para guardar tu colección.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No se ha podido cargar la colección. Comprueba tu conexión e inténtalo de nuevo.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rawCollection = snapshot.data?.data()?['collection'];
        final collection = rawCollection is Map<String, dynamic>
            ? rawCollection
            : <String, dynamic>{};
        final rawLastIdentified = snapshot.data?.data()?['lastIdentified'];
        final lastIdentified = rawLastIdentified is Map<String, dynamic>
            ? rawLastIdentified
            : <String, dynamic>{};
        if (collection.isEmpty) return _emptyCollection();
        final discovered = collection.keys
            .where((name) => animalByName.containsKey(name))
            .length;
        final entries = collection.entries
            .where((entry) => animalByName.containsKey(entry.key))
            .toList();
        entries.sort((a, b) {
          if (_collectionOrder == CollectionOrder.amount) {
            return _asCount(b.value).compareTo(_asCount(a.value));
          }
          if (_collectionOrder == CollectionOrder.latest) {
            return _asDate(
              lastIdentified[b.key],
            ).compareTo(_asDate(lastIdentified[a.key]));
          }
          return a.key.compareTo(b.key);
        });
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _collectionSummary(discovered, entries),
            const SizedBox(height: 12),
            DropdownButtonFormField<CollectionOrder>(
              initialValue: _collectionOrder,
              decoration: const InputDecoration(
                labelText: 'Ordenar fichas',
                border: OutlineInputBorder(),
              ),
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
              onChanged: (order) => setState(
                () => _collectionOrder = order ?? CollectionOrder.name,
              ),
            ),
            const SizedBox(height: 12),
            ...entries.map(
              (entry) =>
                  _animalCard(animalByName[entry.key]!, _asCount(entry.value)),
            ),
            const SizedBox(height: 12),
            _predictionHistory(),
          ],
        );
      },
    );
  }

  int _asCount(dynamic value) => value is num ? value.toInt() : 0;

  DateTime _asDate(dynamic value) => value is Timestamp
      ? value.toDate()
      : DateTime.fromMillisecondsSinceEpoch(0);

  Widget _collectionSummary(
    int discovered,
    List<MapEntry<String, dynamic>> entries,
  ) {
    final totalPhotos = entries.fold<int>(
      0,
      (total, entry) => total + _asCount(entry.value),
    );
    final achievements = <String>[
      if (totalPhotos > 0) 'Primera foto',
      if (discovered >= 5) 'Cinco especies',
      if (discovered == animalCatalog.length) 'Colección completa',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progreso de la colección',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '$discovered de ${animalCatalog.length} especies descubiertas',
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: discovered / animalCatalog.length),
            if (achievements.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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

  Widget _animalCard(Animal animal, int count) => Card(
    clipBehavior: Clip.antiAlias,
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
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animal.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
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

  Widget _predictionHistory() =>
      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .collection('predictions')
            .orderBy('createdAt', descending: true)
            .limit(20)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const SizedBox.shrink();
          }
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Identificaciones recientes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ...snapshot.data!.docs.map((document) {
                    final animal =
                        document.data()['animal'] as String? ?? 'Animal';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(animalByName[animal]?.icon ?? Icons.pets),
                      title: Text(animal),
                      trailing: PopupMenuButton<String>(
                        onSelected: (action) =>
                            _editPrediction(document, animal, action),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'correct',
                            child: Text('Corregir'),
                          ),
                          PopupMenuItem(value: 'delete', child: Text('Borrar')),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      );

  Future<void> _editPrediction(
    DocumentSnapshot<Map<String, dynamic>> document,
    String oldAnimal,
    String action,
  ) async {
    if (action == 'delete') {
      await _updatePrediction(document, oldAnimal, null);
      return;
    }
    if (!mounted) return;
    final corrected = await showDialog<String>(
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
    if (corrected != null && corrected != oldAnimal) {
      await _updatePrediction(document, oldAnimal, corrected);
    }
  }

  Future<void> _updatePrediction(
    DocumentSnapshot<Map<String, dynamic>> document,
    String oldAnimal,
    String? newAnimal,
  ) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final user = firestore.collection('users').doc(widget.user.uid);
      final userData = (await user.get()).data();
      final currentCollection =
          userData?['collection'] as Map<String, dynamic>?;
      final oldCount = _asCount(currentCollection?[oldAnimal]);
      final batch = firestore.batch();
      batch.update(user, {
        'collection.$oldAnimal': oldCount <= 1
            ? FieldValue.delete()
            : FieldValue.increment(-1),
      });
      if (newAnimal == null) {
        batch.delete(document.reference);
      } else {
        batch.update(user, {
          'collection.$newAnimal': FieldValue.increment(1),
          'lastIdentified.$newAnimal': FieldValue.serverTimestamp(),
        });
        batch.update(document.reference, {'animal': newAnimal});
      }
      await batch.commit();
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _error = _collectionErrorMessage(error));
    }
  }

  Widget _emptyCollection() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.collections_bookmark_outlined, size: 64),
            const SizedBox(height: 16),
            Text(
              'Tu colección está esperando',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Haz tu primera predicción y confirma el animal para añadirlo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => setState(() => _index = 0),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Hacer una predicción'),
            ),
          ],
        ),
      ),
    ),
  );
}
