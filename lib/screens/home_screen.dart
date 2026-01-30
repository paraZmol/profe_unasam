// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:profe_unasam/models/profesor_model.dart';
import 'package:profe_unasam/screens/admin_facultades_screen.dart';
import 'package:profe_unasam/screens/notifications_screen.dart';
import 'package:profe_unasam/screens/profile_screen.dart';
import 'package:profe_unasam/screens/suggest_facultad_escuela_screen.dart';
import 'package:profe_unasam/screens/suggest_profesor_screen.dart';
import 'package:profe_unasam/screens/suggestions_screen.dart';
import 'package:profe_unasam/screens/users_management_screen.dart';
import 'package:profe_unasam/services/data_service.dart';
import 'package:profe_unasam/widgets/profesor_card.dart';
import 'package:profe_unasam/widgets/search_filter_bar.dart';
import 'package:profe_unasam/models/user_role.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('DocIn'),
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
            icon: const Icon(Icons.person_outline),
            tooltip: 'perfil',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              ).then((_) => setState(() {}));
            },
          ),
          // boton para cambiar tema
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              widget.onThemeToggle?.call(!widget.isDarkMode);
            },
          ),
          PopupMenuButton<String>(
            tooltip: 'más opciones',
            onSelected: (value) {
              switch (value) {
                case 'suggest':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SuggestProfesorScreen(),
                    ),
                  ).then((_) => setState(() {}));
                  break;
                case 'suggest_faculty':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const SuggestFacultadEscuelaScreen(),
                    ),
                  ).then((_) => setState(() {}));
                  break;
                case 'pending':
                  if (_dataService.isSensitiveActionsLocked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_dataService.sensitiveActionsLockMessage),
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SuggestionsScreen(),
                    ),
                  ).then((_) => setState(() {}));
                  break;
                case 'users':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UsersManagementScreen(),
                    ),
                  ).then((_) => setState(() {}));
                  break;
                case 'faculties':
                  if (_dataService.isSensitiveActionsLocked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_dataService.sensitiveActionsLockMessage),
                      ),
                    );
                    return;
                  }
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
                  break;
              }
            },
            itemBuilder: (context) {
              final items = <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'suggest',
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline),
                      SizedBox(width: 8),
                      Text('Sugerir profesor'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'suggest_faculty',
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_outlined),
                      SizedBox(width: 8),
                      Text('Sugerir facultad/escuela'),
                    ],
                  ),
                ),
              ];

              if (_dataService.getRole() != UserRole.user) {
                items.add(
                  const PopupMenuItem<String>(
                    value: 'pending',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline),
                        SizedBox(width: 8),
                        Text('Sugerencias pendientes'),
                      ],
                    ),
                  ),
                );
              }

              if (_dataService.getRole() == UserRole.admin) {
                items.add(
                  const PopupMenuItem<String>(
                    value: 'users',
                    child: Row(
                      children: [
                        Icon(Icons.people_outline),
                        SizedBox(width: 8),
                        Text('Gestionar usuarios'),
                      ],
                    ),
                  ),
                );
              }

              if (_dataService.canManageFacultades) {
                items.add(
                  const PopupMenuItem<String>(
                    value: 'faculties',
                    child: Row(
                      children: [
                        Icon(Icons.school),
                        SizedBox(width: 8),
                        Text('Administrar facultades'),
                      ],
                    ),
                  ),
                );
              }

              return items;
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
      // boton flotante removido
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
