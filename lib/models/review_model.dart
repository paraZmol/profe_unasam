class Review {
  final String id;
  final String comentario;
  final double puntuacion;
  final DateTime fecha;

  Review({
    required this.id,
    required this.comentario,
    required this.puntuacion,
    required this.fecha,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      comentario: json['comentario'] as String,
      puntuacion: (json['puntuacion'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comentario': comentario,
      'puntuacion': puntuacion,
      'fecha': fecha.toIso8601String(),
    };
  }
}
