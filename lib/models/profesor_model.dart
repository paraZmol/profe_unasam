import 'package:profe_unasam/models/review_model.dart';

class Profesor {
  final String id;
  final String nombre;
  final String curso;
  final String facultadId;
  final String escuelaId;
  final double calificacion;
  final String fotoUrl;
  final String? apodo; // opcional
  final List<Review> reviews;

  Profesor({
    required this.id,
    required this.nombre,
    required this.curso,
    required this.facultadId,
    required this.escuelaId,
    required this.calificacion,
    required this.fotoUrl,
    this.apodo,
    required this.reviews,
  });

  factory Profesor.fromJson(Map<String, dynamic> json) {
    return Profesor(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      curso: json['curso'] as String,
      facultadId: json['facultadId'] as String,
      escuelaId: json['escuelaId'] as String,
      calificacion: (json['calificacion'] as num).toDouble(),
      fotoUrl: json['fotoUrl'] as String,
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
      'curso': curso,
      'facultadId': facultadId,
      'escuelaId': escuelaId,
      'calificacion': calificacion,
      'fotoUrl': fotoUrl,
      'apodo': apodo,
      'reviews': reviews.map((r) => r.toJson()).toList(),
    };
  }
}
