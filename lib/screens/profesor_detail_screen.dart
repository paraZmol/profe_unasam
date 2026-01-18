import 'package:flutter/material.dart';

import 'package:profe_unasam/models/profesor_model.dart';
import 'package:profe_unasam/models/review_model.dart';
import 'package:profe_unasam/screens/add_review_screen.dart';
import 'package:profe_unasam/theme/app_theme.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(profesor.nombre)),
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
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  backgroundImage:
                      profesor.fotoUrl.isNotEmpty && profesor.fotoUrl != 'url'
                      ? NetworkImage(profesor.fotoUrl)
                      : null,
                  onBackgroundImageError: (_, __) {},
                  child: (profesor.fotoUrl.isEmpty || profesor.fotoUrl == 'url')
                      ? Icon(
                          Icons.person,
                          size: 80,
                          color: theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // informacion principal
            Text(profesor.nombre, style: theme.textTheme.displayMedium),
            Text(
              profesor.curso,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Divider(
              height: 40,
              indent: 20,
              endIndent: 20,
              color: theme.dividerColor,
            ),

            // seccion de la calificacion
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: AppTheme.accentAmber, size: 40),
                const SizedBox(width: 10),
                Text(
                  _computedRating().toStringAsFixed(1),
                  style: theme.textTheme.displayLarge,
                ),
              ],
            ),
            Text('Calificación General', style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),

            // btn calificar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    // formulario de votacion
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AddReviewScreen(profesor: profesor),
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
                  child: const Text(
                    'CALIFICAR AL PROFESOR',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (profesor.reviews.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'Aún no hay comentarios para este profesor.',
                  style: theme.textTheme.bodyMedium,
                ),
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
                                    color: AppTheme.accentAmber,
                                    size: 16,
                                  );
                                }),
                              ),
                              Text(
                                '${review.fecha.day}/${review.fecha.month}/${review.fecha.year}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            review.comentario,
                            style: theme.textTheme.bodyMedium,
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
