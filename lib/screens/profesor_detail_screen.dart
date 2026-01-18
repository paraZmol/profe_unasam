import 'package:flutter/material.dart';

import '../models/profesor_model.dart';

class ProfesorDetailScreen extends StatelessWidget {
  final Profesor profesor;

  const ProfesorDetailScreen({super.key, required this.profesor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(profesor.nombre),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            //foto grande
            Center(
              child: Hero(
                tag: profesor.id, // animacion fluida - despues
                child: CircleAvatar(
                  radius: 80,
                  backgroundImage: NetworkImage(profesor.fotoUrl),
                  onBackgroundImageError: (_, __) {},
                  child: profesor.fotoUrl == 'url' || profesor.fotoUrl.isEmpty
                      ? const Icon(Icons.person, size: 80)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),

            //informacion principal
            Text(
              profesor.nombre,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              profesor.curso,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const Divider(height: 40, indent: 20, endIndent: 20),

            //seccion de la calificacion
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 40),
                const SizedBox(width: 10),
                Text(
                  '${profesor.calificacion}',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Text(
              'Calificación General',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),

            //bton calificar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  // para el proximo hito 8: formulario de botacion
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Formulario de votacion (proximamente)'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Calificar al profesor',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
