import 'package:flutter/material.dart';

import 'package:profe_unasam/models/suggestion_model.dart';
import 'package:profe_unasam/services/data_service.dart';
import 'package:profe_unasam/widgets/loading_dots.dart';

class SuggestFacultadEscuelaScreen extends StatefulWidget {
  const SuggestFacultadEscuelaScreen({super.key});

  @override
  State<SuggestFacultadEscuelaScreen> createState() =>
      _SuggestFacultadEscuelaScreenState();
}

class _SuggestFacultadEscuelaScreenState
    extends State<SuggestFacultadEscuelaScreen> {
  final _dataService = DataService();
  final _nombreController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  SuggestionType _type = SuggestionType.facultad;
  String? _selectedFacultadId;

  @override
  void initState() {
    super.initState();
    _loadFacultades();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _loadFacultades() async {
    await _dataService.refreshFacultadesFromFirestore();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _submitSuggestion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    final data = <String, dynamic>{'nombre': _nombreController.text.trim()};

    if (_type == SuggestionType.escuela) {
      if (_selectedFacultadId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona una facultad')),
        );
        return;
      }
      data['facultadId'] = _selectedFacultadId;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _dataService.createSuggestion(type: _type, data: data);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Gracias por tu sugerencia.')));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facultades = _dataService.getFacultades();

    return Scaffold(
      appBar: AppBar(title: const Text('Sugerir Facultad/Escuela')),
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
                'Sugiere una facultad o escuela para DocIn',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              SegmentedButton<SuggestionType>(
                segments: const [
                  ButtonSegment(
                    value: SuggestionType.facultad,
                    label: Text('Facultad'),
                  ),
                  ButtonSegment(
                    value: SuggestionType.escuela,
                    label: Text('Escuela'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (selection) {
                  setState(() {
                    _type = selection.first;
                    if (_type == SuggestionType.facultad) {
                      _selectedFacultadId = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: _type == SuggestionType.facultad
                      ? 'Nombre de la Facultad *'
                      : 'Nombre de la Escuela *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  if (value.trim().length < 3) {
                    return 'Mínimo 3 caracteres';
                  }
                  return null;
                },
              ),
              if (_type == SuggestionType.escuela) ...[
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
                        });
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitSuggestion,
                  child: _isSubmitting
                      ? const LoadingDots()
                      : const Text('Enviar Sugerencia'),
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
