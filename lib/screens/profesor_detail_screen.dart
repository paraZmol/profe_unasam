import 'package:flutter/material.dart';

import 'package:profe_unasam/models/profesor_model.dart';
import 'package:profe_unasam/models/review_model.dart';
import 'package:profe_unasam/screens/add_review_screen.dart';

class ProfesorDetailScreen extends StatefulWidget {
  final Profesor profesor;

  const ProfesorDetailScreen({super.key, required this.profesor});

  @override
  State<ProfesorDetailScreen> createState() => _ProfesorDetailScreenState();
}

class _ProfesorDetailScreenState extends State<ProfesorDetailScreen> {
  double _computedRating() {
    final reviews = widget.profesor.reviews;
    if (reviews.isEmpty) return widget.profesor.calificacion;
    final total = reviews.fold<double>(0.0, (s, r) => s + r.puntuacion);
    return total / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final profesor = widget.profesor;
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
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      profesor.fotoUrl.isNotEmpty && profesor.fotoUrl != 'url'
                      ? NetworkImage(profesor.fotoUrl)
                      : null,
                  onBackgroundImageError: (_, __) {},
                  child: (profesor.fotoUrl.isEmpty || profesor.fotoUrl == 'url')
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
                  _computedRating().toStringAsFixed(1),
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
                onPressed: () async {
                  // formulario de votacion
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddReviewScreen(profesor: profesor),
                    ),
                  );
                  // en caso se envia una receña mostramos un mensaje
                  if (result != null && result is Review) {
                    // agregamos la reseña a la lista y refrescamos la UI
                    setState(() {
                      profesor.reviews.insert(0, result);
                    });

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('GRACIAS POR TU CALIFICACION'),
                        ),
                      );
                    }
                  }
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
            const SizedBox(height: 16),

            if (profesor.reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Aún no hay comentarios para este profesor.'),
              )
            else
              ListView.builder(
                shrinkWrap:
                    true, // permite que el listview viva dentro de un scrollview
                physics:
                    const NeverScrollableScrollPhysics(), // evita conflictos de scroll
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
