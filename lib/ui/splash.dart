import 'dart:async';

import 'package:flutter/material.dart';

const String LoggedInKey = 'LoggedIn';

class Splash extends StatefulWidget {
  @override
  _SplashState createState() => _SplashState();
}

class _SplashState extends State<Splash> {

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final size = query.size;
    final itemWidth = size.width*0.4;
    final itemHeight = itemWidth * (size.width / size.height);
    return Scaffold(
      body: SafeArea(
        child: Stack(
            children:[
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset('assets/granja.jpg',
                    width: itemWidth,height: itemHeight,),
                ),
              ),
              Center(
                  child: Text("LA GRANJA DE MICHI",style: TextStyle(color:Theme.of(context).primaryColor ,fontSize: 24,fontWeight: FontWeight.w700),))
            ]
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Timer(const Duration(milliseconds: 2000), () {
      Navigator.pushReplacementNamed(
        context,
        '/auth',
      );
    });
  }
}