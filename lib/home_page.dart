import 'package:animalspredictor/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tensorflow_lite_flutter/tensorflow_lite_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.user});
  final User user;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _picker = ImagePicker();
  Uint8List? _image;
  Map<dynamic, dynamic>? _prediction;
  String? _error;
  bool _loading = true;
  bool _modelReady = false;
  var _index = 0;

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
      });
      final results = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 3,
        threshold: 0,
        imageMean: 0,
        imageStd: 1,
      );
      final bytes = await image.readAsBytes();
      final result = results?.isEmpty ?? true ? null : results!.first;
      if (result is! Map<dynamic, dynamic>) {
        throw StateError('El modelo no ha devuelto un resultado válido.');
      }
      final label = result['label'];
      final confidence = result['confidence'];
      if (label is! String || confidence is! num) {
        throw StateError('El resultado del modelo está incompleto.');
      }
      if (!widget.user.isAnonymous) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .set({
              'collection.$label': FieldValue.increment(1),
            }, SetOptions(merge: true));
      }
      if (mounted) {
        setState(() {
          _image = bytes;
          _prediction = result;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se ha podido clasificar la imagen.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
    drawer: Drawer(
      child: Material(
        color: const Color(0xFF324BCD),
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
            ListTile(
              leading: const Icon(Icons.image_search, color: Colors.white),
              title: const Text(
                'Predecir',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() => _index = 0);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.collections_bookmark,
                color: Colors.white,
              ),
              title: const Text(
                'Colección',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() => _index = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.white),
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
                  if (context.mounted) {
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
    body: _index == 0 ? _classifier() : _collection(),
  );
  Widget _classifier() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFA8E063), Color(0xFF56AB2F)],
      ),
    ),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Identifica animales en una foto',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1,
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
                    if (_loading) const ColoredBox(color: Color(0x55000000)),
                    if (_loading)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
            ),
            if (_prediction != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.pets),
                  title: Text(_prediction!['label'] as String),
                  subtitle: Text(
                    'Confianza: ${((_prediction!['confidence'] as num) * 100).toStringAsFixed(1)} %',
                  ),
                ),
              ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loading || !_modelReady
                  ? null
                  : () => _pick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Hacer una foto'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading || !_modelReady
                  ? null
                  : () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Elegir de la galería'),
            ),
          ],
        ),
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
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No se ha podido cargar la colección.'),
            ),
          );
        }
        final rawCollection = snapshot.data?.data()?['collection'];
        final collection = rawCollection is Map<String, dynamic>
            ? rawCollection
            : <String, dynamic>{};
        if (collection.isEmpty) {
          return const Center(
            child: Text('Aún no has añadido animales a tu colección.'),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: collection.entries
              .map(
                (entry) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.pets),
                    title: Text(entry.key),
                    trailing: Text('${entry.value}'),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}
