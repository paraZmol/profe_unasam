import 'package:flutter/material.dart';
import 'package:profe_unasam/services/data_service.dart';

class ModerationQueueScreen extends StatefulWidget {
  final String? initialFlagId;

  const ModerationQueueScreen({super.key, this.initialFlagId});

  @override
  State<ModerationQueueScreen> createState() => _ModerationQueueScreenState();
}

class _ModerationQueueScreenState extends State<ModerationQueueScreen> {
  final _dataService = DataService();

  @override
  void initState() {
    super.initState();

    if (_dataService.isSensitiveActionsLocked ||
        !_dataService.canModerateComments) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _dataService.isSensitiveActionsLocked
                  ? _dataService.sensitiveActionsLockMessage
                  : 'No tienes permisos para moderar comentarios',
            ),
          ),
        );
        Navigator.pop(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final flags = _dataService.getPendingReviewFlags();

    return Scaffold(
      appBar: AppBar(title: const Text('Moderación de comentarios')),
      body: flags.isEmpty
          ? Center(
              child: Text(
                'No hay comentarios en revisión',
                style: theme.textTheme.bodyLarge,
              ),
            )
          : ListView.builder(
              itemCount: flags.length,
              itemBuilder: (context, index) {
                final flag = flags[index];
                final profesor = _dataService.getProfesorById(flag.profesorId);
                final review = _dataService.getReviewById(flag.reviewId);

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: flag.id == widget.initialFlagId
                      ? RoundedRectangleBorder(
                          side: BorderSide(color: theme.colorScheme.primary),
                          borderRadius: BorderRadius.circular(12),
                        )
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profesor?.nombre ?? 'Docente',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          review?.comentario ?? 'Comentario no encontrado',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Motivo: ${flag.reason}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                'Mods: ${flag.moderatorApprovals.length}/1',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(
                                flag.adminApproved
                                    ? 'Admin aprobado'
                                    : 'Admin pendiente',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                try {
                                  _dataService.rejectReviewFlag(flag.id);
                                  setState(() {});
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                              child: const Text('Rechazar'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                try {
                                  _dataService.approveReviewFlag(flag.id);
                                  setState(() {});
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                              child: const Text('Aprobar'),
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
}
