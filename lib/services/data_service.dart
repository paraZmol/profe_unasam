import 'package:profe_unasam/data/mock_data.dart';
import 'package:profe_unasam/models/app_notification.dart';
import 'package:profe_unasam/models/facultad_model.dart';
import 'package:profe_unasam/models/profesor_model.dart';
import 'package:profe_unasam/models/review_model.dart';
import 'package:profe_unasam/models/user_plan.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  late List<Profesor> _profesores;
  late List<Facultad> _facultades;
  UserPlan _plan = UserPlan.free;
  DateTime? _trialEndsAt;
  final Set<String> _followedProfesorIds = {};
  final Set<String> _followedCourses = {};
  final List<AppNotification> _notifications = [];

  DataService._internal() {
    _profesores = List.from(mockProfesores);
    _facultades = List.from(mockFacultades);
  }

  factory DataService() {
    return _instance;
  }

  // ======= Planes y acceso =======
  UserPlan getPlan() {
    if (_plan == UserPlan.trial && _trialEndsAt != null) {
      if (DateTime.now().isAfter(_trialEndsAt!)) {
        _plan = UserPlan.free;
        _trialEndsAt = null;
      }
    }
    return _plan;
  }

  bool get hasFullAccess {
    final plan = getPlan();
    return plan == UserPlan.premium || plan == UserPlan.trial;
  }

  int getTrialDaysRemaining() {
    if (_plan != UserPlan.trial || _trialEndsAt == null) return 0;
    final diff = _trialEndsAt!.difference(DateTime.now());
    return diff.inDays < 0 ? 0 : diff.inDays + 1;
  }

  void setPlanFree() {
    _plan = UserPlan.free;
    _trialEndsAt = null;
  }

  void startTrial({int days = 7}) {
    _plan = UserPlan.trial;
    _trialEndsAt = DateTime.now().add(Duration(days: days));
  }

  void setPlanPremium() {
    _plan = UserPlan.premium;
    _trialEndsAt = null;
  }

  // ======= Seguimiento =======
  bool isProfesorFollowed(String profesorId) {
    return _followedProfesorIds.contains(profesorId);
  }

  bool isCourseFollowed(String curso) {
    return _followedCourses.contains(curso.toLowerCase());
  }

  void toggleFollowProfesor(String profesorId) {
    if (isProfesorFollowed(profesorId)) {
      _followedProfesorIds.remove(profesorId);
    } else {
      _followedProfesorIds.add(profesorId);
    }
  }

  void toggleFollowCourse(String curso) {
    final key = curso.toLowerCase();
    if (isCourseFollowed(curso)) {
      _followedCourses.remove(key);
    } else {
      _followedCourses.add(key);
    }
  }

  // ======= Notificaciones =======
  List<AppNotification> getNotifications() => List.unmodifiable(_notifications);

  int getUnreadNotificationsCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  void markNotificationRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  void clearNotifications() {
    _notifications.clear();
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

    _crearNotificacionSiAplica(profesorActualizado, review);
  }

  void _crearNotificacionSiAplica(Profesor profesor, Review review) {
    final sigueProfesor = isProfesorFollowed(profesor.id);
    final sigueCurso = isCourseFollowed(profesor.curso);
    if (!sigueProfesor && !sigueCurso) return;

    final id = 'n${DateTime.now().millisecondsSinceEpoch}';
    final title = sigueProfesor
        ? 'Nueva reseña para ${profesor.nombre}'
        : 'Nueva reseña en ${profesor.curso}';
    final body =
        'Se publicó una reseña con ${review.puntuacion.toStringAsFixed(1)} estrellas.';

    _notifications.insert(
      0,
      AppNotification(
        id: id,
        title: title,
        body: body,
        createdAt: DateTime.now(),
      ),
    );
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
