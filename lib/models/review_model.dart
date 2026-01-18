class Review {
  final String id;
  final String comentario;
  final double puntuacion; // estrellas de cailificacion
  final DateTime fecha;

  Review({
    required this.id,
    required this.comentario,
    required this.puntuacion,
    required this.fecha,
  });
}
