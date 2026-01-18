import 'package:flutter/material.dart';

import '../models/profesor_model.dart';
import '../screens/profesor_detail_screen.dart';

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
                // animacion entre pantallas
                tag: profesor.id,
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(profesor.fotoUrl),
                  onBackgroundImageError: (exception, stackTrace) {},
                  child: const Icon(Icons.person),
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
                    profesor.calificacion.toString(),
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
