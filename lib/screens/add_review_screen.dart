import 'package:flutter/material.dart';

import 'package:profe_unasam/models/profesor_model.dart';
import 'package:profe_unasam/models/review_model.dart';
import 'package:profe_unasam/theme/app_theme.dart';

class AddReviewScreen extends StatefulWidget {
  final Profesor profesor;
  final String userAlias;
  final String userId;

  const AddReviewScreen({
    super.key,
    required this.profesor,
    required this.userAlias,
    required this.userId,
  });

  @override
  State<AddReviewScreen> createState() => _AddReviewScreenState();
}

class _AddReviewScreenState extends State<AddReviewScreen> {
  double _rating = 3.0;
  final _commentController = TextEditingController();
  final _consejoController = TextEditingController();

  Dificultad _dificultad = Dificultad.normal;
  OportunidadAprobacion _oportunidad = OportunidadAprobacion.probable;
  final List<String> _metodosSeleccionados = [];

  final List<String> _metodos = [
    'Clases magistrales',
    'Ejercicios prácticos',
    'Trabajos en grupo',
    'Laboratorio',
    'Resolución de problemas',
    'Aprendizaje basado en proyectos',
    'Aprendizaje basado en problemas',
    'Estudios de caso',
    'Debates en clase',
    'Exposiciones',
    'Aula invertida',
    'Simulaciones',
    'Talleres',
    'Tutorías',
    'Lecturas guiadas',
    'Uso de TIC/recursos digitales',
    'Evaluaciones continuas',
    'Quizzes cortos',
    'Aprendizaje colaborativo',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    _consejoController.dispose();
    super.dispose();
  }

  String _getDificultadLabel(Dificultad d) {
    switch (d) {
      case Dificultad.muyFacil:
        return 'Muy Fácil';
      case Dificultad.facil:
        return 'Fácil';
      case Dificultad.normal:
        return 'Normal';
      case Dificultad.dificil:
        return 'Difícil';
      case Dificultad.muyDificil:
        return 'Muy Difícil';
    }
  }

  String _getOportunidadLabel(OportunidadAprobacion o) {
    switch (o) {
      case OportunidadAprobacion.casioSeguroe:
        return 'Casi seguro (95%+)';
      case OportunidadAprobacion.probable:
        return 'Probable (70-95%)';
      case OportunidadAprobacion.cincuentaCincuenta:
        return '50/50';
      case OportunidadAprobacion.dificil:
        return 'Difícil (<50%)';
    }
  }

  Color _getOportunidadColor(OportunidadAprobacion o) {
    switch (o) {
      case OportunidadAprobacion.casioSeguroe:
        return Colors.green;
      case OportunidadAprobacion.probable:
        return Colors.blue;
      case OportunidadAprobacion.cincuentaCincuenta:
        return Colors.orange;
      case OportunidadAprobacion.dificil:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('CALIFICAR DOCENTE')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Qué tal fue tu clase con ${widget.profesor.nombre}?',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 20),

            // ============ PUNTUACION ============
            Text(
              'PUNTUACIÓN GENERAL',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: index < _rating
                        ? AppTheme.accentAmber
                        : theme.disabledColor,
                    size: 40,
                  ),
                  onPressed: () {
                    setState(() {
                      _rating = index + 1.0;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 24),

            // ============ DIFICULTAD ============
            Text(
              'DIFICULTAD DE LA MATERIA',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<Dificultad>(
              segments: <ButtonSegment<Dificultad>>[
                ButtonSegment<Dificultad>(
                  value: Dificultad.muyFacil,
                  label: Text(_getDificultadLabel(Dificultad.muyFacil)),
                ),
                ButtonSegment<Dificultad>(
                  value: Dificultad.facil,
                  label: Text(_getDificultadLabel(Dificultad.facil)),
                ),
                ButtonSegment<Dificultad>(
                  value: Dificultad.normal,
                  label: Text(_getDificultadLabel(Dificultad.normal)),
                ),
                ButtonSegment<Dificultad>(
                  value: Dificultad.dificil,
                  label: Text(_getDificultadLabel(Dificultad.dificil)),
                ),
                ButtonSegment<Dificultad>(
                  value: Dificultad.muyDificil,
                  label: Text(_getDificultadLabel(Dificultad.muyDificil)),
                ),
              ],
              selected: <Dificultad>{_dificultad},
              onSelectionChanged: (Set<Dificultad> newSelection) {
                setState(() {
                  _dificultad = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 24),

            // ============ OPORTUNIDAD ============
            Text(
              'OPORTUNIDAD DE APROBAR',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: OportunidadAprobacion.values.map((o) {
                final isSelected = _oportunidad == o;
                return FilterChip(
                  label: Text(_getOportunidadLabel(o)),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _oportunidad = o;
                    });
                  },
                  backgroundColor: _getOportunidadColor(
                    o,
                  ).withAlpha((0.2 * 255).toInt()),
                  selectedColor: _getOportunidadColor(o),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : _getOportunidadColor(o),
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ============ METODOS ============
            Text(
              'MÉTODOS DE ENSEÑANZA',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _metodos.map((metodo) {
                final isSelected = _metodosSeleccionados.contains(metodo);
                return FilterChip(
                  label: Text(metodo),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _metodosSeleccionados.add(metodo);
                      } else {
                        _metodosSeleccionados.remove(metodo);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ============ CONSEJO ============
            Text(
              'CONSEJO PARA OTROS ESTUDIANTES (Opcional)',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _consejoController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ej: "Haz todos los trabajos prácticos"',
                border: theme.inputDecorationTheme.border,
                enabledBorder: theme.inputDecorationTheme.enabledBorder,
                focusedBorder: theme.inputDecorationTheme.focusedBorder,
                filled: theme.inputDecorationTheme.filled,
                fillColor: theme.inputDecorationTheme.fillColor,
                contentPadding: theme.inputDecorationTheme.contentPadding,
              ),
            ),
            const SizedBox(height: 24),

            // ============ COMENTARIO ============
            Text(
              'COMENTARIO DETALLADO',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Escribe tu experiencia con el profe...',
                border: theme.inputDecorationTheme.border,
                enabledBorder: theme.inputDecorationTheme.enabledBorder,
                focusedBorder: theme.inputDecorationTheme.focusedBorder,
                filled: theme.inputDecorationTheme.filled,
                fillColor: theme.inputDecorationTheme.fillColor,
                contentPadding: theme.inputDecorationTheme.contentPadding,
              ),
            ),
            const SizedBox(height: 30),

            // ============ BOTON ENVIAR ============
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_commentController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor escribe un comentario'),
                      ),
                    );
                    return;
                  }

                  final newReview = Review(
                    id: DateTime.now().toString(),
                    userId: widget.userId,
                    userAlias: widget.userAlias,
                    comentario: _commentController.text,
                    puntuacion: _rating,
                    fecha: DateTime.now(),
                    dificultad: _dificultad,
                    oportunidadAprobacion: _oportunidad,
                    consejo: _consejoController.text.trim(),
                    metodosEnsenanza: _metodosSeleccionados,
                  );

                  Navigator.pop(context, newReview);
                },
                child: const Text(
                  'ENVIAR CALIFICACIÓN',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
