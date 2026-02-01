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
}
