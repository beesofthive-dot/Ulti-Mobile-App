import 'dart:async';

import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

/// AT-02 Clock in.
class ClockInScreen extends StatefulWidget {
  const ClockInScreen({super.key});

  @override
  State<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends State<ClockInScreen> {
  late Timer _t;
  DateTime now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final b = app.branch!;
    final charger = app.assignedCharger ?? b.chargers.first;
    return Scaffold(
      appBar: AppBar(
        title: Text(b.name),
        actions: [
          TextButton.icon(
            onPressed: app.signOut,
            icon: Icon(Icons.logout_rounded, size: 18, color: UC.muted),
            label: Text('Log out', style: TextStyle(color: UC.muted)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          PageHeader(
            eyebrow: 'Start of shift · ${b.name}',
            title:
                'Good ${now.hour < 12
                    ? 'morning'
                    : now.hour < 17
                    ? 'afternoon'
                    : 'evening'}, ${app.attendantName.split(' ').first}',
            subtitle:
                'Your terminal and shift are ready. Start when you arrive.',
            icon: Icons.badge_outlined,
            bottom: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: .1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Attendance time',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hm(now).replaceFirst(' ', ':${two(now.second)} '),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          '${dmy(now)} · server time is recorded',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusChip.of(shiftInfo(ShiftStatus.notStarted)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'Assigned terminal',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ChoiceCard(
            selected: true,
            icon: Icons.ev_station_outlined,
            title: charger.label,
            subtitle: '${b.name} · ${money(b.tariff)}/kWh · assigned to you',
          ),
          const SizedBox(height: 10),
          Panel(
            child: Column(
              children: [
                KV('Scheduled shift', app.account?.shiftWindow ?? '—'),
                KV(
                  'Opening reading',
                  '${(app.account?.openingReading ?? 0).toStringAsFixed(1)} kWh',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Terminal, shift times and the opening reading are set by your '
            'supervisor. You do not need to enter anything.',
            style: TextStyle(fontSize: 12, color: UC.muted),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            'Start shift',
            leading: Icons.login_rounded,
            onPressed: app.clockIn,
          ),
        ],
      ),
    );
  }
}
