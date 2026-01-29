// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:profe_unasam/models/profesor_model.dart';
import 'package:profe_unasam/screens/add_profesor_screen.dart';
import 'package:profe_unasam/screens/admin_facultades_screen.dart';
import 'package:profe_unasam/screens/notifications_screen.dart';
import 'package:profe_unasam/services/data_service.dart';
import 'package:profe_unasam/widgets/profesor_card.dart';
import 'package:profe_unasam/widgets/search_filter_bar.dart';
import 'package:profe_unasam/models/user_plan.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool)? onThemeToggle;
  final bool isDarkMode;

  const HomeScreen({super.key, this.onThemeToggle, this.isDarkMode = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final _dataService = DataService();

  String _searchQuery = '';
  String _selectedCourse = 'todos';
  SortOption _sortOption = SortOption.calificacion;
  List<Profesor> _filteredProfesores = [];

  @override
  void initState() {
    super.initState();
    _inicializarDatos();
    // escuchar cambios en tiempo real
    _searchController.addListener(_filterAndSort);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _inicializarDatos() {
    _filteredProfesores = _dataService.getProfesores();
    _filterAndSort();
  }

  void _filterAndSort() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredProfesores = _applyFilters();
    });
  }

  Future<void> _showPlanSheet() async {
    final theme = Theme.of(context);
    final currentPlan = _dataService.getPlan();
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu plan actual: ${currentPlan.label}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.lock_open),
                  title: const Text('Gratis'),
                  subtitle: const Text('Vista resumida y reseñas limitadas'),
                  trailing: currentPlan == UserPlan.free
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    setState(() {
                      _dataService.setPlanFree();
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('Iniciar prueba (7 días)'),
                  subtitle: const Text('Acceso completo temporal'),
                  trailing: currentPlan == UserPlan.trial
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    setState(() {
                      _dataService.startTrial(days: 7);
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.workspace_premium),
                  title: const Text('Premium'),
                  subtitle: const Text('Acceso completo sin límites'),
                  trailing: currentPlan == UserPlan.premium
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    setState(() {
                      _dataService.setPlanPremium();
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Profesor> _applyFilters() {
    // aplicar filtros de busqueda y curso
    var filtered = _dataService.getProfesores().where((profesor) {
      final matchesSearch =
          profesor.nombre.toLowerCase().contains(_searchQuery) ||
          profesor.curso.toLowerCase().contains(_searchQuery);

      final matchesCourse =
          _selectedCourse == 'todos' ||
          profesor.curso.toLowerCase() == _selectedCourse.toLowerCase();

      return matchesSearch && matchesCourse;
    }).toList();

    // aplicar ordenamiento segun opcion seleccionada
    switch (_sortOption) {
      case SortOption.nombre:
        // ordenar alfabeticamente
        filtered.sort((a, b) => a.nombre.compareTo(b.nombre));
      case SortOption.calificacion:
        // ordenar de mayor a menor calificacion
        filtered.sort((a, b) => b.calificacion.compareTo(a.calificacion));
      case SortOption.reciente:
        // ordenar por fecha mas reciente
        filtered.sort((a, b) {
          final aLastReview = a.reviews.isNotEmpty
              ? a.reviews.first.fecha
              : DateTime(1970);
          final bLastReview = b.reviews.isNotEmpty
              ? b.reviews.first.fecha
              : DateTime(1970);
          return bLastReview.compareTo(aLastReview);
        });
    }

    return filtered;
  }

  List<String> _getUniqueCourses() {
    final courses = <String>{'todos'};
    // extraer cursos unicos de los profesores
    for (var profesor in _dataService.getProfesores()) {
      courses.add(profesor.curso);
    }
    return courses.toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final courses = _getUniqueCourses();
    final unreadCount = _dataService.getUnreadNotificationsCount();
    final currentPlan = _dataService.getPlan();

    return Scaffold(
      appBar: AppBar(
        title: Text('Profesores UNASAM (${currentPlan.label})'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications),
                if (unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onError,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'notificaciones',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              ).then((_) => setState(() {}));
            },
          ),
          IconButton(
            icon: const Icon(Icons.workspace_premium),
            tooltip: 'plan',
            onPressed: _showPlanSheet,
          ),
          // boton para administrar facultades
          IconButton(
            icon: const Icon(Icons.school),
            tooltip: 'administrar facultades y escuelas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminFacultadesScreen(),
                ),
              ).then((_) {
                setState(() {
                  _inicializarDatos();
                });
              });
            },
          ),
          // boton para cambiar tema
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              widget.onThemeToggle?.call(!widget.isDarkMode);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // barra de busqueda y filtros reutilizable
          SearchFilterBar(
            searchController: _searchController,
            selectedCourse: _selectedCourse,
            courses: courses,
            sortOption: _sortOption,
            onCourseChanged: (course) {
              setState(() {
                _selectedCourse = course;
                _filteredProfesores = _applyFilters();
              });
            },
            onSortChanged: (option) {
              setState(() {
                _sortOption = option;
                _filteredProfesores = _applyFilters();
              });
            },
            onClearSearch: () {
              _searchController.clear();
              _filterAndSort();
            },
          ),
          // lista de profesores filtrados
          Expanded(
            child: _filteredProfesores.isEmpty
                ? _buildEmptyState(context, theme)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _filteredProfesores.length,
                    itemBuilder: (context, index) {
                      final profesor = _filteredProfesores[index];
                      return ProfesorCard(profesor: profesor);
                    },
                  ),
          ),
        ],
      ),
      // boton flotante para agregar nuevo profesor
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProfesorScreen(
                onProfesorAdded: (profesor) {
                  setState(() {
                    _inicializarDatos();
                  });
                },
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('agregar profesor'),
      ),
    );
  }

  // widget para mostrar estado vacio con mensaje personalizado
  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'no se encontraron profesores',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty && _selectedCourse != 'todos'
                ? 'intenta cambiar el filtro de curso'
                : 'intenta con otra busqueda',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
