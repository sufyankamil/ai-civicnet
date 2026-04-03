import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/supabase_service.dart';
import '../../../../models/models.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: SupabaseService().getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey[400]),
                   const SizedBox(height: 16),
                   Text('No notifications yet', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                ],
              ),
            );
          }

          final notifications = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _NotificationItem(
                notification: notif,
                onTap: () async {
                  if (!notif.isRead) {
                     await SupabaseService().markNotificationAsRead(notif.id);
                  }
                  if (notif.relatedId != null && notif.type == 'new_request') {
                     if (context.mounted) {
                        context.push('/request/${notif.relatedId}');
                     }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
  });

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: isUnread ? Theme.of(context).primaryColor : Colors.grey[300],
              child: Icon(
                Icons.notifications_rounded,
                color: isUnread ? Colors.white : Colors.grey[600],
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                            fontSize: 16,
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatTimeAgo(notification.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
