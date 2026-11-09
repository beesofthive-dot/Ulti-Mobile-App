import 'package:flutter/material.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'common.dart';
import 'motion.dart';

/// Round initials avatar with a teal ring; tapping opens the account sheet.
class AccountAvatar extends StatelessWidget {
  final String initials;
  final VoidCallback onTap;
  final double radius;
  const AccountAvatar({
    super.key,
    required this.initials,
    required this.onTap,
    this.radius = 19,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [UC.teal, UC.brandGreen]),
            ),
            child: CircleAvatar(
              radius: radius,
              backgroundColor: UC.navy,
              child: Text(
                initials,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: radius * .62,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One row of quick actions in the account sheet.
class SheetAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const SheetAction(this.icon, this.label, this.onTap);
}

/// Account sheet for both workspaces: who is signed in, key details,
/// shortcuts and a clearly separated Log out button.
Future<void> showAccountSheet(
  BuildContext context, {
  required String name,
  required String initials,
  required String roleLabel,
  required List<(String, String)> details,
  List<SheetAction> actions = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: UC.surface,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheet) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: heroGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    const HeroGlow(),
                    Row(
                      children: [
                        AccountAvatar(
                          initials: initials,
                          radius: 26,
                          onTap: () {},
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: UC.teal.withValues(alpha: .18),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  roleLabel,
                                  style: const TextStyle(
                                    color: UC.teal,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FadeSlideIn(
              index: 1,
              child: Panel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [for (final (k, v) in details) KV(k, v)],
                ),
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 12),
              FadeSlideIn(
                index: 2,
                child: Panel(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const Divider(indent: 56),
                        InsetTile(
                          leading: IconTile(
                            actions[i].icon,
                            UC.accent,
                            size: 34,
                          ),
                          title: Text(
                            actions[i].label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: UC.faint,
                          ),
                          onTap: () {
                            Navigator.pop(sheet);
                            actions[i].onTap();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FadeSlideIn(
              index: 3,
              child: Panel(
                padding: EdgeInsets.zero,
                child: const DarkModeTile(),
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              index: 4,
              child: GhostButton(
                'Log out',
                icon: Icons.logout_rounded,
                color: UC.danger,
                onPressed: () async {
                  final app = AppScope.read(sheet);
                  final nav = Navigator.of(sheet);
                  final ok = await confirmLogout(sheet);
                  if (!ok) return;
                  nav.pop();
                  app.signOut();
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Asks before logging out; warns an attendant whose shift is still open.
Future<bool> confirmLogout(BuildContext context) {
  final app = AppScope.read(context);
  final openShift =
      app.role == Role.attendant && app.shift.status == ShiftStatus.active;
  return confirmDialog(
    context,
    title: 'Log out?',
    confirm: 'Log out',
    color: UC.danger,
    body: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (openShift) ...[
          const InfoBanner(
            'Your shift is still open. It stays open and continues when you sign back in. To finish for the day, end your shift first.',
            tone: Tone.warning,
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 10),
        ],
        Text(
          openShift ? 'Log out anyway?' : 'You will need your phone number and password to sign in again.',
          style: TextStyle(fontSize: 13.5, color: UC.muted),
        ),
      ],
    ),
  );
}
