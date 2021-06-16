import 'package:animalspredictor/widget/navigation_drawer_widget.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final picker = ImagePicker();
  File _image;
  bool _loading = false;
  List _output;

  pickImage() async {
    var image = await picker.getImage(source: ImageSource.camera,
        maxHeight: 224,
        maxWidth: 224);

    if (image == null) return null;

    setState(() {
      _image = File(image.path);
    });
    classifyImage(_image);
  }



  pickGalleryImage() async {
    var image = await picker.getImage(source: ImageSource.gallery,maxHeight: 224,
        maxWidth: 224);

    if (image == null) return null;

    setState(() {
      _image = File(image.path);
    });
    classifyImage(_image);
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
                'Detect Animals',
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
                              Image.asset('assets/farm_animals.png'),
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
                                'Prediction is: ${_output[0]['label']}',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 20.0),
                              )
                                  : Container(),
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
                                  'Take a photo',
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
                                  'Camera Roll',
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
