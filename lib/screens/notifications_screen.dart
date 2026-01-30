import 'package:flutter/material.dart';
import 'package:profe_unasam/services/data_service.dart';
import 'package:profe_unasam/models/user_role.dart';
import 'package:profe_unasam/screens/moderation_queue_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _dataService = DataService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = _dataService.getRole();
    final notifications = _dataService
        .getNotifications()
        .where(
          (n) => role != UserRole.user || !n.title.startsWith('[Moderación]'),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'limpiar',
              onPressed: () {
                setState(() {
                  _dataService.clearNotifications();
                });
              },
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Text(
                'No tienes notificaciones',
                style: theme.textTheme.bodyLarge,
              ),
            )
          : ListView.separated(
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final n = notifications[index];
                return ListTile(
                  leading: Icon(
                    n.isRead ? Icons.notifications_none : Icons.notifications,
                  ),
                  title: Text(
                    n.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: n.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(n.body),
                  trailing: Text(
                    '${n.createdAt.day}/${n.createdAt.month}',
                    style: theme.textTheme.bodySmall,
                  ),
                  onTap: () {
                    setState(() {
                      _dataService.markNotificationRead(n.id);
                    });
                    if (n.actionType == 'review_flag' && n.actionId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ModerationQueueScreen(initialFlagId: n.actionId!),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
