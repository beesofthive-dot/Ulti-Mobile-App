import 'package:flutter/material.dart';

import '../../models.dart';
import '../../payments/payment_rules.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'payment/card_scan_panel.dart';
import 'payment/momo_prompt_panel.dart';
import 'receipt_screen.dart';

/// AT-08 Collect payment: scan the driver's QR card on the machine, or send
/// a Mobile Money prompt to the driver's phone.
class PaymentScreen extends StatefulWidget {
  final ChargeSession s;

  /// Method to open on; defaults to QR card if one was already used.
  final PayMethod? initial;
  const PaymentScreen(this.s, {super.key, this.initial});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late PayMethod method =
      widget.initial ??
      (widget.s.payMethod == PayMethod.card ? PayMethod.card : PayMethod.momo);

  void _paid() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ReceiptScreen(widget.s)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = widget.s;
    final busy = app.awaitingMomo(s);
    final methods = PaymentRules.methodsFor(PaymentParty.sales);
    return Scaffold(
      appBar: AppBar(title: const Text('Collect payment')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          _AmountCard(s),
          if (s.varianceFlag) ...[
            const SizedBox(height: 12),
            InfoBanner(
              'Variance of ${(s.variance ?? 0).toStringAsFixed(2)} GH₵ flagged. Payment can be collected; the session stays under supervisor review.',
              tone: Tone.danger,
              icon: Icons.flag_outlined,
            ),
          ],
          if (!app.online) ...[
            const SizedBox(height: 12),
            const InfoBanner(
              'You are offline. Card and Mobile Money payments need a connection.',
              tone: Tone.warning,
              icon: Icons.cloud_off_rounded,
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Payment method',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final m in methods) ...[
                if (m != methods.first) const SizedBox(width: 8),
                Expanded(
                  child: ChoiceCard(
                    selected: method == m,
                    icon: m == PayMethod.card
                        ? Icons.contactless_rounded
                        : Icons.phone_android_rounded,
                    title: m == PayMethod.card ? 'QR card' : 'MoMo',
                    subtitle: m == PayMethod.card
                        ? 'Scan on machine'
                        : 'Prompt to phone',
                    enabled: !busy,
                    onTap: busy ? null : () => setState(() => method = m),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey(method),
              child: method == PayMethod.card
                  ? CardScanPanel(s: s, onPaid: _paid)
                  : MomoPromptPanel(s: s, onPaid: _paid),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Idempotency key · ${s.idempotencyKey}',
            style: const TextStyle(fontSize: 11, color: UC.faint),
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  final ChargeSession s;
  const _AmountCard(this.s);

  @override
  Widget build(BuildContext context) {
    final failed = s.paymentStatus == PaymentStatus.failed;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: UC.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                failed ? 'Unpaid balance' : 'Amount due',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const Spacer(),
              if (s.paymentStatus != null)
                StatusChip.of(paymentInfo(s.paymentStatus!)),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            money(s.due),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${s.id} · ${(s.kwh ?? 0).toStringAsFixed(2)} kWh · ${s.driver.name}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
