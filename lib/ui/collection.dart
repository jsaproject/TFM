import 'dart:async';

import 'package:animalspredictor/widget/navigation_drawer_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Collection extends StatefulWidget {
  @override
  _CollectionState createState() => _CollectionState();
}

class _CollectionState extends State<Collection> {
  final FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
  }

  Future<Map<String, int>> updateDataAnimals() async {
    String email = auth.currentUser.email;
    int numberDogs = 0;
    int numberHorse = 0;
    int numberElephant = 0;
    int numberButterfly = 0;
    int numberChicken = 0;
    int numberCat = 0;
    int numberCow = 0;
    int numberSheep = 0;
    int numberSpider = 0;
    int numberChipmunk = 0;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .get()
        .asStream()
        .forEach((element) {
      print(element.data());
      numberDogs = element.data()['Perro'];
      numberHorse = element.data()['Caballo'];
      numberElephant = element.data()['Elefante'];
      numberButterfly = element.data()['Mariposa'];
      numberChicken = element.data()['Gallina'];
      numberCat = element.data()['Gato'];
      numberCow = element.data()['Vaca'];
      numberSheep = element.data()['Oveja'];
      numberSpider = element.data()['Araña'];
      numberChipmunk = element.data()['Ardilla'];
    });

    return {
      'Perro': numberDogs,
      'Caballo': numberHorse,
      'Elefante': numberElephant,
      'Mariposa': numberButterfly,
      'Gallina': numberChicken,
      'Gato': numberCat,
      'Vaca': numberCow,
      'Oveja': numberSheep,
      'Araña': numberSpider,
      'Ardilla': numberChipmunk
    };
  }

  Widget page(AsyncSnapshot<Map<String, int>> snapshot) {
    int numberDogs = 0;
    int numberHorse = 0;
    int numberElephant = 0;
    int numberButterfly = 0;
    int numberChicken = 0;
    int numberCat = 0;
    int numberCow = 0;
    int numberSheep = 0;
    int numberSpider = 0;
    int numberChipmunk = 0;
    if(snapshot != null){
      numberDogs = snapshot.data['Perro'];
      numberHorse = snapshot.data['Caballo'];
      numberElephant = snapshot.data['Elefante'];
      numberButterfly = snapshot.data['Mariposa'];
      numberChicken = snapshot.data['Gallina'];
      numberCat = snapshot.data['Gato'];
      numberCow = snapshot.data['Vaca'];
      numberSheep = snapshot.data['Oveja'];
      numberSpider = snapshot.data['Araña'];
      numberChipmunk = snapshot.data['Ardilla'];
    }
    return Scaffold(
      drawer: NavigationDrawerWidget(),
      body: ListView(
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.arrow_drop_down_circle),
                  title: const Text('Perro'),
                  subtitle: Text(
                    'Coleccionados: ' + numberDogs.toString(),
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Greyhound divisively hello coldly wonderfully marginally far upon excluding.',
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Image.asset('assets/farm_animals.png'),
              ],
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.arrow_drop_down_circle),
                  title: const Text('Caballo'),
                  subtitle: Text(
                    'Coleccionados:' + numberHorse.toString(),
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Greyhound divisively hello coldly wonderfully marginally far upon excluding.',
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Image.asset('assets/farm_animals.png'),
              ],
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.arrow_drop_down_circle),
                  title: const Text('Elefante'),
                  subtitle: Text(
                    'Coleccionados:' + numberElephant.toString(),
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Greyhound divisively hello coldly wonderfully marginally far upon excluding.',
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Image.asset('assets/farm_animals.png'),
              ],
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.arrow_drop_down_circle),
                  title: const Text('Mariposa'),
                  subtitle: Text(
                    'Coleccionados:' + numberButterfly.toString(),
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Greyhound divisively hello coldly wonderfully marginally far upon excluding.',
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Image.asset('assets/farm_animals.png'),
              ],
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.arrow_drop_down_circle),
                  title: const Text('Gallina'),
                  subtitle: Text(
                    'Coleccionados:' + numberChicken.toString(),
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Greyhound divisively hello coldly wonderfully marginally far upon excluding.',
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Image.asset('assets/farm_animals.png'),
              ],
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.arrow_drop_down_circle),
                  title: const Text('Gato'),
                  subtitle: Text(
                    'Coleccionados:' + numberCat.toString(),
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Greyhound divisively hello coldly wonderfully marginally far upon excluding.',
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Image.asset('assets/farm_animals.png'),
              ],
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.arrow_drop_down_circle),
                  title: const Text('Vaca'),
                  subtitle: Text(
                    'Coleccionados:' + numberCow.toString(),
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Greyhound divisively hello coldly wonderfully marginally far upon excluding.',
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Image.asset('assets/farm_animals.png'),
              ],
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.arrow_drop_down_circle),
                  title: const Text('Oveja'),
                  subtitle: Text(
                    'Coleccionados:' + numberSheep.toString(),
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Greyhound divisively hello coldly wonderfully marginally far upon excluding.',
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Image.asset('assets/farm_animals.png'),
              ],
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.arrow_drop_down_circle),
                  title: const Text('Araña'),
                  subtitle: Text(
                    'Coleccionados:' + numberSpider.toString(),
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Greyhound divisively hello coldly wonderfully marginally far upon excluding.',
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Image.asset('assets/farm_animals.png'),
              ],
            ),
          ),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.arrow_drop_down_circle),
                  title: const Text('Ardilla'),
                  subtitle: Text(
                    'Coleccionados:' + numberChipmunk.toString(),
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Greyhound divisively hello coldly wonderfully marginally far upon excluding.',
                    style: TextStyle(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                Image.asset('assets/farm_animals.png'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget loadingScreen() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: CircularProgressIndicator(),
            ),
            Text("Please make sure that you are using wifi."),
          ],
        ),
      ),
    );
  }

  /// In case of error shows unrecoverable error screen.
  Widget errorScreen() {
    return Scaffold(
      body: Center(
        child: Text("Error cargando la información."),
      ),
    );
  }

  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: Theme.of(context).textTheme.headline2,
      textAlign: TextAlign.center,
      child: FutureBuilder<Map<String, int>>(
        future: updateDataAnimals(),
        // a previously-obtained Future<String> or null
        builder:
            (BuildContext context, AsyncSnapshot<Map<String, int>> snapshot) {
          if (snapshot.hasData) {
            return page(snapshot);
          } else if (snapshot.hasError) {
            if (auth.currentUser == null) {
              return page(null);
            } else {
              return errorScreen();
            }
          } else {
            return loadingScreen();
          }
        },
      ),
    );
  }
}
