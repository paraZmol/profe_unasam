import 'package:flutter/material.dart';

import 'package:profe_unasam/models/profesor_model.dart';
import 'package:profe_unasam/screens/profesor_detail_screen.dart';

class ProfesorCard extends StatelessWidget {
  final Profesor profesor;

  const ProfesorCard({super.key, required this.profesor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      clipBehavior: Clip.antiAlias, // para que el efecto respete bordes
      child: InkWell(
        // para detectar el toque
        onTap: () {
          // navegacion
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfesorDetailScreen(profesor: profesor),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Hero(
                tag: profesor.id,
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      profesor.fotoUrl.isNotEmpty && profesor.fotoUrl != 'url'
                      ? NetworkImage(profesor.fotoUrl)
                      : null,
                  onBackgroundImageError: (exception, stackTrace) {},
                  child: (profesor.fotoUrl.isEmpty || profesor.fotoUrl == 'url')
                      ? const Icon(Icons.person)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profesor.nombre,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profesor.curso,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  const Text(
                    'Calificación',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    profesor.calificacion.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
