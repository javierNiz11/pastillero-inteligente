import 'package:flutter/material.dart';
import 'home_screen.dart'; // Importamos la nueva pantalla de inicio

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pastillero Inteligente',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}
