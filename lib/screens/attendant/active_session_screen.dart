import 'dart:async';

import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/receipt.dart';
import 'stop_charge_screen.dart';

/// AT-06 Active session.
class ActiveSessionScreen extends StatefulWidget {
  final ChargeSession s;
  const ActiveSessionScreen(this.s, {super.key});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  late Timer _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = widget.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.id),
        actions: [
          if (!s.synced)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: OfflineBadge(),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
            decoration: BoxDecoration(
              color: UC.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    StatusChip.of(sessionInfo(s.status)),
                    const Spacer(),
                    Text(
                      'Started ${hm(s.startedAt)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _Pulse(),
                const SizedBox(height: 16),
                const Text(
                  'Elapsed time',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  clock(s.elapsed),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              children: [
                KV('Driver', s.driver.name),
                KV('Vehicle', s.driver.plate),
                KV('Branch', s.branch.name),
                KV('Charger', s.charger.label),
                KV('Tariff', '${money(s.tariff)} / kWh'),
                if (s.startReading != null)
                  KV(
                    'Starting reading',
                    '${s.startReading!.toStringAsFixed(1)} kWh',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const InfoBanner(
            'Timer is software-only. Watch the charger display — it is not connected to this app and will not stop automatically.',
          ),
          if (s.voidRequested) ...[
            const SizedBox(height: 10),
            InfoBanner(
              'Void requested: "${s.voidReason}". Awaiting manager approval.',
              tone: Tone.warning,
              icon: Icons.hourglass_top_rounded,
            ),
          ],
          const SizedBox(height: 14),
          EventTrail(s),
          const SizedBox(height: 14),
          if (!s.voidRequested)
            GhostButton(
              'Void request',
              icon: Icons.block_rounded,
              color: UC.danger,
              onPressed: () async {
                final r = await reasonDialog(
                  context,
                  title: 'Request void',
                  hint: 'Why was this session started by mistake?',
                );
                if (r != null) {
                  app.requestVoid(s, r);
                  if (context.mounted) {
                    toast(
                      context,
                      'Void request sent to your supervisor',
                      tone: Tone.success,
                    );
                  }
                }
              },
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: PrimaryButton(
            'STOP CHARGE',
            leading: Icons.stop_rounded,
            trailing: null,
            height: 58,
            color: UC.danger,
            onPressed: () {
              app.stopSession(s);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => StopChargeScreen(s)),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse();
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, _) => Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 64 + 36 * c.value,
            height: 64 + 36 * c.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: UC.lime.withValues(alpha: .25 * (1 - c.value)),
            ),
          ),
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: UC.lime,
            ),
            child: const Icon(Icons.bolt_rounded, size: 34, color: UC.primary),
          ),
        ],
      ),
    );
  }
}
