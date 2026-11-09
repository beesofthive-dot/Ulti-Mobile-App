import 'package:flutter/material.dart';

import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

/// Shown to an attendant whose terminal has not been assigned yet.
class AwaitingAssignmentScreen extends StatelessWidget {
  const AwaitingAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const UcLogo(size: 28),
        actions: [
          TextButton.icon(
            onPressed: app.signOut,
            icon: Icon(Icons.logout_rounded, size: 18, color: UC.muted),
            label: Text('Log out', style: TextStyle(color: UC.muted)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        children: [
          PageHeader(
            eyebrow: 'Sales attendant',
            title: 'Hi ${app.attendantName.split(' ').first}',
            subtitle: 'Your terminal is assigned by your supervisor.',
            icon: Icons.storefront_rounded,
          ),
          const SizedBox(height: 22),
          const Panel(
            child: EmptyState(
              Icons.store_outlined,
              'No terminal assigned',
              'Ask your supervisor to assign you a branch, then sign in again.',
            ),
          ),
        ],
      ),
    );
  }
}
