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

/// The notification centre, shared by drivers (Alerts tab) and sales
/// attendants (bell): every notification for the signed-in user, newest
/// first, in one single list. New ones slide in with a
/// brief teal glow, unread ones are marked, and any can be swiped away.
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

  /// Marks everything read after the user has had a moment to see it.
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

  void _dismiss(AppState app, AppNotification n) {
    app.removeNotification(n);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Notification removed'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => app.restoreNotification(n),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final all = app.myNotifications;
    final unread = all.where((n) => !n.read).length;
    _initial ??= all.map((n) => n.id).toSet();
    _scheduleRead(app, unread);
    final shown = all;

    // Day groups, in order, as header + tiles.
    final rows = <Widget>[];
    var k = 0;
    for (final n in shown) {
      rows.add(
        FadeSlideIn(
          key: ValueKey('row-${n.id}'),
          index: math.min(k++, 8),
          offset: 12,
          child: Dismissible(
            key: ValueKey(n.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => _dismiss(app, n),
            background: const _SwipeBg(),
            child: _NoteTile(n: n, fresh: !_initial!.contains(n.id)),
          ),
        ),
      );
    }

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
        const SizedBox(height: 4),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: all.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (unread > 0)
                        SmallLink(
                          'Mark all read',
                          icon: Icons.done_all_rounded,
                          bold: true,
                          onTap: app.markAllRead,
                        ),
                      const SizedBox(width: 8),
                      SmallLink(
                        'Clear all',
                        icon: Icons.delete_sweep_outlined,
                        onTap: app.clearMyNotifications,
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        const SizedBox(height: 4),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          child: shown.isEmpty
              ? Padding(
                  key: const ValueKey('empty'),
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
                        EmptyState(
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
                  key: const ValueKey('list'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rows,
                ),
        ),
      ],
    );
  }
}

/// Red "remove" backdrop revealed while swiping a tile.
class _SwipeBg extends StatelessWidget {
  const _SwipeBg();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.only(right: 22),
    alignment: Alignment.centerRight,
    decoration: BoxDecoration(
      color: UC.danger.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(UC.radius),
    ),
    child: const Icon(Icons.delete_outline_rounded, color: UC.danger),
  );
}

/// One notification. Slides in from the right when it arrives; a fresh one
/// also pulses a teal glow, and an unread one keeps a teal edge and dot.
class _NoteTile extends StatefulWidget {
  final AppNotification n;
  final bool fresh;
  const _NoteTile({required this.n, required this.fresh});

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
