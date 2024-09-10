import 'package:flutter/material.dart';
import 'splash_screen.dart'; // Importera splash screen

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pengu the game',
      home: SplashScreen(), // Starta med SplashScreen
    );
  }
}
