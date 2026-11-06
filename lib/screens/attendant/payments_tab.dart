import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'payment_screen.dart';

/// Mobile Money hub: send a prompt to a driver who owes for a charge, follow
/// prompts waiting for approval, and see what has been paid with MoMo.
class PaymentsTab extends StatelessWidget {
  const PaymentsTab({super.key});

  void _open(BuildContext context, ChargeSession s) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentScreen(s, initial: PayMethod.momo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final today = app.todaySessions;
    final owing = today
        .where((s) => s.status == SessionStatus.awaitingPayment)
        .toList();
    final waiting = owing.where(app.awaitingMomo).toList();
    final toPrompt = owing.where((s) => !app.awaitingMomo(s)).toList();
    final paid = today
        .where(
          (s) =>
              s.payMethod == PayMethod.momo &&
              s.paymentStatus == PaymentStatus.confirmed,
        )
        .toList();
    final received = paid.fold<double>(0, (t, s) => t + s.paidAmount);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        PageHeader(
          eyebrow: 'Mobile Money',
          title: 'Payments',
          subtitle: 'Send a prompt and the driver approves on their phone.',
          icon: Icons.phone_android_rounded,
          bottom: Row(
            children: [
              _Figure('Received', money(received)),
              const SizedBox(width: 28),
              _Figure('To collect', '${owing.length}'),
              const SizedBox(width: 28),
              _Figure('Waiting', '${waiting.length}'),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader('Needs payment', 'Send a prompt'),
        const SizedBox(height: 12),
        if (toPrompt.isEmpty)
          const FadeSlideIn(
            index: 1,
            child: Panel(
              child: EmptyState(
                Icons.task_alt_rounded,
                'Nothing to collect',
                'Charges that are finished and unpaid appear here.',
              ),
            ),
          )
        else
          for (var i = 0; i < toPrompt.length; i++)
            FadeSlideIn(
              index: i,
              child: _OwingRow(
                toPrompt[i],
                onSend: () => _open(context, toPrompt[i]),
              ),
            ),
        if (waiting.isNotEmpty) ...[
          const SizedBox(height: 22),
          const SectionHeader('In progress', 'Waiting for approval'),
          const SizedBox(height: 12),
          for (final s in waiting)
            _OwingRow(s, waiting: true, onSend: () => _open(context, s)),
        ],
        const SizedBox(height: 22),
        const SectionHeader('This shift', 'Paid with MoMo'),
        const SizedBox(height: 12),
        if (paid.isEmpty)
          const Panel(
            child: EmptyState(
              Icons.receipt_long_outlined,
              'No MoMo payments yet',
              'Confirmed Mobile Money payments appear here.',
            ),
          )
        else
          Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < paid.length; i++) ...[
                  if (i > 0) const Divider(indent: 68),
                  _PaidRow(paid[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  final String label;
  final String value;
  const _Figure(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11.5),
        ),
      ],
    );
  }
}

class _OwingRow extends StatelessWidget {
  final ChargeSession s;
  final bool waiting;
  final VoidCallback onSend;
  const _OwingRow(this.s, {required this.onSend, this.waiting = false});

  @override
  Widget build(BuildContext context) {
    final failed = s.paymentStatus == PaymentStatus.failed;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Panel(
        padding: const EdgeInsets.all(14),
        onTap: onSend,
        child: Row(
          children: [
            IconTile(
              waiting
                  ? Icons.hourglass_top_rounded
                  : Icons.phone_android_rounded,
              waiting ? UC.warning : (failed ? UC.danger : UC.info),
              size: 40,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.driver.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    waiting
                        ? 'Prompt sent to ${s.momoNumber}'
                        : failed
                        ? 'Last attempt failed · ${s.driver.phone}'
                        : '${s.id} · ${s.driver.phone}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: UC.muted),
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
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                waiting
                    ? const StatusChip('Waiting', UC.warning)
                    : StatusChip(
                        failed ? 'Send again' : 'Send prompt',
                        failed ? UC.danger : UC.info,
                        dot: false,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PaidRow extends StatelessWidget {
  final ChargeSession s;
  const _PaidRow(this.s);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const IconTile(Icons.check_rounded, UC.success, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.driver.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${s.momoNumber.isEmpty ? s.driver.phone : s.momoNumber} · ${s.id}',
                  style: const TextStyle(fontSize: 11.5, color: UC.muted),
                ),
              ],
            ),
          ),
          Text(
            money(s.paidAmount),
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: UC.success,
            ),
          ),
        ],
      ),
    );
  }
}
