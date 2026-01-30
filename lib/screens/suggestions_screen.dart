import 'package:flutter/material.dart';

import 'package:profe_unasam/models/suggestion_model.dart';
import 'package:profe_unasam/services/data_service.dart';

class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({super.key});

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  final _dataService = DataService();
  late List<Suggestion> _pendingSuggestions;

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  void _loadSuggestions() {
    setState(() {
      _pendingSuggestions = _dataService.getPendingSuggestions();
    });
  }

  void _approveSuggestion(Suggestion suggestion) {
    if (!_guardSensitiveAction()) {
      return;
    }
    try {
      _dataService.approveSuggestion(suggestion.id);
      _loadSuggestions();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sugerencia aprobada')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _rejectSuggestion(Suggestion suggestion) {
    if (!_guardSensitiveAction()) {
      return;
    }
    _dataService.rejectSuggestion(suggestion.id);
    _loadSuggestions();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sugerencia rechazada')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sugerencias Pendientes'),
        centerTitle: true,
      ),
      body: _pendingSuggestions.isEmpty
          ? Center(
              child: Text(
                'No hay sugerencias pendientes',
                style: theme.textTheme.bodyMedium,
              ),
            )
          : ListView.builder(
              itemCount: _pendingSuggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _pendingSuggestions[index];
                final typeLabel = suggestion.type == SuggestionType.profesor
                    ? 'Profesor'
                    : suggestion.type == SuggestionType.facultad
                    ? 'Facultad'
                    : 'Escuela';

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    typeLabel,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    suggestion.data['nombre'] ?? 'Sin nombre',
                                    style: theme.textTheme.titleMedium,
                                  ),
                                  if (suggestion.data['cursos'] != null ||
                                      suggestion.data['curso'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        suggestion.data['cursos'] is List
                                            ? (suggestion.data['cursos']
                                                      as List)
                                                  .join(', ')
                                            : (suggestion.data['curso'] ?? ''),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(
                                'Por: ${suggestion.userAlias}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (suggestion.data.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: suggestion.data.entries
                                  .map(
                                    (e) => Text(
                                      '${e.key}: ${e.value}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _rejectSuggestion(suggestion),
                              icon: const Icon(Icons.close),
                              label: const Text('Rechazar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _approveSuggestion(suggestion),
                              icon: const Icon(Icons.check),
                              label: const Text('Aprobar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  bool _guardSensitiveAction() {
    if (_dataService.isSensitiveActionsLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_dataService.sensitiveActionsLockMessage)),
      );
      return false;
    }

    if (!_dataService.canApproveSuggestions) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para aprobar sugerencias'),
        ),
      );
      return false;
    }

    return true;
  }
}
