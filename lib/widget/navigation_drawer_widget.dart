import 'package:animalspredictor/ui/collection.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../ui/home.dart';

class NavigationDrawerWidget extends StatelessWidget {
  final padding = EdgeInsets.symmetric(horizontal: 20);
  final FirebaseAuth auth = FirebaseAuth.instance;
  final urlImage =
      'https://image.freepik.com/free-vector/big-animals-set_1284-10911.jpg';

  @override
  Widget build(BuildContext context) {
    String nameApp = "Anónimo";
    String emailApp = "";
    if (auth.currentUser != null) {
      nameApp = auth.currentUser.email.split('@').first;
      emailApp = auth.currentUser.email;
    }
    return Drawer(
      child: Material(
        color: Color.fromRGBO(50, 75, 205, 1),
        child: auth.currentUser != null
            ? ListView(
                children: <Widget>[
                  buildHeader(
                    urlImage: urlImage,
                    name: nameApp,
                    email: emailApp,
                  ),
                  Container(
                    padding: padding,
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        buildMenuItem(
                          text: 'Predecir',
                          icon: Icons.image_search,
                          onClicked: () => selectedItem(context, 0),
                        ),
                        const SizedBox(height: 16),
                        buildMenuItem(
                          text: 'Colección',
                          icon: Icons.collections_bookmark,
                          onClicked: () => selectedItem(context, 1),
                        ),
                        const SizedBox(height: 16),
                        buildMenuItem(
                          text: 'Cerrar sesión',
                          icon: Icons.logout,
                          onClicked: () => selectedItem(context, 2),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView(
                children: <Widget>[
                  buildHeader(
                    urlImage: urlImage,
                    name: nameApp,
                    email: emailApp,
                  ),
                  Container(
                    padding: padding,
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        buildMenuItem(
                          text: 'Predecir',
                          icon: Icons.image_search,
                          onClicked: () => selectedItem(context, 0),
                        ),
                        const SizedBox(height: 16),
                        buildMenuItem(
                          text: 'Colección',
                          icon: Icons.collections_bookmark,
                          onClicked: () => selectedItem(context, 1),
                        ),
                        const SizedBox(height: 16),
                        buildMenuItem(
                          text: 'Iniciar sesión',
                          icon: Icons.login,
                          onClicked: () => selectedItem(context, 3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget buildHeader({
    String urlImage,
    String name,
    String email,
    VoidCallback onClicked,
  }) =>
      InkWell(
        onTap: onClicked,
        child: Container(
          padding: padding.add(EdgeInsets.symmetric(vertical: 40)),
          child: Row(
            children: [
              CircleAvatar(radius: 30, backgroundImage: NetworkImage(urlImage)),
              SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget buildMenuItem({
    String text,
    IconData icon,
    VoidCallback onClicked,
  }) {
    final color = Colors.white;
    final hoverColor = Colors.white70;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text, style: TextStyle(color: color)),
      hoverColor: hoverColor,
      onTap: onClicked,
    );
  }

  void selectedItem(BuildContext context, int index) {
    switch (index) {
      case 0:
        {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => Home()));
        }
        break;
      case 1:
        {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => Collection()));
        }
        break;
      case 2:
        {
          FirebaseAuth.instance.signOut();
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => AuthenticationWrapper()));
        }
        break;
      case 3:
        {
          FirebaseAuth.instance.signOut();
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => AuthenticationWrapper()));
        }
        break;
    }
  }
}
