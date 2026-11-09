import 'dart:async';

import 'package:flutter/material.dart';

import '../notifications/app_notification.dart';
import '../screens/notifications_screen.dart';
import '../state.dart';
import '../theme.dart';

/// Shows the current [AppState.banner] at the top of the app: slides in,
/// dismisses itself, and can be swiped away. Tapping a saved notification
/// opens the notification centre.
class NotificationHost extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;
  const NotificationHost({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  @override
  State<NotificationHost> createState() => _NotificationHostState();
}

class _NotificationHostState extends State<NotificationHost> {
  Timer? _timer;
  int? _shownId;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Starts the auto-dismiss timer once per new banner.
  void _arm(AppState app, AppNotification? n) {
    if (n?.id == _shownId) return;
    _shownId = n?.id;
    _timer?.cancel();
    if (n == null) return;
    final seconds = n.tone == Tone.danger || n.tone == Tone.warning ? 6 : 4;
    _timer = Timer(Duration(seconds: seconds), app.dismissBanner);
  }

  void _open(AppState app, AppNotification n) {
    app.dismissBanner();
    if (!n.persist) return;
    widget.navigatorKey.currentState?.push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final n = app.banner;
    _arm(app, n);
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween(
                  begin: const Offset(0, -1.2),
                  end: Offset.zero,
                ).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: n == null
                  ? const SizedBox.shrink(key: ValueKey('none'))
                  : Padding(
                      key: ValueKey(n.id),
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: GestureDetector(
                        onTap: () => _open(app, n),
                        onVerticalDragEnd: (d) {
                          if ((d.primaryVelocity ?? 0) < -150) {
                            app.dismissBanner();
                          }
                        },
                        child: NotificationCard(n, onClose: app.dismissBanner),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Colour and icon for a notification tone.
(Color, IconData) toneStyle(Tone t) => switch (t) {
  Tone.success => (UC.success, Icons.check_circle_rounded),
  Tone.warning => (UC.warning, Icons.warning_amber_rounded),
  Tone.danger => (UC.danger, Icons.error_rounded),
  Tone.info || Tone.neutral => (UC.info, Icons.info_rounded),
};

/// The banner card: tinted background, tone icon, title, detail, close.
class NotificationCard extends StatelessWidget {
  final AppNotification n;
  final VoidCallback onClose;
  const NotificationCard(this.n, {super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = toneStyle(n.tone);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
        decoration: BoxDecoration(
          color: Color.alphaBlend(color.withValues(alpha: .09), UC.surface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .35)),
          boxShadow: [
            BoxShadow(
              color: UC.navy.withValues(alpha: .16),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    n.title,
                    style: TextStyle(
                      color: color,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (n.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      n.body,
                      style: TextStyle(
                        color: UC.ink,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // No tooltip here: this banner sits above the Navigator, so there
            // is no Overlay for a tooltip to use.
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
              icon: Icon(Icons.close_rounded, color: UC.muted, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bell with an unread badge; opens the notification centre.
class NotificationBell extends StatelessWidget {
  /// Overrides the default (opening the notifications page).
  final VoidCallback? onTap;
  const NotificationBell({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final unread = app.unreadCount;
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: 'Notifications',
      onPressed:
          onTap ??
          () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const NotificationsScreen(),
            ),
          ),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text('$unread'),
        backgroundColor: UC.danger,
        child: Icon(Icons.notifications_none_rounded, color: UC.muted),
      ),
    );
  }
}
