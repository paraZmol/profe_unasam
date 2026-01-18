import '../models/profesor_model.dart';
import '../models/review_model.dart';

final List<Profesor> mockProfesores = [
  Profesor(
    id: 'p001',
    nombre: 'Bubu Buble',
    curso: 'Programación',
    calificacion: 4.5,
    fotoUrl: 'https://i.pravatar.cc/150?img=11',
    reviews: [
      Review(
        id: 'r001',
        comentario: 'Excelente profesor, explica muy claro.',
        puntuacion: 5.0,
        fecha: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Review(
        id: 'r002',
        comentario: 'Sus exámenes son algo difíciles, pero se aprende.',
        puntuacion: 4.0,
        fecha: DateTime.now().subtract(const Duration(days: 10)),
      ),
    ],
  ),
  Profesor(
    id: 'p002',
    nombre: 'Chatox',
    curso: 'PHP',
    calificacion: 4.9,
    fotoUrl: 'https://i.pravatar.cc/150?img=3',
    reviews: [
      Review(
        id: 'r003',
        comentario: 'El mejor en PHP de la UNASAM.',
        puntuacion: 5.0,
        fecha: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  ),
  Profesor(
    id: 'p003',
    nombre: 'Silva',
    curso: 'Programación III',
    calificacion: 2.0,
    fotoUrl: 'https://i.pravatar.cc/150?img=5',
    reviews: [
      Review(
        id: 'r004',
        comentario: 'Muy estricto y no explica bien los temas complejos.',
        puntuacion: 2.0,
        fecha: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ],
  ),
];
