import 'package:flutter/material.dart';

import 'package:profe_unasam/models/profesor_model.dart';
import 'package:profe_unasam/models/review_model.dart';
import 'package:profe_unasam/theme/app_theme.dart';

class AddReviewScreen extends StatefulWidget {
  final Profesor profesor;

  const AddReviewScreen({super.key, required this.profesor});

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  // var de estaod
  double _rating = 3.0; // valor inicial
  final _commentController = TextEditingController();

  @override
  void dispose() {
    // liberamos el controlador cuando el widget se destruye para evitar fugas de memoria
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('CALIFICAR DOCENTE')),
      body: SingleChildScrollView(
        // singlechildscrollview para que el teclado no tape el contenido
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // titulo del profesoir
            Text(
              '¿Que tal fue tu clase con ${widget.profesor.nombre}?',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            // seccion de estrellas
            Text(
              'SELECCIONA UNA PUNTUACION',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  // si el indice es menor al rating pintamos la estrella llena
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: index < _rating
                        ? AppTheme.accentAmber
                        : theme.disabledColor,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 20),

            // seccion de comentario
            Text(
              'DEJA TU COMENTARIO',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Escribe aqui tu experiencia con el profe...',
                border: theme.inputDecorationTheme.border,
                enabledBorder: theme.inputDecorationTheme.enabledBorder,
                focusedBorder: theme.inputDecorationTheme.focusedBorder,
                filled: theme.inputDecorationTheme.filled,
                fillColor: theme.inputDecorationTheme.fillColor,
                contentPadding: theme.inputDecorationTheme.contentPadding,
              ),
            ),
            const SizedBox(height: 30),

            // btn enviar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // validacion en caso de comentario vacio
                  if (_commentController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('POR FAVOR ESCRIBE UN COMENTARIO'),
                      ),
                    );
                    return;
                  }

                  // creamos el objeto review con los datos recolectados
                  final newReview = Review(
                    id: DateTime.now()
                        .toString(), // generamos un id temporal unico
                    comentario: _commentController.text,
                    puntuacion: _rating,
                    fecha: DateTime.now(),
                  );

                  // cerramos la pantalla y devolvemos el objeto al detalle del profesor
                  Navigator.pop(context, newReview);
                },
                child: const Text(
                  'ENVIAR CALIFICACION',
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
