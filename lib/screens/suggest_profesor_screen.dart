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
  final _cursosController = TextEditingController();
  final _apodoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _selectedFacultadId;
  String? _selectedEscuelaId;

  @override
  void dispose() {
    _nombreController.dispose();
    _cursosController.dispose();
    _apodoController.dispose();
    super.dispose();
  }

  void _submitSuggestion() {
    if (!_formKey.currentState!.validate()) return;

    final facultades = _dataService.getFacultades();
    if (facultades.isNotEmpty) {
      if (_selectedFacultadId == null || _selectedEscuelaId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona facultad y escuela')),
        );
        return;
      }
    }

    final cursos = _cursosController.text
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    _dataService.createSuggestion(
      type: SuggestionType.profesor,
      data: {
        'nombre': _nombreController.text.trim(),
        'cursos': cursos,
        'apodo': _apodoController.text.trim(),
        if (_selectedFacultadId != null) 'facultadId': _selectedFacultadId,
        if (_selectedEscuelaId != null) 'escuelaId': _selectedEscuelaId,
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
    final facultades = _dataService.getFacultades();
    final escuelas = _selectedFacultadId != null
        ? (_dataService.getFacultadById(_selectedFacultadId!)?.escuelas ?? [])
        : [];

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
                controller: _cursosController,
                decoration: InputDecoration(
                  labelText: 'Cursos / Materias (separados por coma) *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Al menos un curso es requerido';
                  }
                  if (value.trim().length < 3) {
                    return 'Debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              if (facultades.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedFacultadId,
                      isExpanded: true,
                      hint: const Text('Selecciona facultad'),
                      items: facultades
                          .map(
                            (f) => DropdownMenuItem(
                              value: f.id,
                              child: Text(f.nombre),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedFacultadId = value;
                          _selectedEscuelaId = null;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedFacultadId != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedEscuelaId,
                        isExpanded: true,
                        hint: const Text('Selecciona escuela'),
                        items: escuelas
                            .map(
                              (e) => DropdownMenuItem<String>(
                                value: e.id,
                                child: Text(e.nombre),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedEscuelaId = value;
                          });
                        },
                      ),
                    ),
                  ),
              ],
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
