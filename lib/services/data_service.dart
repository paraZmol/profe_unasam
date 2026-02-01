import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:profe_unasam/data/mock_data.dart';
import 'package:profe_unasam/models/app_notification.dart';
import 'package:profe_unasam/models/comment_model.dart';
import 'package:profe_unasam/models/facultad_model.dart';
import 'package:profe_unasam/models/app_user.dart';
import 'package:profe_unasam/models/profesor_model.dart';
import 'package:profe_unasam/models/review_model.dart';
import 'package:profe_unasam/models/user_role.dart';
import 'package:profe_unasam/models/suggestion_model.dart';
import 'package:profe_unasam/models/review_flag.dart';

class AuthResult {
  final bool success;
  final String? message;
  final String? code;

  const AuthResult._(this.success, {this.message, this.code});

  factory AuthResult.success() => const AuthResult._(true);

  factory AuthResult.failure({required String message, String? code}) {
    return AuthResult._(false, message: message, code: code);
  }
}

class DataService {
  static final DataService _instance = DataService._internal();
  late List<Profesor> _profesores;
  late List<Facultad> _facultades;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Set<String> _followedProfesorIds = {};
  final Set<String> _followedCourses = {};
  final List<AppNotification> _notifications = [];
  UserRole _role = UserRole.admin;
  AppUser? _currentUser;
  final List<Suggestion> _suggestions = [];
  final List<ReviewFlag> _reviewFlags = [];
  final Set<String> _hiddenReviewIds = {};
  final ValueNotifier<int> _moderationNotifier = ValueNotifier<int>(0);
  final Map<String, AppUser> _allUsers = {};
  final Map<String, UserRole> _userRoles = {}; // Roles por usuario
  final Map<String, UserRole> _baseRoles = {}; // Rol base/asignado por admin
  final Map<String, String> _publicAliases =
      {}; // Alias público para comentarios
  final Set<String> _usersPermittedToChangeRole =
      {}; // IDs que pueden cambiar rol
  final List<Comment> _comments = []; // Comentarios de usuarios

  DataService._internal() {
    _profesores = List.from(mockProfesores);
    _facultades = List.from(mockFacultades);
    _initializeSampleUsers();
    _syncFromFirebaseUser(_auth.currentUser);
  }

  void _initializeSampleUsers() {
    // Crear usuarios de prueba para demostración
    final adminUser = AppUser(
      id: 'admin_001',
      email: 'admin@docin.com',
      alias: 'Administrador',
    );
    final moderatorUser = AppUser(
      id: 'mod_001',
      email: 'moderador@docin.com',
      alias: 'Moderador',
    );

    _allUsers[adminUser.id] = adminUser;
    _allUsers[moderatorUser.id] = moderatorUser;

    _userRoles[adminUser.id] = UserRole.admin;
    _userRoles[moderatorUser.id] = UserRole.moderator;

    // Guardar rol base para usuarios especiales
    _baseRoles[adminUser.id] = UserRole.admin;
    _baseRoles[moderatorUser.id] = UserRole.moderator;

    // Estos usuarios pueden cambiar de rol
    _usersPermittedToChangeRole.add(adminUser.id);
    _usersPermittedToChangeRole.add(moderatorUser.id);
  }

  factory DataService() {
    return _instance;
  }

  // ======= Auth local =======
  bool get isLoggedIn => _auth.currentUser != null;

  AppUser? getCurrentUser() => _currentUser;

  void _syncFromFirebaseUser(User? user) {
    if (user == null) {
      _currentUser = null;
      _role = UserRole.user;
      return;
    }

    final email = user.email ?? '';
    AppUser? resolvedUser = _allUsers[user.uid];

    if (resolvedUser == null && email.isNotEmpty) {
      for (final existing in _allUsers.values) {
        if (existing.email.toLowerCase() == email.toLowerCase()) {
          resolvedUser = AppUser(
            id: user.uid,
            email: existing.email,
            alias: existing.alias,
          );
          break;
        }
      }
    }

    if (resolvedUser == null) {
      final displayName = user.displayName?.trim();
      final alias = (displayName != null && displayName.isNotEmpty)
          ? displayName
          : _generateUniqueAlias(email.isNotEmpty ? email : 'user');
      resolvedUser = AppUser(id: user.uid, email: email, alias: alias);
    }

    _allUsers[resolvedUser.id] = resolvedUser;
    _currentUser = resolvedUser;
    _role = _userRoles[resolvedUser.id] ?? UserRole.user;
  }

