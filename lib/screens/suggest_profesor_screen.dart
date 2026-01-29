import 'package:flutter/material.dart';

import 'package:profe_unasam/models/suggestion_model.dart';
import 'package:profe_unasam/services/data_service.dart';

class SuggestProfesorScreen extends StatefulWidget {
  const SuggestProfesorScreen({super.key});

  @override
  State<SuggestProfesorScreen> createState() => _SuggestProfesorScreenState();
}

class _SuggestProfesorScreenState extends State<SuggestProfesorScreen> {
  final _dataService = DataService();
  final _nombreController = TextEditingController();
  final _cursoController = TextEditingController();
  final _apodoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nombreController.dispose();
    _cursoController.dispose();
    _apodoController.dispose();
    super.dispose();
  }

  void _submitSuggestion() {
    if (!_formKey.currentState!.validate()) return;

    _dataService.createSuggestion(
      type: SuggestionType.profesor,
      data: {
        'nombre': _nombreController.text.trim(),
        'curso': _cursoController.text.trim(),
        'apodo': _apodoController.text.trim(),
      },
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gracias por tu sugerencia. Será validada pronto.'),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sugerir Profesor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ayúdanos a mejorar', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Sugiere un profesor que deberíamos añadir a DocIn',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del Profesor *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  if (value.trim().length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cursoController,
                decoration: InputDecoration(
                  labelText: 'Curso / Materia *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El curso es requerido';
                  }
                  if (value.trim().length < 3) {
                    return 'El curso debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apodoController,
                decoration: InputDecoration(
                  labelText: 'Apodo o sobrenombre (opcional)',
                  hintText: 'Ej: "El profesor strict"',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitSuggestion,
                  child: const Text('Enviar Sugerencia'),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡 Nota', style: theme.textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Tu sugerencia será revisada por moderadores antes de ser añadida.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
