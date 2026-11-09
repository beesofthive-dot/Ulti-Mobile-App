import 'package:flutter/material.dart';

import 'driver/notifications_tab.dart';

/// Notification centre for the bell icon: one feed with everything addressed
/// to the signed-in user.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The same single feed the driver sees in its Alerts tab.
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const NotificationsTab(active: true),
    );
  }
}
