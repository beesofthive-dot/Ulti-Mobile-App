import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

/// AT-10 End shift.
class ShiftTab extends StatefulWidget {
  const ShiftTab({super.key});

  @override
  State<ShiftTab> createState() => _ShiftTabState();
}

class _ShiftTabState extends State<ShiftTab> {
  final notes = TextEditingController();

  Future<void> _submit(AppState app) async {
    if (app.activeSessions.isNotEmpty) {
      toast(
        context,
        'Stop all active charges before ending the shift.',
        tone: Tone.warning,
      );
      return;
    }
    final ok = await confirmDialog(
      context,
      title: 'Submit shift?',
      confirm: 'Submit',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KV('Sessions', '${app.todaySessions.length}'),
          KV('Collected', money(app.collected)),
          const SizedBox(height: 6),
          const Text(
            'Your supervisor reviews any exceptions.',
            style: TextStyle(fontSize: 12, color: UC.muted),
          ),
        ],
      ),
    );
    if (!ok) return;
    app.submitShift(notes.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final sh = app.shift;
    final list = app.todaySessions;
    final exceptions = list
        .where(
          (s) =>
              s.status == SessionStatus.exception ||
              s.status == SessionStatus.awaitingReadings ||
              s.voidRequested ||
              s.paymentStatus == PaymentStatus.failed,
        )
        .toList();
    final submitted = sh.status != ShiftStatus.active;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        PageHeader(
          eyebrow: 'Shift · ${app.branch!.name}',
          title: submitted ? 'Shift submitted' : 'End shift',
          subtitle:
              'Clocked in ${hm(sh.startedAt!)} on ${sh.charger?.label ?? '—'}',
          icon: submitted ? Icons.task_alt_rounded : Icons.schedule_rounded,
        ),
        const SizedBox(height: 14),
        StatusPanel(shiftInfo(sh.status), sh.endedAt ?? sh.startedAt!),
        const SizedBox(height: 14),
        Panel(
          child: Column(
            children: [
              KV('Clocked in', stamp(sh.startedAt!)),
              KV('Assigned charger', sh.charger?.label ?? '—'),
              KV('Scheduled shift', app.account?.shiftWindow ?? '—'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('Transaction summary'),
              const SizedBox(height: 8),
              KV('Sessions', '${list.length}'),
              KV('Energy recorded', '${app.kwhToday.toStringAsFixed(2)} kWh'),
              KV('Collected (card + MoMo)', money(app.collected)),
              KV('Pending payments', '${app.pendingPayments}'),
            ],
          ),
        ),
        if (exceptions.isNotEmpty) ...[
          const SizedBox(height: 14),
          InfoBanner(
            '${exceptions.length} session${exceptions.length == 1 ? '' : 's'} need supervisor review: ${exceptions.map((e) => e.id).join(', ')}',
            tone: Tone.danger,
            icon: Icons.flag_outlined,
          ),
        ],
        const SizedBox(height: 18),
        if (!submitted) ...[
          LabeledField(
            label: 'Notes',
            optional: true,
            hint: 'Explain any variances',
            controller: notes,
            maxLines: 2,
          ),
          const SizedBox(height: 22),
          PrimaryButton('Submit shift', onPressed: () => _submit(app)),
        ] else ...[
          PrimaryButton(
            'Log out',
            trailing: Icons.logout_rounded,
            onPressed: () {
              app.resetShift();
              app.signOut();
            },
          ),
        ],
      ],
    );
  }
}
