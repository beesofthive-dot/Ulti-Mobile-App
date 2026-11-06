import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/account_sheet.dart';
import '../../widgets/common.dart';
import '../../widgets/info_carousel.dart';
import '../../widgets/motion.dart';
import '../../widgets/notification_host.dart';
import '../../widgets/txn_list.dart';
import 'drivers_tab.dart';
import 'payments_tab.dart';
import 'session_router.dart';
import 'shift_tab.dart';
import 'start_charge_tab.dart';

/// Bottom navigation: Today | Charge | Drivers | MoMo | Shift.
class AttendantShell extends StatefulWidget {
  const AttendantShell({super.key});

  @override
  State<AttendantShell> createState() => _AttendantShellState();
}

class _AttendantShellState extends State<AttendantShell>
    with SingleTickerProviderStateMixin {
  int index = 0;
  Driver? preselected;

  // Fades / lifts the tab body in each time the tab changes; IndexedStack
  // keeps each tab's state.
  late final AnimationController tabAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    value: 1,
  );

  void _go(int i) {
    if (i == index) return;
    setState(() => index = i);
    tabAnim.forward(from: 0);
  }

  void _startFor(Driver? d) {
    setState(() => preselected = d);
    _go(1);
  }

  @override
  void dispose() {
    tabAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pages = [
      TodayTab(onQuickStart: () => _startFor(null), onOpenShift: () => _go(4)),
      StartChargeTab(
        key: ValueKey(preselected?.id),
        preselected: preselected,
        onPickDriver: () => _go(2),
      ),
      DriversTab(onStartCharge: _startFor),
      const PaymentsTab(),
      const ShiftTab(),
    ];
    final t = CurvedAnimation(parent: tabAnim, curve: Curves.easeOutCubic);
    return Scaffold(
      appBar: AttendantTopBar(app: app, onOpenShift: () => _go(4)),
      body: FadeTransition(
        opacity: t,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, .025),
            end: Offset.zero,
          ).animate(t),
          child: IndexedStack(index: index, children: pages),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt),
            label: 'Charge',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Drivers',
          ),
          NavigationDestination(
            icon: Icon(Icons.phone_android_outlined),
            selectedIcon: Icon(Icons.phone_android),
            label: 'MoMo',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Shift',
          ),
        ],
      ),
    );
  }
}

/// "Branch name | Shift Active" top bar with connectivity state.
class AttendantTopBar extends StatelessWidget implements PreferredSizeWidget {
  final AppState app;
  final VoidCallback onOpenShift;
  const AttendantTopBar({
    super.key,
    required this.app,
    required this.onOpenShift,
  });

  void _account(BuildContext context) {
    final sh = app.shift;
    final initials = initialsOf(app.attendantName);
    showAccountSheet(
      context,
      name: app.attendantName,
      initials: initials,
      roleLabel: 'SALES ATTENDANT',
      details: [
        ('Phone', app.account?.phone ?? '—'),
        ('Branch', app.branch?.name ?? '—'),
        ('Shift', shiftInfo(sh.status).label),
        if (sh.startedAt != null) ('Clocked in', stamp(sh.startedAt!)),
        if (sh.charger != null) ('Charger', sh.charger!.label),
        ('Connection', app.online ? 'Online' : 'Offline — saving locally'),
      ],
      actions: [
        SheetAction(Icons.schedule_rounded, 'Shift & end of day', onOpenShift),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final info = shiftInfo(app.shift.status);
    final live = app.shift.status == ShiftStatus.active;
    return AppBar(
      toolbarHeight: 64,
      titleSpacing: 20,
      title: Row(
        children: [
          const UcLogo(size: 34, wordmark: false),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.branch!.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: UC.navy,
                  ),
                ),
                Text(
                  app.attendantName,
                  style: const TextStyle(fontSize: 11.5, color: UC.muted),
                ),
              ],
            ),
          ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (live)
                    PulseDot(color: info.color, size: 6)
                  else
                    const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      info.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: info.color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        const NotificationBell(),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: app.online ? 'Online — tap to simulate offline' : 'Offline',
          onPressed: () {
            app.setOnline(!app.online);
            toast(
              context,
              app.online ? 'Back online — local drafts synced' : 'You are offline. Sessions save on this phone until you reconnect.',
              tone: app.online ? Tone.success : Tone.warning,
            );
          },
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
            child: Icon(
              app.online ? Icons.cloud_done_outlined : Icons.cloud_off_rounded,
              key: ValueKey(app.online),
              color: app.online ? UC.success : UC.warning,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14, left: 2),
          child: AccountAvatar(
            initials: initialsOf(app.attendantName),
            radius: 17,
            onTap: () => _account(context),
          ),
        ),
      ],
    );
  }
}

