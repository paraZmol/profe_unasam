import 'package:flutter/material.dart';
import 'package:profe_unasam/models/profesor_model.dart';
import 'package:profe_unasam/services/data_service.dart';
import 'package:profe_unasam/theme/app_theme.dart';

class AddProfesorScreen extends StatefulWidget {
  final Function(Profesor) onProfesorAdded;

  const AddProfesorScreen({super.key, required this.onProfesorAdded});

  @override
  State<AddProfesorScreen> createState() => _AddProfesorScreenState();
}

class _AddProfesorScreenState extends State<AddProfesorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataService = DataService();

  late TextEditingController _nombreController;
  late TextEditingController _cursoController;
  late TextEditingController _fotoUrlController;
  late TextEditingController _apodoController;

  String? _selectedFacultad;
  String? _selectedEscuela;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _cursoController = TextEditingController();
    _fotoUrlController = TextEditingController();
    _apodoController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cursoController.dispose();
    _fotoUrlController.dispose();
    _apodoController.dispose();
    super.dispose();
  }

  void _guardarProfesor() {
    if (_formKey.currentState!.validate() &&
        _selectedFacultad != null &&
        _selectedEscuela != null) {
      final nuevoProfesor = Profesor(
        id: _dataService.generarIdUnico('p'),
        nombre: _nombreController.text.trim(),
        curso: _cursoController.text.trim(),
        facultadId: _selectedFacultad!,
        escuelaId: _selectedEscuela!,
        calificacion: 0.0,
        fotoUrl: _fotoUrlController.text.trim().isNotEmpty
            ? _fotoUrlController.text.trim()
            : 'https://i.pravatar.cc/150?img=1',
        apodo: _apodoController.text.trim().isNotEmpty
            ? _apodoController.text.trim()
            : null,
        reviews: [],
      );

      _dataService.agregarProfesor(nuevoProfesor);
      widget.onProfesorAdded(nuevoProfesor);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('profesor agregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('completa todos los campos requeridos'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facultades = _dataService.getFacultades();
    final escuelas = _selectedFacultad != null
        ? (_dataService.getFacultadById(_selectedFacultad!)?.escuelas ?? [])
        : [];

    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Nuevo Profesor')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // seccion de informacion personal
              Text(
                'informacion personal',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),

              // nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'nombre completo',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'el nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // curso/materia
              TextFormField(
                controller: _cursoController,
                decoration: const InputDecoration(
                  labelText: 'curso o materia',
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'el curso es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // apodo (opcional)
              TextFormField(
                controller: _apodoController,
                decoration: const InputDecoration(
                  labelText: 'apodo (opcional)',
                  prefixIcon: Icon(Icons.star),
                  hintText: 'ej: "El Profe Bueno"',
                ),
              ),
              const SizedBox(height: 16),

              // url de foto (opcional)
              TextFormField(
                controller: _fotoUrlController,
                decoration: const InputDecoration(
                  labelText: 'url de foto (opcional)',
                  prefixIcon: Icon(Icons.image),
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: 24),

              // seccion de facultad y escuela
              Text(
                'facultad y escuela',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),

              // dropdown de facultad
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFacultad,
                    isExpanded: true,
                    hint: const Text('selecciona facultad'),
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
                        _selectedFacultad = value;
                        _selectedEscuela = null;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // dropdown de escuela
              if (_selectedFacultad != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedEscuela,
                      isExpanded: true,
                      hint: const Text('selecciona escuela'),
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
                          _selectedEscuela = value;
                        });
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              // botones de accion
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _guardarProfesor,
                      child: const Text('guardar profesor'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
