import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:profe_unasam/models/app_notification.dart';
import 'package:profe_unasam/models/comment_model.dart';
import 'package:profe_unasam/models/facultad_model.dart';
import 'package:profe_unasam/models/app_user.dart';
import 'package:profe_unasam/models/profesor_model.dart';
import 'package:profe_unasam/models/review_model.dart';
import 'package:profe_unasam/models/user_role.dart';
import 'package:profe_unasam/models/suggestion_model.dart';
import 'package:profe_unasam/models/review_flag.dart';
import 'package:profe_unasam/services/firestore_service.dart';

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
  final FirestoreService _firestoreService = FirestoreService();
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
    _profesores = [];
    _facultades = [];
    _initializeSampleUsers();
    _syncFromFirebaseUser(_auth.currentUser);
    refreshUsersFromFirestore().catchError((_) {});
    refreshFacultadesFromFirestore().catchError((_) {});
    refreshProfesoresFromFirestore().catchError((_) {});
    refreshReviewFlagsFromFirestore().catchError((_) {});
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

    UserRole? matchedRole;
    UserRole? matchedBaseRole;

    if (resolvedUser == null && email.isNotEmpty) {
      for (final entry in _allUsers.entries) {
        final existing = entry.value;
        if (existing.email.toLowerCase() == email.toLowerCase()) {
          resolvedUser = AppUser(
            id: user.uid,
            email: existing.email,
            alias: existing.alias,
          );
          matchedRole = _userRoles[entry.key];
          matchedBaseRole = _baseRoles[entry.key];
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
    if (matchedRole != null) {
      _userRoles[resolvedUser.id] = matchedRole;
    }
    if (matchedBaseRole != null) {
      _baseRoles[resolvedUser.id] = matchedBaseRole;
      if (matchedBaseRole == UserRole.admin ||
          matchedBaseRole == UserRole.moderator) {
        _usersPermittedToChangeRole.add(resolvedUser.id);
      }
    }
    _currentUser = resolvedUser;
    _role = _userRoles[resolvedUser.id] ?? UserRole.user;

    _syncFromFirestoreUser(
      user,
      aliasOverride: resolvedUser.alias,
    ).catchError((_) {});
  }

  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'admin';
      case UserRole.moderator:
        return 'moderator';
      case UserRole.user:
        return 'user';
    }
  }

  UserRole _roleFromString(String? value) {
    switch (value) {
      case 'admin':
        return UserRole.admin;
      case 'moderator':
        return UserRole.moderator;
      default:
        return UserRole.user;
    }
  }

  Future<void> _syncFromFirestoreUser(
    User user, {
    String? aliasOverride,
  }) async {
    final doc = await _firestoreService.getUserById(user.uid);
    final email = user.email ?? '';

    if (doc == null) {
      final alias = aliasOverride?.trim().isNotEmpty == true
          ? aliasOverride!.trim()
          : (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : _generateUniqueAlias(email.isNotEmpty ? email : 'user'));

      await _firestoreService.upsertUser(
        userId: user.uid,
        email: email,
        alias: alias,
        role: 'user',
        baseRole: 'user',
        canChangeRole: false,
      );

      _allUsers[user.uid] = AppUser(id: user.uid, email: email, alias: alias);
      _userRoles[user.uid] = UserRole.user;
      _baseRoles[user.uid] = UserRole.user;
      _currentUser = _allUsers[user.uid];
      _role = UserRole.user;
      return;
    }

    final alias = (doc['alias'] as String?)?.trim().isNotEmpty == true
        ? (doc['alias'] as String).trim()
        : (user.displayName?.trim().isNotEmpty == true
              ? user.displayName!.trim()
              : _generateUniqueAlias(email.isNotEmpty ? email : 'user'));

    final role = _roleFromString(doc['role'] as String?);
    final baseRole = _roleFromString(doc['baseRole'] as String?);
    final canChangeRole =
        doc['canChangeRole'] == true ||
        baseRole == UserRole.admin ||
        baseRole == UserRole.moderator;

    final resolvedUser = AppUser(id: user.uid, email: email, alias: alias);
    _allUsers[resolvedUser.id] = resolvedUser;
    _userRoles[resolvedUser.id] = role;
    _baseRoles[resolvedUser.id] = baseRole;
    if (canChangeRole) {
      _usersPermittedToChangeRole.add(resolvedUser.id);
    } else {
      _usersPermittedToChangeRole.remove(resolvedUser.id);
    }
    _currentUser = resolvedUser;
    _role = role;
    await refreshFollowsFromFirestore();
    await refreshNotificationsFromFirestore();
  }

  Future<void> refreshUsersFromFirestore() async {
    final users = await _firestoreService.listUsers();

    _allUsers.clear();
    _userRoles.clear();
    _baseRoles.clear();
    _usersPermittedToChangeRole.clear();

    for (final data in users) {
      final userId = data['id'] as String?;
      if (userId == null || userId.trim().isEmpty) continue;
      final email = (data['email'] as String?)?.trim() ?? '';
      final alias = (data['alias'] as String?)?.trim() ?? '';
      final role = _roleFromString(data['role'] as String?);
      final baseRole = _roleFromString(data['baseRole'] as String?);
      final canChangeRole =
          data['canChangeRole'] == true ||
          baseRole == UserRole.admin ||
          baseRole == UserRole.moderator;

      _allUsers[userId] = AppUser(id: userId, email: email, alias: alias);
      _userRoles[userId] = role;
      _baseRoles[userId] = baseRole;
      if (canChangeRole) {
        _usersPermittedToChangeRole.add(userId);
      }
    }

    if (_currentUser != null && _allUsers.containsKey(_currentUser!.id)) {
      _currentUser = _allUsers[_currentUser!.id];
      _role = _userRoles[_currentUser!.id] ?? UserRole.user;
    }
  }

  Future<void> refreshFollowsFromFirestore() async {
    if (_currentUser == null) return;
    final data = await _firestoreService.getUserFollows(_currentUser!.id);
    if (data == null) return;

    final profesorIds = (data['followedProfesorIds'] as List<dynamic>? ?? [])
        .whereType<String>()
        .toSet();
    final courses = (data['followedCourses'] as List<dynamic>? ?? [])
        .whereType<String>()
        .map((c) => c.toLowerCase())
        .toSet();

    _followedProfesorIds
      ..clear()
      ..addAll(profesorIds);
    _followedCourses
      ..clear()
      ..addAll(courses);
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

      await _firestoreService.upsertUser(
        userId: user.uid,
        email: emailTrimmed,
        alias: aliasTrimmed,
        role: _roleToString(UserRole.user),
        baseRole: _roleToString(UserRole.user),
        canChangeRole: false,
      );

      await _syncFromFirestoreUser(user, aliasOverride: aliasTrimmed);

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

      final user = credential.user;
      if (user != null) {
        await _syncFromFirestoreUser(user);
      } else {
        _syncFromFirebaseUser(user);
      }

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

  Future<void> updateProfile({String? alias, String? email}) async {
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

    await _firestoreService.updateUserProfile(
      userId: _currentUser!.id,
      email: newEmail,
      alias: newAlias,
    );
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
  String _suggestionTypeToString(SuggestionType type) {
    switch (type) {
      case SuggestionType.profesor:
        return 'profesor';
      case SuggestionType.facultad:
        return 'facultad';
      case SuggestionType.escuela:
        return 'escuela';
    }
  }

  SuggestionType _suggestionTypeFromString(String? value) {
    switch (value) {
      case 'profesor':
        return SuggestionType.profesor;
      case 'escuela':
        return SuggestionType.escuela;
      default:
        return SuggestionType.facultad;
    }
  }

  String _suggestionStatusToString(SuggestionStatus status) {
    switch (status) {
      case SuggestionStatus.pending:
        return 'pending';
      case SuggestionStatus.approved:
        return 'approved';
      case SuggestionStatus.rejected:
        return 'rejected';
    }
  }

  SuggestionStatus _suggestionStatusFromString(String? value) {
    switch (value) {
      case 'approved':
        return SuggestionStatus.approved;
      case 'rejected':
        return SuggestionStatus.rejected;
      default:
        return SuggestionStatus.pending;
    }
  }

  Suggestion _suggestionFromMap(Map<String, dynamic> data) {
    final createdAtRaw = data['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    return Suggestion(
      id: data['id'] as String,
      userId: data['userId'] as String? ?? '',
      userAlias: data['userAlias'] as String? ?? 'Anónimo',
      type: _suggestionTypeFromString(data['type'] as String?),
      status: _suggestionStatusFromString(data['status'] as String?),
      createdAt: createdAt,
      data: (data['data'] as Map<String, dynamic>? ?? {}),
    );
  }

  List<Suggestion> getSuggestions({SuggestionStatus? status}) {
    if (status == null) return List.unmodifiable(_suggestions);
    return _suggestions.where((s) => s.status == status).toList();
  }

  Future<void> refreshSuggestionsFromFirestore({
    SuggestionStatus? status,
  }) async {
    final statusValue = status != null
        ? _suggestionStatusToString(status)
        : null;
    final data = await _firestoreService.listSuggestions(status: statusValue);
    _suggestions
      ..clear()
      ..addAll(data.map(_suggestionFromMap));
  }

  Future<void> createSuggestion({
    required SuggestionType type,
    required Map<String, dynamic> data,
  }) async {
    if (_currentUser == null) {
      throw Exception('Debes iniciar sesión para sugerir');
    }

    _validateSuggestion(type, data);
    final id = await _firestoreService.addSuggestion({
      'userId': _currentUser!.id,
      'userAlias': _currentUser!.alias,
      'type': _suggestionTypeToString(type),
      'status': _suggestionStatusToString(SuggestionStatus.pending),
      'data': data,
    });

    _suggestions.add(
      Suggestion(
        id: id,
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
      final fotoUrl = (data['fotoUrl'] ?? '').toString().trim();

      if (name.length < 3) {
        throw Exception('Nombre de docente inválido');
      }

      if (fotoUrl.isEmpty) {
        throw Exception('La imagen del docente es requerida');
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

  Future<void> approveSuggestion(String suggestionId) async {
    if (isSensitiveActionsLocked) {
      throw Exception(sensitiveActionsLockMessage);
    }
    if (!canApproveSuggestions) {
      throw Exception('No tienes permisos para aprobar sugerencias');
    }
    final index = _suggestions.indexWhere((s) => s.id == suggestionId);
    if (index == -1) return;

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
      await agregarProfesor(profesor);
    } else if (suggestion.type == SuggestionType.facultad) {
      final facultad = Facultad(
        id:
            suggestion.data['id'] ??
            'f${DateTime.now().millisecondsSinceEpoch}',
        nombre: suggestion.data['nombre'] ?? '',
        escuelas: [],
      );
      await agregarFacultad(facultad);
    } else if (suggestion.type == SuggestionType.escuela) {
      final facultadId = suggestion.data['facultadId'] ?? '';
      if (facultadId.isEmpty) {
        throw Exception('La sugerencia de escuela no tiene facultad asignada');
      }
      final escuela = Escuela(
        id:
            suggestion.data['id'] ??
            'e${DateTime.now().millisecondsSinceEpoch}',
        nombre: suggestion.data['nombre'] ?? '',
        facultadId: facultadId,
      );
      await agregarEscuela(facultadId, escuela);
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

    await _firestoreService.updateSuggestionStatus(
      suggestionId: suggestion.id,
      status: _suggestionStatusToString(SuggestionStatus.approved),
    );
  }

  Future<void> rejectSuggestion(String suggestionId) async {
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

      await _firestoreService.updateSuggestionStatus(
        suggestionId: suggestion.id,
        status: _suggestionStatusToString(SuggestionStatus.rejected),
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

  Future<void> setUserRole(String userId, UserRole role) async {
    if (!_allUsers.containsKey(userId)) {
      throw Exception('Usuario no encontrado');
    }

    final isSelfChange = _currentUser?.id == userId;
    final canSelfChange = isSelfChange && canChangeOwnRole(role);

    // Si es cambio propio y está permitido por rol base, permitir sin exigir admin
    if (canSelfChange) {
      _userRoles[userId] = role;
      await _firestoreService.updateUserRole(
        userId: userId,
        role: _roleToString(role),
        baseRole: _roleToString(_baseRoles[userId] ?? role),
        canChangeRole: _usersPermittedToChangeRole.contains(userId),
      );
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

    await _firestoreService.updateUserRole(
      userId: userId,
      role: _roleToString(role),
      baseRole: _roleToString(_baseRoles[userId] ?? role),
      canChangeRole: _usersPermittedToChangeRole.contains(userId),
    );
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
  Future<void> promoteToModerator(String userId) async {
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

    await _firestoreService.updateUserRole(
      userId: userId,
      role: _roleToString(UserRole.moderator),
      baseRole: _roleToString(UserRole.moderator),
      canChangeRole: true,
    );
  }

  /// Promover moderador a administrador (solo admin, desde moderador)
  Future<void> promoteToAdmin(String userId) async {
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

    await _firestoreService.updateUserRole(
      userId: userId,
      role: _roleToString(UserRole.admin),
      baseRole: _roleToString(UserRole.admin),
      canChangeRole: true,
    );
  }

  /// Degradar moderador a usuario (solo admin)
  Future<void> demoteModerator(String userId) async {
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

    await _firestoreService.updateUserRole(
      userId: userId,
      role: _roleToString(UserRole.user),
      baseRole: _roleToString(UserRole.user),
      canChangeRole: false,
    );
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
    _persistFollows();
  }

  void toggleFollowCourse(String curso) {
    final key = curso.toLowerCase();
    if (isCourseFollowed(curso)) {
      _followedCourses.remove(key);
    } else {
      _followedCourses.add(key);
    }
    _persistFollows();
  }

  void followCourses(List<String> cursos) {
    for (final curso in cursos) {
      if (curso.trim().isEmpty) continue;
      _followedCourses.add(curso.toLowerCase());
    }
    _persistFollows();
  }

  void unfollowCourses(List<String> cursos) {
    for (final curso in cursos) {
      if (curso.trim().isEmpty) continue;
      _followedCourses.remove(curso.toLowerCase());
    }
    _persistFollows();
  }

  void _persistFollows() {
    if (_currentUser == null) return;
    _firestoreService.updateUserFollows(
      userId: _currentUser!.id,
      followedProfesorIds: _followedProfesorIds.toList(),
      followedCourses: _followedCourses.toList(),
    );
  }

  // ======= Notificaciones =======
  List<AppNotification> getNotifications() => List.unmodifiable(_notifications);

  Future<void> refreshNotificationsFromFirestore() async {
    if (_currentUser == null) return;
    final data = await _firestoreService.listNotifications(_currentUser!.id);
    _notifications
      ..clear()
      ..addAll(data.map(_notificationFromMap));
  }

  int getUnreadNotificationsCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  Future<void> markNotificationRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
    await _firestoreService.markNotificationRead(id);
  }

  Future<void> clearNotifications() async {
    _notifications.clear();
    if (_currentUser != null) {
      await _firestoreService.clearNotifications(_currentUser!.id);
    }
  }

  AppNotification _notificationFromMap(Map<String, dynamic> data) {
    final createdAtRaw = data['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    return AppNotification(
      id: data['id'] as String,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      createdAt: createdAt,
      isRead: data['isRead'] == true,
      actionType: data['actionType'] as String?,
      actionId: data['actionId'] as String?,
    );
  }

  Future<void> _pushNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
    if (_currentUser == null) return;
    await _firestoreService.addNotification(
      userId: _currentUser!.id,
      title: notification.title,
      body: notification.body,
      actionType: notification.actionType,
      actionId: notification.actionId,
    );
  }

  // obtener todos los profesores
  List<Profesor> getProfesores() => _profesores;

  // obtener todas las facultades
  List<Facultad> getFacultades() => _facultades;

  Future<void> refreshFacultadesFromFirestore() async {
    final data = await _firestoreService.listFacultades();
    _facultades = data.map((item) => Facultad.fromJson(item)).toList();
  }

  Future<void> refreshProfesoresFromFirestore() async {
    final data = await _firestoreService.listProfesores();
    _profesores = data.map((item) => Profesor.fromJson(item)).toList();
  }

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
  Future<void> agregarProfesor(Profesor profesor) async {
    if (isSensitiveActionsLocked) {
      throw Exception(sensitiveActionsLockMessage);
    }
    if (!canAddProfesor) {
      throw Exception(
        'Solo administradores o moderadores pueden agregar profesores',
      );
    }
    _profesores.add(profesor);
    await _firestoreService.upsertProfesor(profesor.toJson());
  }

  // actualizar profesor
  Future<void> actualizarProfesor(Profesor profesor) async {
    final index = _profesores.indexWhere((p) => p.id == profesor.id);
    if (index != -1) {
      _profesores[index] = profesor;
      await _firestoreService.upsertProfesor(profesor.toJson());
    }
  }

  // agregar resena a profesor
  Future<void> agregarResena(String profesorId, Review review) async {
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
      apodo: profesor.apodo,
      reviews: [...profesor.reviews, review],
    );

    _profesores[indice] = profesorActualizado;

    await _firestoreService.upsertProfesor(profesorActualizado.toJson());

    final curso = profesorActualizado.cursos.isNotEmpty
        ? profesorActualizado.cursos.first
        : '';
    await _firestoreService.guardar_calificacion(
      docente: profesorActualizado.nombre,
      curso: curso,
      puntaje: review.puntuacion,
    );

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

    _pushNotification(
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
  String _reviewFlagStatusToString(ReviewFlagStatus status) {
    switch (status) {
      case ReviewFlagStatus.pending:
        return 'pending';
      case ReviewFlagStatus.approved:
        return 'approved';
      case ReviewFlagStatus.rejected:
        return 'rejected';
    }
  }

  ReviewFlagStatus _reviewFlagStatusFromString(String? value) {
    switch (value) {
      case 'approved':
        return ReviewFlagStatus.approved;
      case 'rejected':
        return ReviewFlagStatus.rejected;
      default:
        return ReviewFlagStatus.pending;
    }
  }

  ReviewFlag _reviewFlagFromMap(Map<String, dynamic> data) {
    final createdAtRaw = data['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return ReviewFlag(
      id: data['id'] as String,
      reviewId: data['reviewId'] as String? ?? '',
      profesorId: data['profesorId'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      flaggedByUserId: data['flaggedByUserId'] as String? ?? '',
      createdAt: createdAt,
      moderatorApprovals: Set<String>.from(
        (data['moderatorApprovals'] as List<dynamic>? ?? []),
      ),
      adminApproved: data['adminApproved'] == true,
      status: _reviewFlagStatusFromString(data['status'] as String?),
    );
  }

  Future<void> refreshReviewFlagsFromFirestore({
    ReviewFlagStatus? status,
  }) async {
    final statusValue = status != null
        ? _reviewFlagStatusToString(status)
        : null;
    final data = await _firestoreService.listReviewFlags(status: statusValue);
    _reviewFlags
      ..clear()
      ..addAll(data.map(_reviewFlagFromMap));
  }

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

  Future<void> flagReview({
    required String reviewId,
    required String profesorId,
    required String reason,
  }) async {
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

    final id = await _firestoreService.addReviewFlag({
      'reviewId': reviewId,
      'profesorId': profesorId,
      'reason': reason.trim(),
      'flaggedByUserId': _currentUser!.id,
      'moderatorApprovals': <String>[],
      'adminApproved': false,
      'status': _reviewFlagStatusToString(ReviewFlagStatus.pending),
    });

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

    await _pushNotification(
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

  Future<void> approveReviewFlag(String flagId) async {
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

      await _pushNotification(
        AppNotification(
          id: 'n${DateTime.now().millisecondsSinceEpoch}',
          title: '[Moderación] Comentario ocultado',
          body: 'Se aprobó la ocultación de un comentario.',
          createdAt: DateTime.now(),
        ),
      );

      _notifyReviewAuthor(flag.reviewId, flag.reason);
    }

    final updatedFlag = flag.copyWith(
      moderatorApprovals: moderatorApprovals,
      adminApproved: adminApproved,
      status: status,
    );
    _reviewFlags[index] = updatedFlag;

    await _firestoreService.updateReviewFlag(
      flagId: updatedFlag.id,
      data: {
        'moderatorApprovals': updatedFlag.moderatorApprovals.toList(),
        'adminApproved': updatedFlag.adminApproved,
        'status': _reviewFlagStatusToString(updatedFlag.status),
      },
    );
  }

  Future<void> rejectReviewFlag(String flagId) async {
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
    final updatedFlag = flag.copyWith(status: ReviewFlagStatus.rejected);
    _reviewFlags[index] = updatedFlag;

    await _firestoreService.updateReviewFlag(
      flagId: updatedFlag.id,
      data: {'status': _reviewFlagStatusToString(updatedFlag.status)},
    );
  }

  void _notifyReviewAuthor(String reviewId, String reason) {
    final review = getReviewById(reviewId);
    if (review == null || review.userId == null) {
      return;
    }

    _pushNotification(
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
  Future<void> agregarFacultad(Facultad facultad) async {
    if (isSensitiveActionsLocked) {
      throw Exception(sensitiveActionsLockMessage);
    }
    if (!canManageFacultades) {
      throw Exception('No tienes permisos para administrar facultades');
    }
    _facultades.add(facultad);
    await _firestoreService.upsertFacultad(
      facultadId: facultad.id,
      nombre: facultad.nombre,
      escuelas: facultad.escuelas.map((e) => e.toJson()).toList(),
    );
  }

  // agregar escuela a facultad
  Future<void> agregarEscuela(String facultadId, Escuela escuela) async {
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
      await _firestoreService.addEscuelaToFacultad(
        facultadId: facultadId,
        escuela: escuela.toJson(),
      );
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

  Comment _commentFromMap(Map<String, dynamic> data) {
    final createdAtRaw = data['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }
    return Comment(
      id: data['id'] as String,
      userId: data['userId'] as String? ?? '',
      profesorId: data['profesorId'] as String? ?? '',
      texto: data['texto'] as String? ?? '',
      fecha: createdAt,
      esInapropiado: data['esInapropiado'] == true,
    );
  }

  Future<void> refreshCommentsFromFirestore({String? profesorId}) async {
    final data = await _firestoreService.listComments(profesorId: profesorId);
    _comments
      ..clear()
      ..addAll(data.map(_commentFromMap));
  }

  /// Crear un nuevo comentario
  Future<bool> createComment({
    required String profesorId,
    required String texto,
  }) async {
    // Solo usuarios (todos los roles) pueden comentar
    if (!canComment) {
      return false;
    }

    if (_currentUser == null) {
      return false;
    }

    final commentId = await _firestoreService.addComment({
      'userId': _currentUser!.id,
      'profesorId': profesorId,
      'texto': texto,
      'esInapropiado': false,
    });

    final comment = Comment(
      id: commentId,
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
