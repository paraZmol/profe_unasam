import 'review_model.dart';

class Profesor {
  final String id;
  final String nombre;
  final String curso;
  final double calificacion;
  final String fotoUrl;
  final List<Review> reviews; // comentarios de los esudiantes

  Profesor({
    required this.id,
    required this.nombre,
    required this.curso,
    required this.calificacion,
    required this.fotoUrl,
    required this.reviews,
  });
}
