import 'package:profe_unasam/models/facultad_model.dart';
import 'package:profe_unasam/models/profesor_model.dart';
import 'package:profe_unasam/models/review_model.dart';

// datos iniciales de facultades y escuelas
final List<Facultad> mockFacultades = [
  Facultad(
    id: 'f001',
    nombre: 'Facultad de Ciencias',
    escuelas: [
      Escuela(
        id: 'e001',
        nombre: 'Ingenieria de Sistemas e Informatica',
        facultadId: 'f001',
      ),
      Escuela(
        id: 'e002',
        nombre: 'Educacion y Comunicacion',
        facultadId: 'f001',
      ),
      Escuela(
        id: 'e003',
        nombre: 'Estadistica e Informatica',
        facultadId: 'f001',
      ),
    ],
  ),
  Facultad(
    id: 'f002',
    nombre: 'Ciencias de la Salud',
    escuelas: [
      Escuela(id: 'e004', nombre: 'Medicina', facultadId: 'f002'),
      Escuela(id: 'e005', nombre: 'Enfermeria', facultadId: 'f002'),
      Escuela(id: 'e006', nombre: 'Odontologia', facultadId: 'f002'),
    ],
  ),
  Facultad(
    id: 'f003',
    nombre: 'Derecho y Ciencias Sociales',
    escuelas: [
      Escuela(id: 'e007', nombre: 'Derecho', facultadId: 'f003'),
      Escuela(id: 'e008', nombre: 'Administracion', facultadId: 'f003'),
      Escuela(id: 'e009', nombre: 'Contabilidad', facultadId: 'f003'),
    ],
  ),
];

final List<Profesor> mockProfesores = [
  Profesor(
    id: 'p001',
    nombre: 'Bubu Buble',
    curso: 'Programación',
    facultadId: 'f001',
    escuelaId: 'e001',
    calificacion: 4.5,
    fotoUrl:
        'https://media-lim1-1.cdn.whatsapp.net/v/t61.24694-24/293874895_451436070133149_3343926150248203909_n.jpg?ccb=11-4&oh=01_Q5Aa3gGbjY4x6qBoTkh09Q4R-AS1Hx5OiCySRQJ9NL2e_tP9_w&oe=697A709E&_nc_sid=5e03e0&_nc_cat=100',
    apodo: 'El Profe Buble',
    reviews: [
      Review(
        id: 'r001',
        comentario: 'Excelente profesor, explica muy claro.',
        puntuacion: 5.0,
        fecha: DateTime.now().subtract(const Duration(days: 2)),
        dificultad: Dificultad.facil,
        oportunidadAprobacion: OportunidadAprobacion.casioSeguroe,
        consejo: 'Asiste a clase y haz todos los trabajos prácticos',
        metodosEnsenanza: ['Clases magistrales', 'Ejercicios prácticos'],
      ),
      Review(
        id: 'r002',
        comentario: 'Sus examenes son algo dificiles, pero se aprende.',
        puntuacion: 4.0,
        fecha: DateTime.now().subtract(const Duration(days: 10)),
        dificultad: Dificultad.dificil,
        oportunidadAprobacion: OportunidadAprobacion.probable,
        consejo: 'Estudia los ejercicios del libro, se repiten en el examen',
        metodosEnsenanza: ['Clases magistrales', 'Resolución de problemas'],
      ),
    ],
  ),
  Profesor(
    id: 'p002',
    nombre: 'Chatox',
    curso: 'PHP',
    facultadId: 'f001',
    escuelaId: 'e001',
    calificacion: 4.9,
    fotoUrl:
        'https://media-lim1-1.cdn.whatsapp.net/v/t61.24694-24/414728706_1417097939225101_4291173992527253576_n.jpg?ccb=11-4&oh=01_Q5Aa3gHeNGirJtdElJqclgny8qTKjHOcVEyxgqaAEjsq44qv-g&oe=697A64E6&_nc_sid=5e03e0&_nc_cat=105',
    apodo: 'El Rey del PHP',
    reviews: [
      Review(
        id: 'r003',
        comentario: 'El mejor en PHP de la UNASAM.',
        puntuacion: 5.0,
        fecha: DateTime.now().subtract(const Duration(days: 1)),
        dificultad: Dificultad.normal,
        oportunidadAprobacion: OportunidadAprobacion.casioSeguroe,
        consejo: 'El profe entiende cuando tienes dudas, aprovecha eso',
        metodosEnsenanza: ['Ejercicios prácticos', 'Laboratorio'],
      ),
    ],
  ),
  Profesor(
    id: 'p003',
    nombre: 'Silva',
    curso: 'Programación III',
    facultadId: 'f001',
    escuelaId: 'e001',
    calificacion: 2.0,
    fotoUrl: 'https://i.pravatar.cc/150?img=5',
    apodo: null,
    reviews: [
      Review(
        id: 'r004',
        comentario: 'Muy estricto y no explica bien los temas complejos.',
        puntuacion: 2.0,
        fecha: DateTime.now().subtract(const Duration(days: 30)),
        dificultad: Dificultad.muyDificil,
        oportunidadAprobacion: OportunidadAprobacion.dificil,
        consejo: 'Si es posible, espera a otro semestre para otro profe',
        metodosEnsenanza: ['Clases magistrales'],
      ),
    ],
  ),
  Profesor(
    id: 'p004',
    nombre: 'Abel Anacleto',
    curso: 'Chuchulogia',
    facultadId: 'f002',
    escuelaId: 'e004',
    calificacion: 4.7,
    fotoUrl:
        'https://media-lim1-1.cdn.whatsapp.net/v/t61.24694-24/397590148_862542188869178_7427810096452653571_n.jpg?ccb=11-4&oh=01_Q5Aa3gFYSry02Dfudb9Hhxof8SvNjYO-f1oaKKevtx_mO6fXoA&oe=697A5E95&_nc_sid=5e03e0&_nc_cat=105',
    apodo: 'El Doc Ramirez',
    reviews: [
      Review(
        id: 'r005',
        comentario: 'Excelente docente, muy dedicado con sus estudiantes.',
        puntuacion: 5.0,
        fecha: DateTime.now().subtract(const Duration(days: 5)),
        dificultad: Dificultad.normal,
        oportunidadAprobacion: OportunidadAprobacion.casioSeguroe,
        consejo: 'Aprovecha las consultas del profe, siempre está disponible',
        metodosEnsenanza: [
          'Clases magistrales',
          'Laboratorio',
          'Trabajos en grupo',
        ],
      ),
    ],
  ),
  Profesor(
    id: 'p005',
    nombre: 'Lic. Martinez',
    curso: 'Derecho Penal',
    facultadId: 'f003',
    escuelaId: 'e007',
    calificacion: 3.8,
    fotoUrl: 'https://i.pravatar.cc/150?img=2',
    apodo: 'Lic. Penalista',
    reviews: [
      Review(
        id: 'r006',
        comentario: 'Buen profesor, aunque a veces es algo confuso.',
        puntuacion: 3.5,
        fecha: DateTime.now().subtract(const Duration(days: 15)),
        dificultad: Dificultad.dificil,
        oportunidadAprobacion: OportunidadAprobacion.cincuentaCincuenta,
        consejo: 'Lee los apuntes de clase varias veces para entender',
        metodosEnsenanza: ['Clases magistrales'],
      ),
    ],
  ),
];
