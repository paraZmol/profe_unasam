class Escuela {
  final String id;
  final String nombre;
  final String facultadId;

  Escuela({required this.id, required this.nombre, required this.facultadId});

  factory Escuela.fromJson(Map<String, dynamic> json) {
    String readString(dynamic value, {String fallback = ''}) {
      if (value is String) {
        final trimmed = value.trim();
        return trimmed.isNotEmpty ? trimmed : fallback;
      }
      if (value == null) return fallback;
      final asString = value.toString().trim();
      return asString.isNotEmpty ? asString : fallback;
    }

    return Escuela(
      id: readString(json['id'], fallback: 'unknown'),
      nombre: readString(json['nombre'], fallback: 'Sin nombre'),
      facultadId: readString(json['facultadId']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nombre': nombre, 'facultadId': facultadId};
  }
}

class Facultad {
  final String id;
  final String nombre;
  final List<Escuela> escuelas;

  Facultad({required this.id, required this.nombre, required this.escuelas});

  factory Facultad.fromJson(Map<String, dynamic> json) {
    String readString(dynamic value, {String fallback = ''}) {
      if (value is String) {
        final trimmed = value.trim();
        return trimmed.isNotEmpty ? trimmed : fallback;
      }
      if (value == null) return fallback;
      final asString = value.toString().trim();
      return asString.isNotEmpty ? asString : fallback;
    }

    return Facultad(
      id: readString(json['id'], fallback: 'unknown'),
      nombre: readString(json['nombre'], fallback: 'Sin nombre'),
      escuelas: (json['escuelas'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(Escuela.fromJson)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'escuelas': escuelas.map((e) => e.toJson()).toList(),
    };
  }
}