/// AT-03 Today.
class TodayTab extends StatelessWidget {
  final VoidCallback onQuickStart;
  final VoidCallback onOpenShift;
  const TodayTab({
    super.key,
    required this.onQuickStart,
    required this.onOpenShift,
  });

  List<InfoItem> _info(BuildContext context, AppState app) {
    final sh = app.shift;
    final run = app.shiftElapsed;
    final b = app.branch!;
    final unsynced = app.todaySessions.where((s) => !s.synced).length;
    return [
      for (final s in app.attentionSessions.take(3))
        InfoItem(
          icon: s.paymentStatus == PaymentStatus.failed
              ? Icons.error_outline_rounded
              : Icons.flag_outlined,
          color:
              s.status == SessionStatus.exception ||
                  s.paymentStatus == PaymentStatus.failed
              ? UC.danger
              : UC.orange,
          title: '${s.id} needs attention',
          body:
              '${s.paymentStatus == PaymentStatus.failed
                  ? 'Payment failed'
                  : s.voidRequested
                  ? 'Void requested'
                  : sessionInfo(s.status).label} · ${s.driver.name}',
          action: 'Open',
          onTap: () => openSession(context, s),
        ),
      InfoItem(
        icon: Icons.timer_outlined,
        color: UC.info,
        title: 'Shift running ${run.inHours}h ${run.inMinutes % 60}m',
        body:
            'Started ${sh.startedAt == null ? '—' : hm(sh.startedAt!)} on ${sh.charger?.label ?? '—'}',
        action: 'Shift',
        onTap: onOpenShift,
      ),
      InfoItem(
        icon: Icons.payments_outlined,
        color: const Color(0xFF0FB9A5),
        title: 'Tariff ${money(b.tariff)} / kWh',
        body:
            'Expected amount = machine kWh × tariff. Differences are flagged.',
      ),
      if (!app.online)
        InfoItem(
          icon: Icons.cloud_off_rounded,
          color: UC.warning,
          title: 'Offline · $unsynced unsynced',
          body: 'Sessions save on this phone. Card and MoMo need a connection.',
        )
      else
        const InfoItem(
          icon: Icons.cloud_done_outlined,
          color: UC.success,
          title: 'All sessions synced',
          body: 'You are online. Payments confirm in real time.',
        ),
      const InfoItem(
        icon: Icons.lightbulb_outline_rounded,
        color: UC.brandGreen,
        title: 'Tip: watch the charger display',
        body: 'START / STOP only record the time — they do not control the machine.',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final list = app.todaySessions;
    final active = app.activeSessions;
    final now = DateTime.now();
    final greet = now.hour < 12
        ? 'Good morning'
        : now.hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final rest = list.where((s) => s.status != SessionStatus.active).toList();
    final run = app.shiftElapsed;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        InfoCarousel(items: _info(context, app)),
        const SizedBox(height: 14),
        PageHeader(
          eyebrow:
              '${dm(now)} · Shift ${run.inHours}h ${two(run.inMinutes % 60)}m',
          title: '$greet, ${app.attendantName.split(' ').first}',
          subtitle: 'Collected so far this shift',
          icon: Icons.insights_rounded,
          bottom: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CountUp(
                app.collected,
                format: money,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Card and Mobile Money confirmed',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 16),
              PressScale(
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: UC.teal,
                      foregroundColor: UC.navy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    onPressed: onQuickStart,
                    icon: const Icon(Icons.bolt_rounded),
                    label: const Text('Quick start charge'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          // Fixed height so the tiles never squash on narrow phones.
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 120,
          ),
          children: [
            _Stat(
              'Sessions',
              list.length.toDouble(),
              (v) => v.round().toString(),
              Icons.receipt_long_outlined,
              UC.info,
              0,
            ),
            _Stat(
              'Energy',
              app.kwhToday,
              (v) => '${v.toStringAsFixed(1)} kWh',
              Icons.bolt_outlined,
              UC.brandGreen,
              1,
            ),
            _Stat(
              'Pending payments',
              app.pendingPayments.toDouble(),
              (v) => v.round().toString(),
              Icons.hourglass_bottom_rounded,
              UC.orange,
              2,
            ),
            _Stat(
              'Active charges',
              active.length.toDouble(),
              (v) => v.round().toString(),
              Icons.ev_station_outlined,
              UC.purple,
              3,
            ),
          ],
        ),
        const SizedBox(height: 26),
        const SectionHeader('Right now', 'Active charges'),
        const SizedBox(height: 12),
        if (active.isEmpty)
          const FadeSlideIn(
            index: 1,
            child: Panel(
              child: EmptyState(
                Icons.ev_station_outlined,
                'No active charges',
                'Start a charge when a driver plugs in.',
              ),
            ),
          )
        else
          for (var i = 0; i < active.length; i++)
            FadeSlideIn(index: i, child: _SessionRow(active[i])),
        const SizedBox(height: 26),
        const SectionHeader('This shift', 'All sessions'),
        const SizedBox(height: 12),
        if (rest.isEmpty)
          const FadeSlideIn(
            index: 1,
            child: Panel(
              child: EmptyState(
                Icons.receipt_long_outlined,
                'No sessions yet',
                'Sessions you start during this shift appear here.',
              ),
            ),
          )
        else
          FadeSlideIn(
            index: 1,
            child: TransactionList(
              sessions: rest,
              onVerify: (s) => openSession(context, s),
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final double value;
  final String Function(double) format;
  final IconData icon;
  final Color tint;
  final int index;
  const _Stat(
    this.label,
    this.value,
    this.format,
    this.icon,
    this.tint,
    this.index,
  );

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      index: index + 1,
      child: Panel(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                IconTile(icon, tint, size: 32),
                const Spacer(),
                Container(
                  width: 18,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: .35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CountUp(
                  value,
                  format: format,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: UC.navy,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11.5, color: UC.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  final ChargeSession s;
  const _SessionRow(this.s);

  @override
  Widget build(BuildContext context) {
    final info = sessionInfo(s.status);
    final pending = s.paymentStatus == PaymentStatus.failed
        ? const StatusInfo('Payment failed', UC.danger, '', '')
        : s.voidRequested
        ? const StatusInfo('Void requested', UC.purple, '', '')
        : info;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Panel(
        padding: const EdgeInsets.all(14),
        onTap: () => openSession(context, s),
        child: Row(
          children: [
            IconTile(Icons.bolt_rounded, info.color, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          s.driver.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (!s.synced) ...[
                        const SizedBox(width: 6),
                        const OfflineBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.id} · ${s.charger.id} · ${hm(s.startedAt)}',
                    style: const TextStyle(fontSize: 11.5, color: UC.muted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  s.status == SessionStatus.active
                      ? clock(s.elapsed)
                      : money(s.due),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                StatusChip(pending.label, pending.color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
