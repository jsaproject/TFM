import 'package:animalspredictor/widget/navigation_drawer_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final picker = ImagePicker();
  File _image;
  bool _loading = false;
  List _output;
  bool _imagePickCamera = false;
  final FirebaseAuth auth = FirebaseAuth.instance;

  pickImage() async {
    var image = await picker.getImage(
        source: ImageSource.camera, maxHeight: 224, maxWidth: 224);

    if (image == null) return null;

    setState(() {
      _image = File(image.path);
    });
    classifyImage(_image);
    _imagePickCamera = true;
  }

  pickGalleryImage() async {
    var image = await picker.getImage(
        source: ImageSource.gallery, maxHeight: 224, maxWidth: 224);

    if (image == null) return null;

    setState(() {
      _image = File(image.path);
    });
    classifyImage(_image);
    _imagePickCamera = false;
  }

  @override
  void initState() {
    super.initState();
    _loading = true;
    loadModel().then((value) {
      // setState(() {});
    });
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 10,
        threshold: 0.5,
        imageMean: 0,
        imageStd: 1);

    setState(() {
      _loading = false;
      _output = output;
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: 'assets/model.tflite',
      labels: 'assets/labels.txt',
    );
  }

  updateAnswersInfo(String parameter) async {
    int respuesta = 0;
    int numRespuestas = 0;
    await FirebaseFirestore.instance
        .collection("predictions")
        .doc('countWrongAndCorrectAnswers')
        .get()
        .asStream()
        .forEach((element) {
      numRespuestas = element.data()['totalAnswers'] + 1;
      respuesta = element.data()[parameter] + 1;
    });
    FirebaseFirestore.instance
        .collection("predictions")
        .doc('countWrongAndCorrectAnswers')
        .update({'totalAnswers': numRespuestas, parameter: respuesta});
  }

  updateWrongAnswersInfo(String animal) async {
    int respuesta = 0;
    int animalCount = 0;
    await FirebaseFirestore.instance
        .collection("predictions")
        .doc('animalWrongDetect')
        .get()
        .asStream()
        .forEach((element) {
      animalCount = element.data()[animal] + 1;
      respuesta = element.data()['totalWrong'] + 1;
    });
    String fileName = _image.path.split('/').last;
    try {
      await firebase_storage.FirebaseStorage.instance
          .ref('uploads/$animal/$fileName')
          .putFile(_image);
    } on firebase_core.FirebaseException catch (e) {
      print('Failed');
    }
    FirebaseFirestore.instance
        .collection("predictions")
        .doc('animalWrongDetect')
        .update({'totalWrong': respuesta, animal: animalCount});
  }

  void updateCollectionUser() async {
    int animal = 0;
    String email = auth.currentUser.email;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .get()
        .asStream()
        .forEach((element) {
      animal = element.data()['${_output[0]['label']}'] + 1;
    });
    FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .update({'${_output[0]['label']}': animal});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavigationDrawerWidget(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.004, 1],
            colors: [
              Color(0xFFa8e063),
              Color(0xFF56ab2f),
            ],
          ),
        ),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: <Widget>[
              SizedBox(height: 60),
              Text(
                'La granja de Michi',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 28),
              ),
              SizedBox(
                height: 70,
              ),
              Container(
                padding: EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                    )
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      height: 10,
                    ),
                    Container(
                      width: 300,
                      child: Center(
                        child: _loading
                            ? Container(
                                width: 180,
                                child: Column(
                                  children: <Widget>[
                                    Image.asset('assets/granja.jpg'),
                                    SizedBox(
                                      height: 60,
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                      height: 200,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          _image,
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 20,
                                    ),
                                    _output != null
                                        ? Text(
                                            'El animal es: ${_output[0]['label']}',
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 20.0),
                                          )
                                        : Container(),
                                    SizedBox(
                                      height: 20,
                                    ),
                                    Text(
                                      '¿Es correcto?',
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 20.0),
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Container(
                                      child: Row(
                                        children: <Widget>[
                                          Expanded(
                                            child: FloatingActionButton(
                                              heroTag: "btn3",
                                              child: Text('Sí'),
                                              onPressed: () {
                                                updateAnswersInfo(
                                                    'totalCorrectAnswers');
                                                if (_imagePickCamera &&
                                                    auth.currentUser != null) {
                                                  updateCollectionUser();
                                                }
                                                dispose();
                                                Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            Home()));
                                              },
                                            ),
                                          ),
                                          Expanded(
                                            child: FloatingActionButton(
                                              heroTag: "btn4",
                                              child: Text('No'),
                                              onPressed: () async {
                                                updateAnswersInfo(
                                                    'totalWrongAnswers');
                                                bool shouldUpdate =
                                                    await showDialog(
                                                        context: context,
                                                        builder: (_) =>
                                                            new SimpleDialog(
                                                              title: new Text(
                                                                  '¿Cuál es el animal correcto?'),
                                                              children: <
                                                                  Widget>[
                                                                new SimpleDialogOption(
                                                                  child: new Text(
                                                                      'Perro'),
                                                                  onPressed:
                                                                      () {
                                                                    updateWrongAnswersInfo(
                                                                        'Perro');
                                                                    Navigator.pop(
                                                                        context,
                                                                        true);
                                                                  },
                                                                ),
                                                                new SimpleDialogOption(
                                                                  child: new Text(
                                                                      'Caballo'),
                                                                  onPressed:
                                                                      () {
                                                                    updateWrongAnswersInfo(
                                                                        'Caballo');
                                                                    Navigator.pop(
                                                                        context,
                                                                        true);
                                                                  },
                                                                ),
                                                                new SimpleDialogOption(
                                                                  child: new Text(
                                                                      'Elefante'),
                                                                  onPressed:
                                                                      () {
                                                                    updateWrongAnswersInfo(
                                                                        'Elefante');
                                                                    Navigator.pop(
                                                                        context,
                                                                        true);
                                                                  },
                                                                ),
                                                                new SimpleDialogOption(
                                                                  child: new Text(
                                                                      'Mariposa'),
                                                                  onPressed:
                                                                      () {
                                                                    updateWrongAnswersInfo(
                                                                        'Mariposa');
                                                                    Navigator.pop(
                                                                        context,
                                                                        true);
                                                                  },
                                                                ),
                                                                new SimpleDialogOption(
                                                                  child: new Text(
                                                                      'Gallina'),
                                                                  onPressed:
                                                                      () {
                                                                    updateWrongAnswersInfo(
                                                                        'Gallina');
                                                                    Navigator.pop(
                                                                        context,
                                                                        true);
                                                                  },
                                                                ),
                                                                new SimpleDialogOption(
                                                                  child: new Text(
                                                                      'Gato'),
                                                                  onPressed:
                                                                      () {
                                                                    updateWrongAnswersInfo(
                                                                        'Gato');
                                                                    Navigator.pop(
                                                                        context,
                                                                        true);
                                                                  },
                                                                ),
                                                                new SimpleDialogOption(
                                                                  child: new Text(
                                                                      'Vaca'),
                                                                  onPressed:
                                                                      () {
                                                                    updateWrongAnswersInfo(
                                                                        'Vaca');
                                                                    Navigator.pop(
                                                                        context,
                                                                        true);
                                                                  },
                                                                ),
                                                                new SimpleDialogOption(
                                                                  child: new Text(
                                                                      'Oveja'),
                                                                  onPressed:
                                                                      () {
                                                                    updateWrongAnswersInfo(
                                                                        'Oveja');
                                                                    Navigator.pop(
                                                                        context,
                                                                        true);
                                                                  },
                                                                ),
                                                                new SimpleDialogOption(
                                                                  child: new Text(
                                                                      'Araña'),
                                                                  onPressed:
                                                                      () {
                                                                    updateWrongAnswersInfo(
                                                                        'Araña');
                                                                    Navigator.pop(
                                                                        context,
                                                                        true);
                                                                  },
                                                                ),
                                                                new SimpleDialogOption(
                                                                  child: new Text(
                                                                      'Ardilla'),
                                                                  onPressed:
                                                                      () {
                                                                    updateWrongAnswersInfo(
                                                                        'Ardilla');
                                                                    Navigator.pop(
                                                                        context,
                                                                        true);
                                                                  },
                                                                ),
                                                              ],
                                                            ));
                                                dispose();
                                                Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            Home()));
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(
                                      height: 20,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    Container(
                        width: MediaQuery.of(context).size.width,
                        child: Column(
                          children: <Widget>[
                            GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                width: MediaQuery.of(context).size.width - 180,
                                alignment: Alignment.center,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 17,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF56ab2f),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Haz una foto',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18),
                                ),
                              ),
                            ),
                            SizedBox(height: 5),
                            GestureDetector(
                              onTap: pickGalleryImage,
                              child: Container(
                                width: MediaQuery.of(context).size.width - 180,
                                alignment: Alignment.center,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 17,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(0xFF56ab2f),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Galería',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18),
                                ),
                              ),
                            ),
                          ],
                        ))
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
