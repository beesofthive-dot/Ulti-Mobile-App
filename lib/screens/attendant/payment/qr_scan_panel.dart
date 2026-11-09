import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models.dart';
import '../../../payments/payment_flow.dart';
import '../../../state.dart';
import '../../../theme.dart';
import '../../../widgets/common.dart';

/// Collect by scanning the driver's QR (Pay in their app). The scan sends the
/// driver a payment request; once they approve it, the amount is taken from
/// their wallet and both sides are notified.
class QrScanPanel extends StatefulWidget {
  final ChargeSession s;
  final VoidCallback onPaid;
  const QrScanPanel({super.key, required this.s, required this.onPaid});

  @override
  State<QrScanPanel> createState() => _QrScanPanelState();
}

class _QrScanPanelState extends State<QrScanPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat(reverse: true);
  Timer? tick;
  bool reading = false;
  // Demo: with no real phone around, pretend the driver is showing their QR.
  bool demoPhone = true;
  int left = PaymentFlow.qrTimeout.inSeconds;

  @override
  void initState() {
    super.initState();
    tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final app = AppScope.read(context);
      if (app.awaitingQr(widget.s)) {
        setState(() => left = left > 0 ? left - 1 : 0);
      }
    });
  }

  @override
  void dispose() {
    tick?.cancel();
    sweep.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final app = AppScope.read(context);
    final s = widget.s;
    setState(() {
      reading = true;
      left = PaymentFlow.qrTimeout.inSeconds;
    });
    // The camera read: whatever QR the driver has on screen right now.
    var scanned = app.liveQrPayload(s.driver) ?? '';
    if (scanned.isEmpty && demoPhone) scanned = app.showDriverQr(s.driver);
    final r = await app.requestQrPayment(s, scanned);
    if (!mounted) return;
    setState(() => reading = false);
    if (r == PaymentResult.confirmed) widget.onPaid();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = widget.s;
    final waiting = app.awaitingQr(s);
    final busy = reading || waiting;
    final failed =
        s.payMethod == PayMethod.wallet &&
        s.paymentStatus == PaymentStatus.failed;
    final first = s.driver.name.split(' ').first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
          child: Column(
            children: [
              SizedBox(
                width: 168,
                height: 168,
                child: AnimatedBuilder(
                  animation: sweep,
                  builder: (_, _) => CustomPaint(
                    painter: _ViewfinderPainter(
                      sweep.value,
                      busy,
                      UC.accent,
                      UC.teal,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          waiting
                              ? Icons.hourglass_top_rounded
                              : reading
                              ? Icons.sync_rounded
                              : Icons.qr_code_2_rounded,
                          key: ValueKey('$waiting$reading'),
                          size: 58,
                          color: waiting ? UC.accent : UC.faint,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                waiting
                    ? 'Waiting for $first to approve'
                    : reading
                    ? 'Reading QR…'
                    : "Scan $first's QR",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                waiting
                    ? '${money(s.due)} was sent to $first\'s app. They approve '
                          'it there and it is taken from their wallet. '
                          'Expires in ${left}s.'
                    : 'The driver opens Pay in the Ulti Charge app. Scanning '
                          'sends them a payment request to approve.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, height: 1.4, color: UC.muted),
              ),
              if (waiting) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: left / PaymentFlow.qrTimeout.inSeconds,
                    minHeight: 5,
                    color: left <= 10 ? UC.orange : UC.teal,
                    backgroundColor: UC.line,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (failed && !busy) ...[
          const SizedBox(height: 12),
          InfoBanner(
            s.events.last.label.split(' — ').last,
            tone: Tone.danger,
            icon: Icons.error_outline_rounded,
          ),
        ],
        if (!busy) ...[
          const SizedBox(height: 6),
          SwitchListTile(
            value: demoPhone,
            onChanged: (v) => setState(() => demoPhone = v),
            title: Text(
              'Demo: driver’s phone is showing their QR',
              style: TextStyle(fontSize: 12.5, color: UC.muted),
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (waiting)
          GhostButton(
            'Cancel request',
            icon: Icons.close_rounded,
            onPressed: () => app.cancelQrPayment(s),
          )
        else
          PrimaryButton(
            reading
                ? 'Reading QR…'
                : failed
                ? 'Scan again'
                : 'Scan driver QR',
            leading: Icons.qr_code_scanner_rounded,
            trailing: null,
            busy: reading,
            onPressed: _scan,
          ),
      ],
    );
  }
}

/// Corner brackets and a sweeping scan line.
class _ViewfinderPainter extends CustomPainter {
  final double t;
  final bool reading;
  final Color frame;
  final Color line;
  const _ViewfinderPainter(this.t, this.reading, this.frame, this.line);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = frame
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const l = 30.0;
    final w = size.width, h = size.height;
    void corner(double x, double y, double dx, double dy) {
      canvas.drawLine(Offset(x, y), Offset(x + dx * l, y), p);
      canvas.drawLine(Offset(x, y), Offset(x, y + dy * l), p);
    }

    corner(2, 2, 1, 1);
    corner(w - 2, 2, -1, 1);
    corner(2, h - 2, 1, -1);
    corner(w - 2, h - 2, -1, -1);

    final y = 14 + (h - 28) * (reading ? 1 - (t * 2 % 1) : t);
    final glow = Paint()
      ..shader = LinearGradient(
        colors: [line.withValues(alpha: 0), line, line.withValues(alpha: 0)],
      ).createShader(Rect.fromLTWH(10, y - 2, w - 20, 4))
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(12, y), Offset(w - 12, y), glow);
    canvas.drawRect(
      Rect.fromLTWH(12, y - 16, w - 24, 16),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [line.withValues(alpha: .18), line.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(12, y - 16, w - 24, 16)),
    );
  }

  @override
  bool shouldRepaint(_ViewfinderPainter o) =>
      o.t != t || o.reading != reading || o.frame != frame;
}
