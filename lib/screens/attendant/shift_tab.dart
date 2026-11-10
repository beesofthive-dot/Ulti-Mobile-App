import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'off_shift.dart';
import 'session_router.dart';

/// AT-10 My shift: the numbers so far, charges that still need payment (they
/// block closing), and every charge this shift.
class ShiftTab extends StatefulWidget {
  /// Opens the Record a charge tab.
  final VoidCallback onRecord;
  const ShiftTab({super.key, required this.onRecord});

  @override
  State<ShiftTab> createState() => _ShiftTabState();
}

class _ShiftTabState extends State<ShiftTab> {
  final notes = TextEditingController();

  @override
  void dispose() {
    notes.dispose();
    super.dispose();
  }

  /// Charges nobody has acted on: they must be paid or cancelled before the
  /// shift can close.
  List<ChargeSession> _unpaid(AppState app) => app.todaySessions
      .where(
        (s) =>
            s.status == SessionStatus.awaitingPayment &&
            !s.voidRequested &&
            s.paymentStatus != PaymentStatus.pending,
      )
      .toList();

  /// Charges with a payment request out, waiting on the driver.
  List<ChargeSession> _waiting(AppState app) => app.todaySessions
      .where((s) => s.paymentStatus == PaymentStatus.pending)
      .toList();

