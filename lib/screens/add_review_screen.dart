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
              'NIVEL DE DIFICULTAD',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Dificultad.values.map((d) {
                final isSelected = _dificultad == d;
                return ChoiceChip(
                  label: Text(_getDificultadLabel(d)),
                  selected: isSelected,
                  showCheckmark: false,
                  selectedColor: Colors.green.withAlpha((0.22 * 255).toInt()),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.green.shade800
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? Colors.green.shade700
                        : theme.dividerColor,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _dificultad = d;
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
                    oportunidadAprobacion: OportunidadAprobacion.probable,
                    consejo: _consejoController.text.trim(),
                    metodosEnsenanza: const [],
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
