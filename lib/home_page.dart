import 'dart:typed_data';

import 'package:animalspredictor/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await Tflite.loadModel(
        model: 'assets/model.tflite',
        labels: 'assets/labels.txt',
      );
    } catch (_) {
      _error = 'No se ha podido cargar el modelo.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pick(ImageSource source) async {
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
      final result = results?.isEmpty ?? true
          ? null
          : results!.first as Map<dynamic, dynamic>;
      if (result == null) throw StateError('No hay resultados');
      if (!widget.user.isAnonymous) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .set({
              'collection.${result['label']}': FieldValue.increment(1),
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
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(_index == 0 ? 'Clasificar animales' : 'Mi colección'),
    ),
    drawer: Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(
              widget.user.isAnonymous
                  ? 'Invitado'
                  : (widget.user.email ?? 'Usuario'),
            ),
            accountEmail: null,
          ),
          ListTile(
            leading: const Icon(Icons.pets),
            title: const Text('Predecir'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _index = 0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.collections_bookmark),
            title: const Text('Colección'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _index = 1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Cerrar sesión'),
            onTap: () => AuthService(
              FirebaseAuth.instance,
              FirebaseFirestore.instance,
            ).signOut(),
          ),
        ],
      ),
    ),
    body: _index == 0 ? _classifier() : _collection(),
  );
  Widget _classifier() => Center(
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
                    Image.asset('assets/farm_animals.png', fit: BoxFit.contain),
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
            onPressed: _loading ? null : () => _pick(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Hacer una foto'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Elegir de la galería'),
          ),
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
        final collection =
            snapshot.data?.data()?['collection'] as Map<String, dynamic>? ?? {};
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
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
