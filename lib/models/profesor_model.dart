import 'package:profe_unasam/models/review_model.dart';

class Profesor {
  final String id;
  final String nombre;
  final List<String> cursos;
  final String facultadId;
  final String escuelaId;
  final double calificacion;
  final String fotoUrl;
  final String? apodo; // opcional
  final List<Review> reviews;

  Profesor({
    required this.id,
    required this.nombre,
    required this.cursos,
    required this.facultadId,
    required this.escuelaId,
    required this.calificacion,
    required this.fotoUrl,
    this.apodo,
    required this.reviews,
  });

  factory Profesor.fromJson(Map<String, dynamic> json) {
    String readString(dynamic value, {String fallback = ''}) {
      if (value is String) {
        final trimmed = value.trim();
        return trimmed.isNotEmpty ? trimmed : fallback;
      }
      if (value == null) return fallback;
      final asString = value.toString().trim();
      return asString.isNotEmpty ? asString : fallback;
    }

    final cursosJson = json['cursos'];
    final legacyCurso = json['curso'];
    final cursos = cursosJson is List
        ? cursosJson.whereType<String>().toList()
        : legacyCurso is String && legacyCurso.isNotEmpty
        ? [legacyCurso]
        : <String>[];

    return Profesor(
      id: readString(json['id'], fallback: 'unknown'),
      nombre: readString(json['nombre'], fallback: 'Sin nombre'),
      cursos: cursos,
      facultadId: readString(json['facultadId']),
      escuelaId: readString(json['escuelaId']),
      calificacion: (json['calificacion'] as num?)?.toDouble() ?? 0.0,
      fotoUrl: readString(
        json['fotoUrl'],
        fallback: 'https://i.pravatar.cc/150?img=1',
      ),
      apodo: json['apodo'] as String?,
      reviews:
          (json['reviews'] as List<dynamic>?)
              ?.map((r) => Review.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'cursos': cursos,
      'facultadId': facultadId,
      'escuelaId': escuelaId,
      'calificacion': calificacion,
      'fotoUrl': fotoUrl,
      'apodo': apodo,
      'reviews': reviews.map((r) => r.toJson()).toList(),
    };
  }
}
