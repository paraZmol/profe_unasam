// lib/models/profesor_model.dart

class Profesor {
  final String id;
  final String nombre;
  final String curso;
  final double calificacion;
  final String fotoUrl;

  Profesor({
    required this.id,
    required this.nombre,
    required this.curso,
    required this.calificacion,
    required this.fotoUrl,
  });
}
