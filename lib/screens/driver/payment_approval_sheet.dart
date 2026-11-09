import 'dart:async';

import 'package:flutter/material.dart';

import '../../models.dart';
import '../../payments/payment_flow.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

/// Shown on the driver's phone when an attendant asks them to pay: either
/// they scanned the driver's QR (paid from the wallet) or sent a Mobile
/// Money prompt (approved with the MoMo PIN). Pay / Decline, then the result.
Future<void> showPaymentApproval(BuildContext context, ChargeSession s) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: UC.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _ApprovalSheet(s),
  );
}

class _ApprovalSheet extends StatefulWidget {
  final ChargeSession s;
  const _ApprovalSheet(this.s);

  @override
  State<_ApprovalSheet> createState() => _ApprovalSheetState();
}

class _ApprovalSheetState extends State<_ApprovalSheet> {
  final pin = TextEditingController();
  Timer? tick;
  late final bool momo;
  late final DateTime deadline;
  int left = 0;
  bool answered = false;
  bool closing = false;

  Duration get _window =>
      momo ? PaymentFlow.momoTimeout : PaymentFlow.qrTimeout;

  @override
  void initState() {
    super.initState();
    final app = AppScope.read(context);
    momo = app.awaitingMomo(widget.s);
    deadline =
        (momo ? app.momoDeadline(widget.s) : null) ??
        DateTime.now().add(_window);
    void update() {
      final l = deadline.difference(DateTime.now()).inSeconds;
      left = l < 0 ? 0 : l;
    }

    update();
    tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(update);
    });
  }

  @override
  void dispose() {
    tick?.cancel();
    pin.dispose();
    super.dispose();
  }

  void _approve(AppState app) {
    setState(() => answered = true);
    if (momo) {
      app.approveMomo(widget.s);
    } else {
      app.approveQrPayment(widget.s);
    }
  }

  void _decline(AppState app) {
    if (momo) {
      app.declineMomo(widget.s);
    } else {
      app.declineQrPayment(widget.s);
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = widget.s;
    final pending = app.awaitingQr(s) || app.awaitingMomo(s);
    // Resolved (by me, the timer, or the attendant cancelling): show the
    // outcome for a moment, then close.
    if (!pending && !closing) {
      closing = true;
      final nav = Navigator.of(context);
      Future.delayed(const Duration(milliseconds: 1700), () {
        if (mounted) nav.pop();
      });
    }
    final paid = s.paymentStatus == PaymentStatus.confirmed;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: pending ? _request(s, app) : _result(s, paid),
          ),
        ),
      ),
    );
  }

  Widget _request(ChargeSession s, AppState app) {
    final after = s.driver.walletBalance - s.due;
    final canApprove = !answered && (!momo || pin.text.length == 4);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FadeSlideIn(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: heroGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                const BrandRings(strength: 1.4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(
                      momo ? 'Mobile Money request' : 'Payment request',
                      color: UC.teal,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      money(s.due),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(s.kwh ?? 0).toStringAsFixed(2)} kWh · ${s.branch.name} · ${s.id}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          index: 1,
          child: Panel(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: momo
                  ? [
                      KV('Paying with', 'Mobile Money'),
                      KV('MoMo number', s.momoNumber),
                      KV('Amount', money(s.due), strong: true),
                    ]
                  : [
                      KV('Paying from', 'Ulti wallet'),
                      KV('Wallet balance', money(s.driver.walletBalance)),
                      KV('Balance after', money(after), strong: true),
                    ],
            ),
          ),
        ),
        if (momo) ...[
          const SizedBox(height: 14),
          FadeSlideIn(
            index: 2,
            child: LabeledField(
              label: 'MoMo PIN',
              hint: '••••',
              icon: Icons.lock_outline_rounded,
              controller: pin,
              obscure: true,
              keyboardType: TextInputType.number,
              helper: 'Demo: any 4 digits approves.',
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
        const SizedBox(height: 14),
        FadeSlideIn(
          index: 3,
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (left / _window.inSeconds).clamp(0.0, 1.0),
                    minHeight: 5,
                    color: left <= 15 ? UC.orange : UC.teal,
                    backgroundColor: UC.line,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 12, color: UC.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          index: 4,
          child: PrimaryButton(
            momo ? 'Approve ${money(s.due)}' : 'Pay ${money(s.due)}',
            leading: Icons.lock_outline_rounded,
            trailing: null,
            busy: answered,
            onPressed: canApprove ? () => _approve(app) : null,
          ),
        ),
        const SizedBox(height: 10),
        GhostButton(
          'Decline',
          color: UC.danger,
          onPressed: answered ? null : () => _decline(app),
        ),
      ],
    );
  }

  Widget _result(ChargeSession s, bool paid) {
    final color = paid ? UC.success : UC.danger;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 650),
            curve: Curves.elasticOut,
            builder: (_, v, child) => Transform.scale(scale: v, child: child),
            child: Icon(
              paid ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 84,
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            paid ? 'Payment successful' : 'Payment not made',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            paid
                ? (momo
                      ? '${money(s.due)} was paid with Mobile Money.'
                      : '${money(s.due)} was taken from your wallet.')
                : (momo
                      ? 'Nothing was taken from your MoMo.'
                      : 'Nothing was taken from your wallet.'),
            style: TextStyle(fontSize: 13, color: UC.muted),
          ),
        ],
      ),
    );
  }
}
