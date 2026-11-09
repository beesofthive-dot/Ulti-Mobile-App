import 'package:flutter/material.dart';

import '../../../models.dart';
import '../../../payments/payment_flow.dart';
import '../../../state.dart';
import '../../../theme.dart';
import '../../../widgets/common.dart';

/// Card payment: the driver's QR card is read on the machine, then paid
/// from the linked balance.
class CardScanPanel extends StatefulWidget {
  final ChargeSession s;
  final VoidCallback onPaid;
  const CardScanPanel({super.key, required this.s, required this.onPaid});

  @override
  State<CardScanPanel> createState() => _CardScanPanelState();
}

class _CardScanPanelState extends State<CardScanPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  bool reading = false;
  bool wrongCard = false; // demo only

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final app = AppScope.read(context);
    final s = widget.s;
    setState(() => reading = true);
    final scanned = wrongCard ? 'UC-0000-0000' : (s.driver.cardId ?? '');
    final r = await app.payWithCard(s, scanned);
    if (!mounted) return;
    setState(() => reading = false);
    if (r == PaymentResult.confirmed) widget.onPaid();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final failed =
        s.payMethod == PayMethod.card &&
        s.paymentStatus == PaymentStatus.failed;
    final card = s.driver.cardId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              SizedBox(
                height: 132,
                child: AnimatedBuilder(
                  animation: pulse,
                  builder: (_, _) => CustomPaint(
                    painter: _ReaderPainter(reading ? 1 : pulse.value),
                    child: Center(
                      child: Icon(
                        reading
                            ? Icons.sync_rounded
                            : Icons.contactless_rounded,
                        size: 44,
                        color: UC.title,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                reading ? 'Reading card…' : 'Scan the QR card on the machine',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card == null
                    ? 'No QR card is linked to ${s.driver.name}.'
                    : 'Expecting card •• ${card.substring(card.length - 4)} · ${s.driver.name}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: UC.muted),
              ),
            ],
          ),
        ),
        if (failed) ...[
          const SizedBox(height: 12),
          InfoBanner(
            s.events.last.label.split(' — ').last,
            tone: Tone.danger,
            icon: Icons.error_outline_rounded,
          ),
        ],
        const SizedBox(height: 14),
        SwitchListTile(
          value: wrongCard,
          onChanged: reading ? null : (v) => setState(() => wrongCard = v),
          title: Text(
            'Demo: scan a different card',
            style: TextStyle(fontSize: 12.5, color: UC.muted),
          ),
        ),
        const SizedBox(height: 6),
        PrimaryButton(
          reading
              ? 'Reading card…'
              : failed
              ? 'Scan again'
              : 'Card scanned on machine',
          leading: Icons.contactless_rounded,
          trailing: null,
          busy: reading,
          onPressed: card == null ? null : _scan,
        ),
      ],
    );
  }
}

/// Soft expanding rings around the reader icon.
class _ReaderPainter extends CustomPainter {
  final double t;
  const _ReaderPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    for (var i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1;
      canvas.drawCircle(
        c,
        34 + 34 * p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = UC.teal.withValues(alpha: (1 - p) * .55),
      );
    }
    canvas.drawCircle(c, 34, Paint()..color = UC.limeSoft);
  }

  @override
  bool shouldRepaint(_ReaderPainter old) => old.t != t;
}
