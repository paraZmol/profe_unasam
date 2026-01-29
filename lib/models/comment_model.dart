class Comment {
  final String id;
  final String userId; // ID del usuario que hizo el comentario
  final String profesorId; // ID del profesor
  final String texto;
  final DateTime fecha;
  bool esInapropiado; // Marcado por moderador como inapropiado

  Comment({
    required this.id,
    required this.userId,
    required this.profesorId,
    required this.texto,
    required this.fecha,
    this.esInapropiado = false,
  });

  Comment copyWith({
    String? id,
    String? userId,
    String? profesorId,
    String? texto,
    DateTime? fecha,
    bool? esInapropiado,
  }) {
    return Comment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      profesorId: profesorId ?? this.profesorId,
      texto: texto ?? this.texto,
      fecha: fecha ?? this.fecha,
      esInapropiado: esInapropiado ?? this.esInapropiado,
    );
  }
}
