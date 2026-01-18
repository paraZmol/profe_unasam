// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:profe_unasam/data/mock_data.dart';
import 'package:profe_unasam/widgets/profesor_card.dart';

class HomeScreen extends StatelessWidget {
  final Function(bool)? onThemeToggle;
  final bool isDarkMode;

  const HomeScreen({super.key, this.onThemeToggle, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    final profesores = mockProfesores;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profesores UNASAM'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              onThemeToggle?.call(!isDarkMode);
            },
          ),
        ],
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
