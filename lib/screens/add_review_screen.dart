import 'package:flutter/material.dart';

import '../models/profesor_model.dart';
import '../models/review_model.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('CALIFICAR DOCENTE'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        // singlechildscrollview para que el teclado no tape el contenido
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // titulo del profesoir
            Text(
              '¿Que tal fue tu clase con ${widget.profesor.nombre}?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // seccion de estrellas
            const Text('SELECCIONA UNA PUNTUACION'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  // si el indice es menor al rating pintamos la estrella llena
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: index < _rating ? Colors.amber : Colors.grey[400],
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
            const Text('DEJA TU COMENTARIO'),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Escribe aqui tu experiencia con el profe...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // btn enviar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
