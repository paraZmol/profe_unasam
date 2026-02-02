import 'package:cloud_firestore/cloud_firestore.dart';

class DbSeeder {
  DbSeeder({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> seed() async {
    final batch = _firestore.batch();

    final users = _firestore.collection('users');
    batch.set(users.doc('admin_docin'), {
      'email': 'admin@docin.com',
      'role': 'admin',
      'alias': 'Admin Supremo',
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(users.doc('moderator_docin'), {
      'email': 'moderador@docin.com',
      'role': 'moderator',
      'alias': 'El Vigilante',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final facultades = _firestore.collection('facultades');
    batch.set(facultades.doc('facultad_ciencias'), {
      'nombre': 'Facultad de Ciencias',
      'escuelas': [
        {'id': 'esc_sistemas', 'nombre': 'Sistemas'},
        {'id': 'esc_estadistica', 'nombre': 'Estadística'},
      ],
    });
    batch.set(facultades.doc('facultad_ambiente'), {
      'nombre': 'Facultad de Ambiente',
      'escuelas': [
        {'id': 'esc_sanitaria', 'nombre': 'Sanitaria'},
        {'id': 'esc_ambiental', 'nombre': 'Ambiental'},
      ],
    });
    batch.set(facultades.doc('facultad_derecho'), {
      'nombre': 'Facultad de Derecho',
      'escuelas': [
        {'id': 'esc_derecho', 'nombre': 'Derecho'},
      ],
    });

    final profesores = _firestore.collection('profesores');
    batch.set(profesores.doc('prof_carlos'), {
      'nombre': 'Ing. Carlos Pérez',
      'apodo': 'Terminator',
      'cursos': ['Programación', 'Estructuras'],
      'facultadId': 'facultad_ciencias',
      'escuelaId': 'esc_sistemas',
      'calificacion': 3.5,
    });
    batch.set(profesores.doc('prof_ana'), {
      'nombre': 'Lic. Ana Gómez',
      'apodo': 'La Mami',
      'cursos': ['Matemática I'],
      'facultadId': 'facultad_ciencias',
      'escuelaId': 'esc_sistemas',
      'calificacion': 4.8,
    });
    batch.set(profesores.doc('prof_maria'), {
      'nombre': 'Dra. María Sánchez',
      'cursos': ['Penal', 'Constitucional'],
      'facultadId': 'facultad_derecho',
      'escuelaId': 'esc_derecho',
      'calificacion': 3.9,
    });

    final notifications = _firestore.collection('notifications');
    batch.set(notifications.doc('notif_1'), {
      'userId': 'admin_docin',
      'title': 'Bienvenido',
      'body': 'Sistema inicializado',
      'isRead': false,
    });

    final suggestions = _firestore.collection('suggestions');
    batch.set(suggestions.doc('sugg_1'), {
      'userId': 'user_random',
      'type': 'profesor',
      'status': 'pending',
      'data': {'nombre': 'Ing. Nuevo'},
    });

    await batch.commit();
  }
}
