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
            // foto grande
            Center(
              child: Hero(
                tag: profesor.id,
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

            // informacion principal
            Text(
              profesor.nombre,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              profesor.curso,
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const Divider(height: 40, indent: 20, endIndent: 20),

            // seccion de la calificacion
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
            const SizedBox(height: 24),

            // btn calificar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  // formulario de votacion
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Formulario de votación (Próximamente)'),
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
                  'CALIFICAR AL PROFESOR',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // seccion de comentarios
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Comentarios de Estudiantes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (profesor.reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Aún no hay comentarios para este profesor.'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: profesor.reviews.length,
                itemBuilder: (context, index) {
                  final review = profesor.reviews[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < review.puntuacion
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 16,
                                  );
                                }),
                              ),
                              Text(
                                '${review.fecha.day}/${review.fecha.month}/${review.fecha.year}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            review.comentario,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
