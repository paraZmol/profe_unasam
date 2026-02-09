import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> guardar_calificacion({
    required String docente,
    required String curso,
    required num puntaje,
  }) async {
    await _firestore.collection('calificaciones').add({
      'docente': docente.trim(),
      'curso': curso.trim(),
      'puntaje': puntaje,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Map<String, dynamic>>> leer_calificaciones() async {
    final snapshot = await _firestore
        .collection('calificaciones')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>?> getUserById(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  Future<void> upsertUser({
    required String userId,
    required String email,
    required String alias,
    required String role,
    required String baseRole,
    required bool canChangeRole,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'email': email,
      'alias': alias,
      'role': role,
      'baseRole': baseRole,
      'canChangeRole': canChangeRole,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
    required String baseRole,
    required bool canChangeRole,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'role': role,
      'baseRole': baseRole,
      'canChangeRole': canChangeRole,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserProfile({
    required String userId,
    required String email,
    required String alias,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'email': email,
      'alias': alias,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<Map<String, dynamic>>> listUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> listFacultades() async {
    final snapshot = await _firestore.collection('facultades').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<List<Map<String, dynamic>>> listProfesores() async {
    final snapshot = await _firestore.collection('profesores').get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> upsertFacultad({
    required String facultadId,
    required String nombre,
    required List<Map<String, dynamic>> escuelas,
  }) async {
    await _firestore.collection('facultades').doc(facultadId).set({
      'nombre': nombre,
      'escuelas': escuelas,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addEscuelaToFacultad({
    required String facultadId,
    required Map<String, dynamic> escuela,
  }) async {
    final doc = await _firestore.collection('facultades').doc(facultadId).get();
    final data = doc.data();
    final escuelas = (data?['escuelas'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();

    escuelas.add(escuela);

    await _firestore.collection('facultades').doc(facultadId).set({
      'escuelas': escuelas,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> upsertProfesor(Map<String, dynamic> profesor) async {
    final id = profesor['id'] as String?;
    if (id == null || id.trim().isEmpty) return;
    await _firestore.collection('profesores').doc(id).set({
      ...profesor,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> addSuggestion(Map<String, dynamic> data) async {
    final doc = await _firestore.collection('suggestions').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<List<Map<String, dynamic>>> listSuggestions({String? status}) async {
    Query<Map<String, dynamic>> query = _firestore.collection('suggestions');
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> updateSuggestionStatus({
    required String suggestionId,
    required String status,
  }) async {
    await _firestore.collection('suggestions').doc(suggestionId).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> addNotification({
    required String userId,
    required String title,
    required String body,
    String? actionType,
    String? actionId,
  }) async {
    final doc = await _firestore.collection('notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'actionType': actionType,
      'actionId': actionId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<List<Map<String, dynamic>>> listNotifications(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).set({
      'isRead': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clearNotifications(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<Map<String, dynamic>?> getUserFollows(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return null;
    final data = doc.data() ?? {};
    return {
      'followedProfesorIds': data['followedProfesorIds'] ?? [],
      'followedCourses': data['followedCourses'] ?? [],
    };
  }

  Future<void> updateUserFollows({
    required String userId,
    required List<String> followedProfesorIds,
    required List<String> followedCourses,
  }) async {
    await _firestore.collection('users').doc(userId).set({
      'followedProfesorIds': followedProfesorIds,
      'followedCourses': followedCourses,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> addComment(Map<String, dynamic> data) async {
    final doc = await _firestore.collection('comments').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<List<Map<String, dynamic>>> listComments({String? profesorId}) async {
    Query<Map<String, dynamic>> query = _firestore.collection('comments');
    if (profesorId != null) {
      query = query.where('profesorId', isEqualTo: profesorId);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> updateComment({
    required String commentId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection('comments').doc(commentId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<String> addReviewFlag(Map<String, dynamic> data) async {
    final doc = await _firestore.collection('review_flags').add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<List<Map<String, dynamic>>> listReviewFlags({String? status}) async {
    Query<Map<String, dynamic>> query = _firestore.collection('review_flags');
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> updateReviewFlag({
    required String flagId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection('review_flags').doc(flagId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getAppSettings() async {
    final doc = await _firestore.collection('app_settings').doc('public').get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
  }

  Future<void> updateAppSettings(Map<String, dynamic> data) async {
    await _firestore.collection('app_settings').doc('public').set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
