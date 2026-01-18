class Escuela {
  final String id;
  final String nombre;
  final String facultadId;

  Escuela({required this.id, required this.nombre, required this.facultadId});

  factory Escuela.fromJson(Map<String, dynamic> json) {
    return Escuela(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      facultadId: json['facultadId'] as String,
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
    return Facultad(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      escuelas: (json['escuelas'] as List<dynamic>)
          .map((e) => Escuela.fromJson(e as Map<String, dynamic>))
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
