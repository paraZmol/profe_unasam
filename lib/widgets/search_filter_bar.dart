import 'package:flutter/material.dart';
import 'package:profe_unasam/theme/app_theme.dart';

enum SortOption { nombre, calificacion, reciente }

class SearchFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String selectedCourse;
  final List<String> courses;
  final SortOption sortOption;
  final Function(String) onCourseChanged;
  final Function(SortOption) onSortChanged;
  final VoidCallback onClearSearch;

  const SearchFilterBar({
    super.key,
    required this.searchController,
    required this.selectedCourse,
    required this.courses,
    required this.sortOption,
    required this.onCourseChanged,
    required this.onSortChanged,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.appBarTheme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // campo de busqueda con icono y boton de limpiar
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'busca por nombre o cursos...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClearSearch,
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // fila de filtros
          Row(
            children: [
              // dropdown de cursos con interfaz mejorada
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor, width: 0.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedCourse,
                      isExpanded: true,
                      items: courses
                          .map(
                            (course) => DropdownMenuItem(
                              value: course,
                              child: Text(
                                course,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        onCourseChanged(value ?? 'todos');
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // menu de ordenamiento con iconos descriptivos
              PopupMenuButton<SortOption>(
                initialValue: sortOption,
                onSelected: onSortChanged,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: SortOption.calificacion,
                    child: Row(
                      children: [
                        Icon(Icons.star, color: AppTheme.accentAmber, size: 18),
                        const SizedBox(width: 8),
                        const Text('por calificacion'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: SortOption.nombre,
                    child: Row(
                      children: [
                        Icon(
                          Icons.abc,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('por nombre'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: SortOption.reciente,
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text('mas recientes'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor, width: 0.5),
                  ),
                  child: Icon(Icons.tune, color: theme.colorScheme.primary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
