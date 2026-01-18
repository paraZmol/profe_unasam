import 'package:profe_unasam/data/mock_data.dart';
import 'package:profe_unasam/models/facultad_model.dart';
import 'package:profe_unasam/models/profesor_model.dart';
import 'package:profe_unasam/models/review_model.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  late List<Profesor> _profesores;
  late List<Facultad> _facultades;

  DataService._internal() {
    _profesores = List.from(mockProfesores);
    _facultades = List.from(mockFacultades);
  }

  factory DataService() {
    return _instance;
  }

  // obtener todos los profesores
  List<Profesor> getProfesores() => _profesores;

  // obtener todas las facultades
  List<Facultad> getFacultades() => _facultades;

  // obtener escuela por id
  Escuela? getEscuelaById(String escuelaId) {
    for (var facultad in _facultades) {
      for (var escuela in facultad.escuelas) {
        if (escuela.id == escuelaId) {
          return escuela;
        }
      }
    }
    return null;
  }

  // obtener facultad por id
  Facultad? getFacultadById(String facultadId) {
    try {
      return _facultades.firstWhere((f) => f.id == facultadId);
    } catch (e) {
      return null;
    }
  }

  // agregar nuevo profesor
  void agregarProfesor(Profesor profesor) {
    _profesores.add(profesor);
  }

  // actualizar profesor
  void actualizarProfesor(Profesor profesor) {
    final index = _profesores.indexWhere((p) => p.id == profesor.id);
    if (index != -1) {
      _profesores[index] = profesor;
    }
  }

  // agregar resena a profesor
  void agregarResena(String profesorId, Review review) {
    final profesor = _profesores.firstWhere((p) => p.id == profesorId);
    final indice = _profesores.indexOf(profesor);

    final profesorActualizado = Profesor(
      id: profesor.id,
      nombre: profesor.nombre,
      curso: profesor.curso,
      facultadId: profesor.facultadId,
      escuelaId: profesor.escuelaId,
      calificacion: _calcularCalificacion([...profesor.reviews, review]),
      fotoUrl: profesor.fotoUrl,
      reviews: [...profesor.reviews, review],
    );

    _profesores[indice] = profesorActualizado;
  }

  // calcular calificacion promedio
  double _calcularCalificacion(List<Review> reviews) {
    if (reviews.isEmpty) return 0.0;
    final suma = reviews.fold<double>(0.0, (s, r) => s + r.puntuacion);
    return suma / reviews.length;
  }

  // agregar nueva facultad
  void agregarFacultad(Facultad facultad) {
    _facultades.add(facultad);
  }

  // agregar escuela a facultad
  void agregarEscuela(String facultadId, Escuela escuela) {
    final facultad = getFacultadById(facultadId);
    if (facultad != null) {
      final indice = _facultades.indexOf(facultad);
      final facultadActualizada = Facultad(
        id: facultad.id,
        nombre: facultad.nombre,
        escuelas: [...facultad.escuelas, escuela],
      );
      _facultades[indice] = facultadActualizada;
    }
  }

  // obtener profesores por facultad
  List<Profesor> getProfesoresPorFacultad(String facultadId) {
    return _profesores.where((p) => p.facultadId == facultadId).toList();
  }

  // obtener profesores por escuela
  List<Profesor> getProfesoresPorEscuela(String escuelaId) {
    return _profesores.where((p) => p.escuelaId == escuelaId).toList();
  }

  // generar id unico
  String generarIdUnico(String prefijo) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$prefijo$timestamp';
  }
}
