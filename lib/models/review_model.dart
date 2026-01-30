enum Dificultad { muyFacil, facil, normal, dificil, muyDificil }

enum OportunidadAprobacion {
  casioSeguroe,
  probable,
  cincuentaCincuenta,
  dificil,
}

class Review {
  final String id;
  final String? userId;
  final String userAlias;
  final String comentario;
  final double puntuacion;
  final DateTime fecha;
  final Dificultad dificultad;
  final OportunidadAprobacion oportunidadAprobacion;
  final String consejo;
  final List<String> metodosEnsenanza;

  Review({
    required this.id,
    this.userId,
    required this.userAlias,
    required this.comentario,
    required this.puntuacion,
    required this.fecha,
    required this.dificultad,
    required this.oportunidadAprobacion,
    required this.consejo,
    required this.metodosEnsenanza,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      userAlias: (json['userAlias'] as String?) ?? 'Anónimo',
      comentario: json['comentario'] as String,
      puntuacion: (json['puntuacion'] as num).toDouble(),
      fecha: DateTime.parse(json['fecha'] as String),
      dificultad: Dificultad.values.firstWhere(
        (e) => e.toString() == json['dificultad'],
        orElse: () => Dificultad.normal,
      ),
      oportunidadAprobacion: OportunidadAprobacion.values.firstWhere(
        (e) => e.toString() == json['oportunidadAprobacion'],
        orElse: () => OportunidadAprobacion.probable,
      ),
      consejo: json['consejo'] as String? ?? '',
      metodosEnsenanza: List<String>.from(
        json['metodosEnsenanza'] as List? ?? [],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userAlias': userAlias,
      'comentario': comentario,
      'puntuacion': puntuacion,
      'fecha': fecha.toIso8601String(),
      'dificultad': dificultad.toString(),
      'oportunidadAprobacion': oportunidadAprobacion.toString(),
      'consejo': consejo,
      'metodosEnsenanza': metodosEnsenanza,
    };
  }
}
