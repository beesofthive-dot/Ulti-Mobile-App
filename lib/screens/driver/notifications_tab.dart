import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models.dart';
import '../../notifications/app_notification.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import '../../widgets/notification_host.dart';

/// Driver "Alerts" tab: every notification the driver receives, newest first.
/// New ones slide in with a brief teal glow; unread ones are marked until the
/// tab has been looked at for a moment.
class NotificationsTab extends StatefulWidget {
  final bool active;
  const NotificationsTab({super.key, required this.active});

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> {
  Set<int>? _initial; // ids that existed before this tab first built
  Timer? _readTimer;

  @override
  void dispose() {
    _readTimer?.cancel();
    super.dispose();
  }

  /// Marks everything read after the driver has had a moment to see it.
  void _scheduleRead(AppState app, int unread) {
    if (!widget.active || unread == 0) {
      _readTimer?.cancel();
      _readTimer = null;
      return;
    }
    _readTimer ??= Timer(const Duration(milliseconds: 2200), () {
      _readTimer = null;
      if (mounted && widget.active) app.markAllRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    // One feed: payments, charges, security and account events together,
    // newest first.
    final all = app.myNotifications;
    final unread = all.where((n) => !n.read).length;
    _initial ??= all.map((n) => n.id).toSet();
    _scheduleRead(app, unread);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        PageHeader(
          eyebrow: 'Inbox',
          title: 'Notifications',
          subtitle: unread > 0
              ? '$unread new ${unread == 1 ? 'update' : 'updates'} for you'
              : "You're all caught up",
          icon: Icons.notifications_active_rounded,
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: unread > 0
              ? Align(
                  alignment: Alignment.centerRight,
                  child: SmallLink(
                    'Mark all read',
                    icon: Icons.done_all_rounded,
                    bold: true,
                    onTap: app.markAllRead,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 4),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: all.isEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Panel(
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Bob(
                          child: IconTile(
                            Icons.notifications_none_rounded,
                            UC.accent,
                            size: 60,
                          ),
                        ),
                        const EmptyState(
                          Icons.notifications_off_outlined,
                          'No notifications yet',
                          'Payments, charges and account activity will '
                              'appear here the moment they happen.',
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final n in all)
                      _NoteTile(
                        key: ValueKey(n.id),
                        n: n,
                        fresh: !_initial!.contains(n.id),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// One notification. Slides in from the right when it arrives; a fresh one
/// also pulses a teal glow, and an unread one keeps a teal edge and dot.
class _NoteTile extends StatefulWidget {
  final AppNotification n;
  final bool fresh;
  const _NoteTile({super.key, required this.n, required this.fresh});

  @override
  State<_NoteTile> createState() => _NoteTileState();
}

class _NoteTileState extends State<_NoteTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.fresh ? 1400 : 520),
  )..forward();

  late final Animation<double> slide = CurvedAnimation(
    parent: c,
    curve: Interval(
      0,
      widget.fresh ? .35 : 1,
      curve: widget.fresh ? Curves.easeOutBack : Curves.easeOutCubic,
    ),
  );

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.n;
    final (color, _) = toneStyle(n.tone);
    final icon = n.isMoney
        ? Icons.payments_outlined
        : n.category == NoteCategory.session
        ? Icons.bolt_rounded
        : Icons.notifications_none_rounded;
    return AnimatedBuilder(
      animation: c,
      builder: (context, child) {
        final s = slide.value.clamp(0.0, 1.2);
        // Glow fades out over the second half of a fresh tile's animation.
        final glow = widget.fresh
            ? (1 -
                      Curves.easeOut.transform(
                        ((c.value - .3) / .7).clamp(0, 1),
                      )) *
                  math.min(1, c.value * 4)
            : 0.0;
        return Opacity(
          opacity: s.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(40 * (1 - s), 0),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(UC.radius),
                boxShadow: [
                  if (glow > 0)
                    BoxShadow(
                      color: UC.teal.withValues(alpha: .55 * glow),
                      blurRadius: 22 * glow,
                      spreadRadius: 1.5 * glow,
                    ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: Panel(
        padding: EdgeInsets.zero,
        borderColor: n.read ? null : UC.teal.withValues(alpha: .55),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: n.read ? 0 : 4,
                color: UC.teal,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconTile(icon, color, size: 40),
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
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: n.read
                                          ? FontWeight.w700
                                          : FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (!n.read) const _PulseDot(),
                              ],
                            ),
                            if (n.body.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                n.body,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: UC.muted,
                                ),
                              ),
                            ],
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  switch (n.category) {
                                    NoteCategory.money => 'Payment',
                                    NoteCategory.session => 'Charging',
                                    NoteCategory.system => 'Account',
                                  },
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                                Text(
                                  '  ·  ${ago(n.at)}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: UC.faint,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small red unread dot that gently pulses.
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(
          color: UC.danger,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: UC.danger.withValues(alpha: .5 * (1 - c.value)),
              blurRadius: 2 + 8 * c.value,
              spreadRadius: 3 * c.value,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom-nav bell: shows the unread count and rings whenever a new
/// notification arrives.
class AlertNavIcon extends StatefulWidget {
  final bool selected;
  const AlertNavIcon({super.key, required this.selected});

  @override
  State<AlertNavIcon> createState() => _AlertNavIconState();
}

class _AlertNavIconState extends State<AlertNavIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  int _last = 0;

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unread = AppScope.of(context).unreadCount;
    if (unread > _last) c.forward(from: 0);
    _last = unread;
    return AnimatedBuilder(
      animation: c,
      builder: (context, child) {
        // Damped swing around the top of the bell.
        final t = c.value;
        final angle = math.sin(t * math.pi * 6) * .42 * (1 - t);
        return Transform.rotate(
          angle: angle,
          alignment: Alignment.topCenter,
          child: child,
        );
      },
      child: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 9 ? '9+' : '$unread'),
        backgroundColor: UC.danger,
        child: Icon(
          widget.selected
              ? Icons.notifications_rounded
              : Icons.notifications_none_rounded,
        ),
      ),
    );
  }
}