  String _generateUniqueAlias(String email) {
    // Extraer la parte antes del @
    final baseName = email.split('@')[0];

    // Generar números random del 1 al 8
    final random = Random();
    String alias;
    int attempts = 0;
    const maxAttempts = 20;

    do {
      final randomNum = random.nextInt(8) + 1; // 1 a 8
      alias = '$baseName$randomNum';
      attempts++;

      // Verificar si el alias ya existe
      final exists = _allUsers.values.any((user) => user.alias == alias);
      if (!exists) {
        return alias;
      }
    } while (attempts < maxAttempts);

    // Si aún hay colisión, usar timestamp
    return '$baseName${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Registrar un nuevo usuario con alias proporcionado
  Future<AuthResult> registerWithAlias({
    required String email,
    required String password,
    required String alias,
  }) async {
    final emailTrimmed = email.trim().toLowerCase();
    final aliasTrimmed = alias.trim();

    // Verificar si el alias ya existe localmente
    final aliasExists = _allUsers.values.any(
      (user) => user.alias.toLowerCase() == aliasTrimmed.toLowerCase(),
    );

    if (aliasExists) {
      return AuthResult.failure(message: 'Este alias ya está registrado');
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: emailTrimmed,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return AuthResult.failure(
          message: 'No se pudo crear la cuenta. Intenta de nuevo.',
        );
      }

      await user.updateDisplayName(aliasTrimmed);

      final newUser = AppUser(
        id: user.uid,
        email: emailTrimmed,
        alias: aliasTrimmed,
      );

      _allUsers[newUser.id] = newUser;
      _userRoles[newUser.id] = UserRole.user;
      _currentUser = newUser;
      _role = UserRole.user;

      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return AuthResult.failure(
            message: 'Este email ya está registrado',
            code: e.code,
          );
        case 'invalid-email':
          return AuthResult.failure(message: 'Correo inválido', code: e.code);
        case 'weak-password':
          return AuthResult.failure(
            message: 'La contraseña es muy débil',
            code: e.code,
          );
        default:
          return AuthResult.failure(
            message: 'No se pudo crear la cuenta. Intenta de nuevo.',
            code: e.code,
          );
      }
    } catch (_) {
      return AuthResult.failure(
        message: 'Ocurrió un error inesperado. Intenta de nuevo.',
      );
    }
  }

  /// Registrar un nuevo usuario (versión antigua - mantener para compatibilidad)
  Future<AuthResult> register({
    required String email,
    required String password,
  }) async {
    final emailTrimmed = email.trim().toLowerCase();
    final generatedAlias = _generateUniqueAlias(emailTrimmed);
    return registerWithAlias(
      email: emailTrimmed,
      password: password,
      alias: generatedAlias,
    );
  }

  /// Iniciar sesión con un usuario existente
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final emailTrimmed = email.trim().toLowerCase();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: emailTrimmed,
        password: password,
      );

      _syncFromFirebaseUser(credential.user);

      if (_currentUser == null) {
        return AuthResult.failure(
          message: 'No se pudo iniciar sesión. Intenta de nuevo.',
        );
      }

      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          return AuthResult.failure(
            message: 'Contraseña incorrecta',
            code: e.code,
          );
        case 'user-not-found':
          return AuthResult.failure(
            message: 'No existe una cuenta con ese correo',
            code: e.code,
          );
        case 'invalid-email':
          return AuthResult.failure(message: 'Correo inválido', code: e.code);
        case 'invalid-credential':
          return AuthResult.failure(
            message: 'Credenciales inválidas',
            code: e.code,
          );
        default:
          return AuthResult.failure(
            message: 'No se pudo iniciar sesión. Intenta de nuevo.',
            code: e.code,
          );
      }
    } catch (_) {
      return AuthResult.failure(
        message: 'Ocurrió un error inesperado. Intenta de nuevo.',
      );
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    _role = UserRole.user;
    _followedProfesorIds.clear();
    _followedCourses.clear();
    _notifications.clear();
  }

  void updateProfile({String? alias, String? email}) {
    if (_currentUser == null) return;

    final newEmail = email != null
        ? email.trim().toLowerCase()
        : _currentUser!.email;
    final newAlias = alias != null ? alias.trim() : _currentUser!.alias;

    // Si el email cambió, verificar que no esté duplicado
    if (newEmail != _currentUser!.email) {
      final emailExists = _allUsers.values.any(
        (user) =>
            user.id != _currentUser!.id && user.email.toLowerCase() == newEmail,
      );
      if (emailExists) {
        // Email ya existe, no permitir cambio
        return;
      }
    }

    final updatedUser = AppUser(
      id: _currentUser!.id,
      email: newEmail,
      alias: newAlias,
    );
    _currentUser = updatedUser;
    _allUsers[_currentUser!.id] = updatedUser;
  }

  // ======= Gestión de usuarios =======
  Map<String, AppUser> getAllUsers() => _allUsers;
  AppUser? getUserById(String userId) => _allUsers[userId];

  String? getPublicAlias(String userId) => _publicAliases[userId];

  bool hasPublicAlias(String userId) {
    final alias = _publicAliases[userId];
    return alias != null && alias.trim().isNotEmpty;
  }

  bool isAliasAvailable(String alias, {String? excludeUserId}) {
    final normalized = alias.trim().toLowerCase();
    if (normalized.isEmpty) return false;

    final aliasTakenByUser = _allUsers.values.any(
      (user) =>
          user.alias.toLowerCase() == normalized && user.id != excludeUserId,
    );
    if (aliasTakenByUser) return false;

    final aliasTakenByPublic = _publicAliases.entries.any(
      (entry) =>
          entry.value.toLowerCase() == normalized && entry.key != excludeUserId,
    );

    return !aliasTakenByPublic;
  }

  void setPublicAlias(String userId, String alias) {
    final trimmed = alias.trim();
    if (!isAliasAvailable(trimmed, excludeUserId: userId)) {
      throw Exception('El alias público ya está en uso');
    }
    _publicAliases[userId] = trimmed;
  }

  String getCommentAliasForCurrentUser() {
    if (_currentUser == null) {
      return 'Anónimo';
    }

    final userId = _currentUser!.id;
    final baseRole = _baseRoles[userId];
    if (baseRole == UserRole.admin || baseRole == UserRole.moderator) {
      final publicAlias = _publicAliases[userId];
      if (publicAlias != null && publicAlias.trim().isNotEmpty) {
        return publicAlias;
      }
    }

    return _currentUser!.alias;
  }

  void registerUser(AppUser user) {
    _allUsers[user.id] = user;
  }

  Profesor? getProfesorById(String profesorId) {
    try {
      return _profesores.firstWhere((p) => p.id == profesorId);
    } catch (_) {
      return null;
    }
  }

  Review? getReviewById(String reviewId) {
    for (final profesor in _profesores) {
      for (final review in profesor.reviews) {
        if (review.id == reviewId) {
          return review;
        }
      }
    }
    return null;
  }

  // ======= Sugerencias =======
  List<Suggestion> getSuggestions({SuggestionStatus? status}) {
    if (status == null) return List.unmodifiable(_suggestions);
    return _suggestions.where((s) => s.status == status).toList();
  }

  void createSuggestion({
    required SuggestionType type,
    required Map<String, dynamic> data,
  }) {
    if (_currentUser == null) {
      throw Exception('Debes iniciar sesión para sugerir');
    }

    _validateSuggestion(type, data);
    _suggestions.add(
      Suggestion(
        id: 's${DateTime.now().millisecondsSinceEpoch}',
        userId: _currentUser!.id,
        userAlias: _currentUser!.alias,
        type: type,
        status: SuggestionStatus.pending,
        createdAt: DateTime.now(),
        data: data,
      ),
    );
  }

  void _validateSuggestion(SuggestionType type, Map<String, dynamic> data) {
    String normalize(String value) => value.trim().toLowerCase();

    if (type == SuggestionType.profesor) {
      final name = normalize(data['nombre'] ?? '');
      final facultadId = (data['facultadId'] ?? '') as String;
      final escuelaId = (data['escuelaId'] ?? '') as String;

      if (name.length < 3) {
        throw Exception('Nombre de docente inválido');
      }

      final duplicateProfesor = _profesores.any((p) {
        final sameName = p.nombre.trim().toLowerCase() == name;
        if (!sameName) return false;
        if (facultadId.isNotEmpty && p.facultadId != facultadId) return false;
        if (escuelaId.isNotEmpty && p.escuelaId != escuelaId) return false;
        return true;
      });

      if (duplicateProfesor) {
        throw Exception('El docente ya existe');
      }

      final duplicateSuggestion = _suggestions.any((s) {
        if (s.status != SuggestionStatus.pending) return false;
        if (s.type != SuggestionType.profesor) return false;
        final sName = normalize(s.data['nombre'] ?? '');
        if (sName != name) return false;
        if (facultadId.isNotEmpty && s.data['facultadId'] != facultadId) {
          return false;
        }
        if (escuelaId.isNotEmpty && s.data['escuelaId'] != escuelaId) {
          return false;
        }
        return true;
      });

      if (duplicateSuggestion) {
        throw Exception('Ya existe una sugerencia pendiente para este docente');
      }
    }

    if (type == SuggestionType.facultad) {
      final name = normalize(data['nombre'] ?? '');
      if (name.length < 3) {
        throw Exception('Nombre de facultad inválido');
      }
      final exists = _facultades.any(
        (f) => f.nombre.trim().toLowerCase() == name,
      );
      if (exists) {
        throw Exception('La facultad ya existe');
      }
    }

    if (type == SuggestionType.escuela) {
      final name = normalize(data['nombre'] ?? '');
      final facultadId = (data['facultadId'] ?? '') as String;
      if (name.length < 3) {
        throw Exception('Nombre de escuela inválido');
      }
      if (facultadId.isEmpty) {
        throw Exception('Selecciona una facultad');
      }
      final facultad = getFacultadById(facultadId);
      if (facultad == null) {
        throw Exception('Facultad no encontrada');
      }
      final exists = facultad.escuelas.any(
        (e) => e.nombre.trim().toLowerCase() == name,
      );
      if (exists) {
        throw Exception('La escuela ya existe en esta facultad');
      }
    }
  }

  void approveSuggestion(String suggestionId) {
    if (isSensitiveActionsLocked) {
      throw Exception(sensitiveActionsLockMessage);
    }
    if (!canApproveSuggestions) {
      throw Exception('No tienes permisos para aprobar sugerencias');
    }
    final index = _suggestions.indexWhere((s) => s.id == suggestionId);
    if (index != -1) {
      final suggestion = _suggestions[index];
      if (suggestion.type == SuggestionType.profesor) {
        final cursosData = suggestion.data['cursos'];
        final cursoLegacy = suggestion.data['curso'];
        final cursos = cursosData is List
            ? cursosData.whereType<String>().toList()
            : cursoLegacy is String && cursoLegacy.isNotEmpty
            ? [cursoLegacy]
            : <String>[];
        final profesor = Profesor(
          id:
              suggestion.data['id'] ??
              'p${DateTime.now().millisecondsSinceEpoch}',
          nombre: suggestion.data['nombre'] ?? '',
          cursos: cursos,
          facultadId: suggestion.data['facultadId'] ?? '',
          escuelaId: suggestion.data['escuelaId'] ?? '',
          calificacion: 0.0,
          fotoUrl: suggestion.data['fotoUrl'] ?? '',
          apodo: suggestion.data['apodo'],
          reviews: [],
        );
        _profesores.add(profesor);
      } else if (suggestion.type == SuggestionType.facultad) {
        final facultad = Facultad(
          id:
              suggestion.data['id'] ??
              'f${DateTime.now().millisecondsSinceEpoch}',
          nombre: suggestion.data['nombre'] ?? '',
          escuelas: [],
        );
        _facultades.add(facultad);
      } else if (suggestion.type == SuggestionType.escuela) {
        final facultadId = suggestion.data['facultadId'] ?? '';
        if (facultadId.isEmpty) {
          throw Exception(
            'La sugerencia de escuela no tiene facultad asignada',
          );
        }
        final escuela = Escuela(
          id:
              suggestion.data['id'] ??
              'e${DateTime.now().millisecondsSinceEpoch}',
          nombre: suggestion.data['nombre'] ?? '',
          facultadId: facultadId,
        );
        agregarEscuela(facultadId, escuela);
      }
      _suggestions[index] = Suggestion(
        id: suggestion.id,
        userId: suggestion.userId,
        userAlias: suggestion.userAlias,
        type: suggestion.type,
        status: SuggestionStatus.approved,
        createdAt: suggestion.createdAt,
        data: suggestion.data,
      );
    }
  }

  void rejectSuggestion(String suggestionId) {
    if (isSensitiveActionsLocked) {
      throw Exception(sensitiveActionsLockMessage);
    }
    if (!canApproveSuggestions) {
      throw Exception('No tienes permisos para rechazar sugerencias');
    }
    final index = _suggestions.indexWhere((s) => s.id == suggestionId);
    if (index != -1) {
      final suggestion = _suggestions[index];
      _suggestions[index] = Suggestion(
        id: suggestion.id,
        userId: suggestion.userId,
        userAlias: suggestion.userAlias,
        type: suggestion.type,
        status: SuggestionStatus.rejected,
        createdAt: suggestion.createdAt,
        data: suggestion.data,
      );
    }
  }

  List<Suggestion> getPendingSuggestions() {
    return _suggestions
        .where((s) => s.status == SuggestionStatus.pending)
        .toList();
  }

  // ======= Roles =======
  UserRole getRole([String? userId]) {
    if (userId != null) {
      return _userRoles[userId] ?? UserRole.user;
    }
    return _role;
  }

  /// Obtener el rol base/asignado del usuario actual
  UserRole? getBaseRole() {
    if (_currentUser == null) {
      return null;
    }
    return _baseRoles[_currentUser!.id];
  }

  /// Verificar si el usuario actual puede cambiar su rol
  bool canUserChangeRole() {
    if (_currentUser == null) {
      return false;
    }
    return _usersPermittedToChangeRole.contains(_currentUser!.id);
  }

  /// Bloquear acciones sensibles si el rol activo no coincide con el rol base
  bool get isSensitiveActionsLocked {
    if (_currentUser == null) {
      return true;
    }
    final baseRole = _baseRoles[_currentUser!.id];
    if (baseRole == null) {
      return false;
    }
    return _role != baseRole;
  }

  String get sensitiveActionsLockMessage {
    if (_currentUser == null) {
      return 'Debes iniciar sesión para realizar esta acción';
    }
    final baseRole = _baseRoles[_currentUser!.id];
    if (baseRole == null) {
      return 'No tienes permisos para realizar esta acción';
    }
    return 'Acción bloqueada. Activa tu rol base (${baseRole.label}) desde tu perfil';
  }

  void setRoleInternal(UserRole role) {
    _role = role;
  }

  void setUserRole(String userId, UserRole role) {
    if (!_allUsers.containsKey(userId)) {
      throw Exception('Usuario no encontrado');
    }

    final isSelfChange = _currentUser?.id == userId;
    final canSelfChange = isSelfChange && canChangeOwnRole(role);

    // Si es cambio propio y está permitido por rol base, permitir sin exigir admin
    if (canSelfChange) {
      _userRoles[userId] = role;
      return;
    }

    // Solo admin puede asignar roles a otros usuarios
    if (_role != UserRole.admin) {
      throw Exception('Solo administradores pueden asignar roles');
    }

    final currentRole = _userRoles[userId] ?? UserRole.user;

    // Si se intenta promover a admin, el usuario debe ser moderador
    if (role == UserRole.admin && currentRole != UserRole.moderator) {
      throw Exception(
        'Solo los moderadores pueden ser promovidos a administradores',
      );
    }

    _userRoles[userId] = role;

    // Actualizar rol base y permisos de cambio para coherencia del flujo
    _baseRoles[userId] = role;
    if (role == UserRole.admin || role == UserRole.moderator) {
      _usersPermittedToChangeRole.add(userId);
    } else {
      _usersPermittedToChangeRole.remove(userId);
    }
  }

  bool get canManageFacultades =>
      _role == UserRole.admin || _role == UserRole.moderator;

  bool get canAddProfesor =>
      _role == UserRole.admin || _role == UserRole.moderator;

  // ======= Permisos por rol =======

  /// Usuario puede comentar/calificar profesores
  bool get canComment => _role == UserRole.user;

  /// Moderador NO puede editar profesores, solo usuarios pueden sugerir y admins/mods aprueban
  bool get canEditProfesor => _role == UserRole.admin;

  /// Moderador puede eliminar comentarios inapropiados
  bool get canDeleteComments =>
      _role == UserRole.moderator || _role == UserRole.admin;

  /// Moderador puede aprobar/rechazar sugerencias de profesores
  bool get canApproveSuggestions =>
      _role == UserRole.moderator || _role == UserRole.admin;

  bool get canModerateComments =>
      _role == UserRole.moderator || _role == UserRole.admin;

  ValueNotifier<int> get moderationNotifier => _moderationNotifier;

  /// Usuario solo usuario, Moderador puede cambiar entre moderador/usuario, Admin puede cambiar entre todos
  /// PERO solo si el usuario está en la lista permitida (admin y moderador originales)
  bool canChangeOwnRole(UserRole newRole) {
    // Primero verificar si el usuario actual tiene permiso para cambiar roles
    if (_currentUser == null ||
        !_usersPermittedToChangeRole.contains(_currentUser!.id)) {
      return false; // Usuario normal no puede cambiar
    }

    // Obtener el rol base del usuario (el rol que fue asignado originalmente)
    final baseRole = _baseRoles[_currentUser!.id];

    if (baseRole == UserRole.admin) {
      // Admin puede cambiar a cualquier rol
      return true;
    }
    if (baseRole == UserRole.moderator) {
      // Moderador solo puede cambiar entre moderador y usuario
      return newRole == UserRole.user || newRole == UserRole.moderator;
    }

    return false;
  }

  /// Obtener lista de moderadores actuales
  List<MapEntry<String, AppUser>> getModerators() {
    return _allUsers.entries
        .where((entry) => _userRoles[entry.key] == UserRole.moderator)
        .toList();
  }

  /// Promover usuario a moderador (solo admin)
  void promoteToModerator(String userId) {
    if (isSensitiveActionsLocked) {
      throw Exception(sensitiveActionsLockMessage);
    }
    if (_role != UserRole.admin) {
      throw Exception('Solo administradores pueden promover moderadores');
    }
    if (!_allUsers.containsKey(userId)) {
      throw Exception('Usuario no encontrado');
    }
    _userRoles[userId] = UserRole.moderator;
    _baseRoles[userId] = UserRole.moderator;
    _usersPermittedToChangeRole.add(userId);
  }

  /// Promover moderador a administrador (solo admin, desde moderador)
  void promoteToAdmin(String userId) {
    if (isSensitiveActionsLocked) {
      throw Exception(sensitiveActionsLockMessage);
    }
    if (_role != UserRole.admin) {
      throw Exception('Solo administradores pueden crear administradores');
    }
    if (!_allUsers.containsKey(userId)) {
      throw Exception('Usuario no encontrado');
    }
    final userRole = _userRoles[userId];
    if (userRole != UserRole.moderator) {
      throw Exception('Solo se pueden promover moderadores a administradores');
    }
    _userRoles[userId] = UserRole.admin;
    _baseRoles[userId] = UserRole.admin;
    _usersPermittedToChangeRole.add(userId);
  }

  /// Degradar moderador a usuario (solo admin)
  void demoteModerator(String userId) {
    if (isSensitiveActionsLocked) {
      throw Exception(sensitiveActionsLockMessage);
    }
    if (_role != UserRole.admin) {
      throw Exception('Solo administradores pueden degradar moderadores');
    }
    if (!_allUsers.containsKey(userId)) {
      throw Exception('Usuario no encontrado');
    }
    _userRoles[userId] = UserRole.user;
    _baseRoles[userId] = UserRole.user;
    _usersPermittedToChangeRole.remove(userId);
  }

  // ======= Seguimiento =======
  bool isProfesorFollowed(String profesorId) {
    return _followedProfesorIds.contains(profesorId);
  }

  bool isCourseFollowed(String curso) {
    return _followedCourses.contains(curso.toLowerCase());
  }

  bool areAnyCoursesFollowed(List<String> cursos) {
    return cursos.any(isCourseFollowed);
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

  void followCourses(List<String> cursos) {
    for (final curso in cursos) {
      if (curso.trim().isEmpty) continue;
      _followedCourses.add(curso.toLowerCase());
    }
  }

  void unfollowCourses(List<String> cursos) {
    for (final curso in cursos) {
      if (curso.trim().isEmpty) continue;
      _followedCourses.remove(curso.toLowerCase());
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
    if (isSensitiveActionsLocked) {
      throw Exception(sensitiveActionsLockMessage);
    }
    if (!canAddProfesor) {
      throw Exception(
        'Solo administradores o moderadores pueden agregar profesores',
      );
    }
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
    if (!canComment) {
      throw Exception('Debes cambiar tu rol a Usuario para comentar');
    }
    final profesor = _profesores.firstWhere((p) => p.id == profesorId);
    final indice = _profesores.indexOf(profesor);

    final profesorActualizado = Profesor(
      id: profesor.id,
      nombre: profesor.nombre,
      cursos: profesor.cursos,
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
    final sigueCurso = areAnyCoursesFollowed(profesor.cursos);
    if (!sigueProfesor && !sigueCurso) return;

    final primaryCourse = _getPrimaryCourse(profesor);
    final id = 'n${DateTime.now().millisecondsSinceEpoch}';
    final title = sigueProfesor
        ? 'Nueva reseña para ${profesor.nombre}'
        : 'Nueva reseña en $primaryCourse';
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

  String _getPrimaryCourse(Profesor profesor) {
    if (profesor.cursos.isEmpty) {
      return 'un curso';
    }
    if (profesor.cursos.length == 1) {
      return profesor.cursos.first;
    }
    return '${profesor.cursos.first} y otros';
  }

  // ======= Moderación de comentarios (reviews) =======
  bool isReviewHidden(String reviewId) => _hiddenReviewIds.contains(reviewId);

  ReviewFlag? getReviewFlagByReviewId(String reviewId) {
    try {
      return _reviewFlags.lastWhere((f) => f.reviewId == reviewId);
    } catch (_) {
      return null;
    }
  }

  List<ReviewFlag> getPendingReviewFlags() {
    return _reviewFlags
        .where((f) => f.status == ReviewFlagStatus.pending)
        .toList();
  }

  void flagReview({
    required String reviewId,
    required String profesorId,
    required String reason,
  }) {
    if (isSensitiveActionsLocked) {
      throw Exception(sensitiveActionsLockMessage);
    }
    if (!canModerateComments) {
      throw Exception('Solo moderadores o administradores pueden marcar');
    }
    if (reason.trim().length < 5) {
      throw Exception('El motivo debe tener al menos 5 caracteres');
    }
    if (_currentUser == null) {
      throw Exception('Debes iniciar sesión');
    }

    final existingPending = _reviewFlags.any(
      (f) => f.reviewId == reviewId && f.status == ReviewFlagStatus.pending,
    );
    if (existingPending) {
      throw Exception('Este comentario ya está en revisión');
    }

    final id = 'rf${DateTime.now().millisecondsSinceEpoch}';
    _reviewFlags.add(
      ReviewFlag(
        id: id,
        reviewId: reviewId,
        profesorId: profesorId,
        reason: reason.trim(),
        flaggedByUserId: _currentUser!.id,
        createdAt: DateTime.now(),
        moderatorApprovals: <String>{},
        adminApproved: false,
        status: ReviewFlagStatus.pending,
      ),
    );

    _notifications.insert(
      0,
      AppNotification(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        title: '[Moderación] Comentario marcado',
        body: 'Se marcó un comentario para revisión.',
        createdAt: DateTime.now(),
        actionType: 'review_flag',
        actionId: id,
      ),
    );
  }

  void approveReviewFlag(String flagId) {
    if (isSensitiveActionsLocked) {
      throw Exception(sensitiveActionsLockMessage);
    }
    if (!canModerateComments) {
      throw Exception('Solo moderadores o administradores pueden aprobar');
    }
    if (_currentUser == null) {
      throw Exception('Debes iniciar sesión');
    }

    final index = _reviewFlags.indexWhere((f) => f.id == flagId);
    if (index == -1) {
      throw Exception('Registro de revisión no encontrado');
    }

    final flag = _reviewFlags[index];
    if (flag.status != ReviewFlagStatus.pending) {
      return;
    }

    var moderatorApprovals = Set<String>.from(flag.moderatorApprovals);
    var adminApproved = flag.adminApproved;

    if (_role == UserRole.admin) {
      adminApproved = true;
    } else if (_role == UserRole.moderator) {
      moderatorApprovals.add(_currentUser!.id);
    }

    var status = flag.status;
    if (adminApproved && moderatorApprovals.isNotEmpty) {
      status = ReviewFlagStatus.approved;
      _hiddenReviewIds.add(flag.reviewId);
      _moderationNotifier.value++;

      _notifications.insert(
        0,
        AppNotification(
          id: 'n${DateTime.now().millisecondsSinceEpoch}',
          title: '[Moderación] Comentario ocultado',
          body: 'Se aprobó la ocultación de un comentario.',
          createdAt: DateTime.now(),
        ),
      );

      _notifyReviewAuthor(flag.reviewId, flag.reason);
    }

    _reviewFlags[index] = flag.copyWith(
      moderatorApprovals: moderatorApprovals,
      adminApproved: adminApproved,
      status: status,
    );
  }

  void rejectReviewFlag(String flagId) {
    if (isSensitiveActionsLocked) {
      throw Exception(sensitiveActionsLockMessage);
    }
    if (!canModerateComments) {
      throw Exception('Solo moderadores o administradores pueden rechazar');
    }
    final index = _reviewFlags.indexWhere((f) => f.id == flagId);
    if (index == -1) {
      throw Exception('Registro de revisión no encontrado');
    }
    final flag = _reviewFlags[index];
    _reviewFlags[index] = flag.copyWith(status: ReviewFlagStatus.rejected);
  }

  void _notifyReviewAuthor(String reviewId, String reason) {
    final review = getReviewById(reviewId);
    if (review == null || review.userId == null) {
      return;
    }

    _notifications.insert(
      0,
      AppNotification(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        title: 'Tu comentario fue ocultado',
        body: 'Motivo: $reason',
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
    if (isSensitiveActionsLocked) {
      throw Exception(sensitiveActionsLockMessage);
    }
    if (!canManageFacultades) {
      throw Exception('No tienes permisos para administrar facultades');
    }
    _facultades.add(facultad);
  }

  // agregar escuela a facultad
  void agregarEscuela(String facultadId, Escuela escuela) {
    if (isSensitiveActionsLocked) {
      throw Exception(sensitiveActionsLockMessage);
    }
    if (!canManageFacultades) {
      throw Exception('No tienes permisos para administrar facultades');
    }
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

  // ======= Comentarios =======

  /// Crear un nuevo comentario
  bool createComment({required String profesorId, required String texto}) {
    // Solo usuarios (todos los roles) pueden comentar
    if (!canComment) {
      return false;
    }

    if (_currentUser == null) {
      return false;
    }

    final comment = Comment(
      id: generarIdUnico('comment_'),
      userId: _currentUser!.id,
      profesorId: profesorId,
      texto: texto,
      fecha: DateTime.now(),
      esInapropiado: false,
    );

    _comments.add(comment);
    return true;
  }

  /// Obtener comentarios de un profesor
  List<Comment> getCommentsByProfesor(String profesorId) {
    return _comments
        .where((c) => c.profesorId == profesorId && !c.esInapropiado)
        .toList();
  }

  /// Obtener todos los comentarios (incluyendo inapropiados) - solo para mods
  List<Comment> getAllComments() {
    if (isSensitiveActionsLocked) {
      throw Exception(sensitiveActionsLockMessage);
    }
    if (!canDeleteComments) {
      throw Exception('Solo moderadores pueden ver todos los comentarios');
    }
    return List.unmodifiable(_comments);
  }

  /// Marcar comentario como inapropiado (solo moderadores)
  bool markCommentAsInappropriate(String commentId) {
    if (isSensitiveActionsLocked) {
      return false;
    }
    if (!canDeleteComments) {
      return false;
    }

    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) {
      return false;
    }

    _comments[index] = _comments[index].copyWith(esInapropiado: true);
    return true;
  }

  /// Eliminar comentario permanentemente (solo admin)
  bool deleteComment(String commentId) {
    if (isSensitiveActionsLocked) {
      return false;
    }
    if (_role != UserRole.admin) {
      return false;
    }

    final index = _comments.indexWhere((c) => c.id == commentId);
    if (index == -1) {
      return false;
    }

    _comments.removeAt(index);
    return true;
  }
}
