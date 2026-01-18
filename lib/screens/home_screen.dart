// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:profe_unasam/data/mock_data.dart';
import 'package:profe_unasam/widgets/profesor_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profesores = mockProfesores;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profesores UNASAM'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: profesores.length,
        itemBuilder: (context, index) {
          final profesor = profesores[index];
          return ProfesorCard(profesor: profesor);
        },
      ),
    );
  }
}
