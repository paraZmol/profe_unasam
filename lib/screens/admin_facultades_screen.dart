import 'package:flutter/material.dart';
import 'package:profe_unasam/models/facultad_model.dart';
import 'package:profe_unasam/services/data_service.dart';
import 'package:profe_unasam/theme/app_theme.dart';

class AdminFacultadesScreen extends StatefulWidget {
  const AdminFacultadesScreen({super.key});

  @override
  State<AdminFacultadesScreen> createState() => _AdminFacultadesScreenState();
}

class _AdminFacultadesScreenState extends State<AdminFacultadesScreen> {
  final _dataService = DataService();
  late TextEditingController _nombreFacultadController;
  late TextEditingController _nombreEscuelaController;
  String? _selectedFacultadId;

  @override
  void initState() {
    super.initState();
    _nombreFacultadController = TextEditingController();
    _nombreEscuelaController = TextEditingController();
    _loadFacultades();
  }

  @override
  void dispose() {
    _nombreFacultadController.dispose();
    _nombreEscuelaController.dispose();
    super.dispose();
  }

  Future<void> _agregarFacultad() async {
    if (!_guardSensitiveAction()) {
      return;
    }
    if (_nombreFacultadController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ingresa el nombre de la facultad')),
      );
      return;
    }

    final nuevaFacultad = Facultad(
      id: _dataService.generarIdUnico('f'),
      nombre: _nombreFacultadController.text.trim(),
      escuelas: [],
    );

    await _dataService.agregarFacultad(nuevaFacultad);
    if (!mounted) return;
    setState(() {
      _nombreFacultadController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('facultad agregada exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _agregarEscuela() async {
    if (!_guardSensitiveAction()) {
      return;
    }
    if (_selectedFacultadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('selecciona una facultad primero')),
      );
      return;
    }

    if (_nombreEscuelaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ingresa el nombre de la escuela')),
      );
      return;
    }

    final nuevaEscuela = Escuela(
      id: _dataService.generarIdUnico('e'),
      nombre: _nombreEscuelaController.text.trim(),
      facultadId: _selectedFacultadId!,
    );

    await _dataService.agregarEscuela(_selectedFacultadId!, nuevaEscuela);
    if (!mounted) return;
    setState(() {
      _nombreEscuelaController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('escuela agregada exitosamente'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facultades = _dataService.getFacultades();

    return Scaffold(
      appBar: AppBar(title: const Text('Administrar Facultades y Escuelas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // seccion agregar facultad
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'agregar nueva facultad',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nombreFacultadController,
                            decoration: const InputDecoration(
                              hintText: 'nombre de la facultad',
                              prefixIcon: Icon(Icons.school),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _agregarFacultad,
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // seccion agregar escuela
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'agregar nueva escuela',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                              _selectedFacultadId = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nombreEscuelaController,
                            decoration: const InputDecoration(
                              hintText: 'nombre de la escuela',
                              prefixIcon: Icon(Icons.class_),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _agregarEscuela,
                          child: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // lista de facultades y escuelas
            Text(
              'facultades registradas',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: facultades.length,
              itemBuilder: (context, index) {
                final facultad = facultades[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(facultad.nombre),
                    subtitle: Text('${facultad.escuelas.length} escuelas'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (facultad.escuelas.isEmpty)
                              Text(
                                'sin escuelas registradas',
                                style: theme.textTheme.bodySmall,
                              )
                            else
                              Column(
                                children: facultad.escuelas
                                    .map(
                                      (escuela) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.check_circle,
                                              size: 20,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(escuela.nombre),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadFacultades() async {
    await _dataService.refreshFacultadesFromFirestore();
    if (!mounted) return;
    setState(() {});
  }

  bool _guardSensitiveAction() {
    if (_dataService.isSensitiveActionsLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_dataService.sensitiveActionsLockMessage)),
      );
      return false;
    }

    if (!_dataService.canManageFacultades) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para administrar facultades'),
        ),
      );
      return false;
    }

    return true;
  }
}