  Future<void> _close(AppState app) async {
    if (app.activeSessions.isNotEmpty) {
      toast(
        context,
        'Stop all active charges before closing the shift.',
        tone: Tone.warning,
      );
      return;
    }
    final ok = await confirmDialog(
      context,
      title: 'Close shift?',
      confirm: 'Close shift',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KV('Charges', '${app.todaySessions.length}'),
          KV('Collected', money(app.collected)),
          const SizedBox(height: 6),
          Text(
            'Your supervisor reviews any exceptions.',
            style: TextStyle(fontSize: 12, color: UC.muted),
          ),
        ],
      ),
    );
    if (!ok) return;
    app.submitShift(notes.text.trim());
  }

  Future<void> _cancel(AppState app, ChargeSession s) async {
    final reason = await reasonDialog(
      context,
      title: 'Cancel ${s.id}?',
      hint: 'Why was this charge a mistake?',
      confirm: 'Cancel charge',
    );
    if (reason == null) return;
    app.requestVoid(s, reason);
    if (mounted) toast(context, '${s.id} cancelled.', tone: Tone.info);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final sh = app.shift;
    if (sh.startedAt == null) {
      // No shift yet: only records are available until one is started.
      final past = app.records;
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          PageHeader(
            eyebrow: 'Shift · ${app.branch!.name}',
            title: 'Off shift',
            subtitle: 'Scheduled ${app.account?.shiftWindow ?? '—'}',
            icon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 14),
          const OffShiftNotice(),
          const SizedBox(height: 22),
          const SectionHeader('Records', 'Past charges'),
          const SizedBox(height: 10),
          if (past.isEmpty)
            const Panel(
              child: EmptyState(
                Icons.bolt_outlined,
                'No records yet',
                'Charges you record during a shift appear here.',
              ),
            )
          else
            for (var i = 0; i < past.length; i++)
              FadeSlideIn(
                key: ValueKey(past[i].id),
                index: i,
                child: _ChargeRow(past[i]),
              ),
        ],
      );
    }
    final list = [...app.todaySessions]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final unpaid = _unpaid(app);
    final waiting = _waiting(app);
    final waitingAmount = waiting.fold<double>(0, (t, s) => t + s.due);
    final submitted = sh.status != ShiftStatus.active;
    final exceptions = list
        .where(
          (s) =>
              s.status == SessionStatus.exception ||
              s.status == SessionStatus.awaitingReadings ||
              s.paymentStatus == PaymentStatus.failed,
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        PageHeader(
          eyebrow: 'Shift · ${app.branch!.name}',
          title: submitted ? 'Shift closed' : 'Your shift',
          subtitle:
              'Open since ${hm(sh.startedAt!)} on ${sh.charger?.label ?? '—'}',
          icon: submitted ? Icons.task_alt_rounded : Icons.schedule_rounded,
        ),
        const SizedBox(height: 14),
        StatusPanel(shiftInfo(sh.status), sh.endedAt ?? sh.startedAt!),
        const SizedBox(height: 14),
        // ---- numbers ----
        FadeSlideIn(
          index: 1,
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: [
              _Stat('Charges', '${list.length}'),
              _Stat('Energy', '${app.kwhToday.toStringAsFixed(2)} kWh'),
              _Stat('Paid', money(app.collected)),
              _Stat(
                'Waiting',
                waiting.isEmpty
                    ? 'None'
                    : '${waiting.length} · ${money(waitingAmount)}',
              ),
            ],
          ),
        ),
        // ---- cannot close yet ----
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: (!submitted && unpaid.isNotEmpty)
              ? Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _UnpaidBanner(
                    unpaid: unpaid,
                    onOpen: (s) => openSession(context, s),
                    onCancel: (s) => _cancel(app, s),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
        if (exceptions.isNotEmpty) ...[
          const SizedBox(height: 14),
          InfoBanner(
            '${exceptions.length} charge${exceptions.length == 1 ? '' : 's'} need supervisor review: ${exceptions.map((e) => e.id).join(', ')}',
            tone: Tone.danger,
            icon: Icons.flag_outlined,
          ),
        ],
        const SizedBox(height: 16),
        if (!submitted) ...[
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  'Record',
                  leading: Icons.add_rounded,
                  trailing: null,
                  onPressed: widget.onRecord,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: UC.ink,
                      side: BorderSide(color: UC.line),
                      backgroundColor: UC.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: unpaid.isEmpty ? () => _close(app) : null,
                    child: const Text('Close shift'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Notes',
            optional: true,
            hint: 'Explain any variances',
            controller: notes,
            maxLines: 2,
          ),
        ] else ...[
          PrimaryButton(
            'Start next shift',
            leading: Icons.login_rounded,
            trailing: null,
            onPressed: () => startShiftFlow(context),
          ),
          const SizedBox(height: 10),
          GhostButton(
            'Log out',
            icon: Icons.logout_rounded,
            onPressed: () {
              app.resetShift();
              app.signOut();
            },
          ),
        ],
        const SizedBox(height: 22),
        // ---- charges this shift ----
        const SectionHeader('This shift', 'Charges this shift'),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 14, bottom: 10),
          child: Text(
            submitted
                ? 'Tap a charge to see its receipt.'
                : 'Tap a charge to take payment or see its receipt.',
            style: TextStyle(fontSize: 12.5, color: UC.muted),
          ),
        ),
        if (list.isEmpty)
          const Panel(
            child: EmptyState(
              Icons.bolt_outlined,
              'No charges yet',
              'Record the first one when a driver finishes charging.',
            ),
          )
        else
          for (var i = 0; i < list.length; i++)
            FadeSlideIn(
              key: ValueKey(list[i].id),
              index: i,
              child: _ChargeRow(list[i]),
            ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: UC.muted,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: UC.title,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnpaidBanner extends StatelessWidget {
  final List<ChargeSession> unpaid;
  final ValueChanged<ChargeSession> onOpen;
  final ValueChanged<ChargeSession> onCancel;
  const _UnpaidBanner({
    required this.unpaid,
    required this.onOpen,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final n = unpaid.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: UC.warning.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: UC.warning.withValues(alpha: .35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.lock_clock_outlined, size: 20, color: UC.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'You cannot close the shift yet. ',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(
                        text:
                            '$n charge${n == 1 ? ' has' : 's have'} no payment. '
                            'Take payment, or cancel ${n == 1 ? 'it' : 'them'} '
                            'if ${n == 1 ? 'it was a mistake' : 'they were mistakes'}. '
                            'A driver who cannot pay needs your supervisor.',
                      ),
                    ],
                  ),
                  style: TextStyle(fontSize: 12.5, height: 1.45, color: UC.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final s in unpaid)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: UC.surface,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => onOpen(s),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.id,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${s.charger.id} · ${(s.kwh ?? 0).toStringAsFixed(3)} kWh · ${s.driver.name}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: UC.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          money(s.due),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SmallLink(
                          'Cancel',
                          bold: true,
                          onTap: () => onCancel(s),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChargeRow extends StatelessWidget {
  final ChargeSession s;
  const _ChargeRow(this.s);

  @override
  Widget build(BuildContext context) {
    final waiting = s.paymentStatus == PaymentStatus.pending;
    final info = s.voidRequested
        ? const StatusInfo('Cancelled', UC.purple, '', '')
        : s.paymentStatus == PaymentStatus.failed
        ? const StatusInfo('Payment failed', UC.danger, '', '')
        : waiting
        ? const StatusInfo('Waiting for driver', UC.warning, '', '')
        : sessionInfo(s.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Panel(
        padding: const EdgeInsets.all(14),
        onTap: () => openSession(context, s),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.id,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.charger.id} · ${(s.kwh ?? 0).toStringAsFixed(3)} kWh · ${hm(s.startedAt)}',
                    style: TextStyle(fontSize: 11.5, color: UC.muted),
                  ),
                  Text(
                    s.driver.name,
                    style: TextStyle(fontSize: 11.5, color: UC.faint),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  money(s.due),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                StatusChip(info.label, info.color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
