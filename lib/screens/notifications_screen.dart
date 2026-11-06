import 'package:flutter/material.dart';

import '../models.dart';
import '../notifications/app_notification.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import '../widgets/notification_host.dart';

/// Notification centre: everything addressed to the signed-in user, with a
/// Money filter for payments, top-ups and shift totals.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool moneyOnly = false;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final all = app.myNotifications;
    final list = moneyOnly ? all.where((n) => n.isMoney).toList() : all;
    return PopScope(
      onPopInvokedWithResult: (_, _) => app.markAllRead(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            TextButton(
              onPressed: all.any((n) => !n.read) ? app.markAllRead : null,
              child: const Text('Mark all read'),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: !moneyOnly,
                  onSelected: (_) => setState(() => moneyOnly = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Money'),
                  selected: moneyOnly,
                  onSelected: (_) => setState(() => moneyOnly = true),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (list.isEmpty)
              const Panel(
                child: EmptyState(
                  Icons.notifications_none_rounded,
                  'No notifications',
                  'Payments, top-ups and shift totals appear here.',
                ),
              )
            else
              for (var i = 0; i < list.length; i++)
                FadeSlideIn(index: i, child: _Tile(list[i])),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final AppNotification n;
  const _Tile(this.n);

  @override
  Widget build(BuildContext context) {
    final (color, _) = toneStyle(n.tone);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Panel(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTile(
              n.isMoney ? Icons.payments_outlined : Icons.notifications_none,
              color,
              size: 38,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!n.read)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: UC.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  if (n.body.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      n.body,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: UC.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    ago(n.at),
                    style: const TextStyle(fontSize: 11, color: UC.faint),
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
