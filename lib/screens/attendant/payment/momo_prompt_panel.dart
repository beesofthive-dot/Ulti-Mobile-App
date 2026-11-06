import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models.dart';
import '../../../payments/payment_flow.dart';
import '../../../payments/payment_rules.dart';
import '../../../state.dart';
import '../../../theme.dart';
import '../../../widgets/common.dart';

/// Mobile Money: the attendant sends a prompt to the driver's phone and
/// waits while the driver approves it with their MoMo PIN.
class MomoPromptPanel extends StatefulWidget {
  final ChargeSession s;
  final VoidCallback onPaid;
  const MomoPromptPanel({super.key, required this.s, required this.onPaid});

  @override
  State<MomoPromptPanel> createState() => _MomoPromptPanelState();
}

class _MomoPromptPanelState extends State<MomoPromptPanel> {
  late final number = TextEditingController(text: widget.s.driver.phone);
  MomoOutcome demo = MomoOutcome.approve; // demo only
  String? numberErr;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(seconds: 1),
      (_) => mounted ? setState(() {}) : null,
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    number.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final app = AppScope.read(context);
    final n = PaymentRules.momoNumber(number.text);
    if (n == null) {
      setState(() => numberErr = 'Enter a valid 10-digit MoMo number');
      return;
    }
    setState(() => numberErr = null);
    final r = await app.requestMomo(widget.s, n, demo: demo);
    if (!mounted) return;
    if (r == PaymentResult.confirmed) widget.onPaid();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final s = widget.s;
    return app.awaitingMomo(s) ? _waiting(app, s) : _compose(s);
  }

  Widget _compose(ChargeSession s) {
    final failed =
        s.payMethod == PayMethod.momo &&
        s.paymentStatus == PaymentStatus.failed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: 'Driver’s MoMo number',
          hint: '024 000 0000',
          icon: Icons.phone_android_rounded,
          controller: number,
          errorText: numberErr,
          keyboardType: TextInputType.phone,
          helper: 'A payment prompt is sent to this number. The driver approves it with their MoMo PIN.',
        ),
        if (failed) ...[
          const SizedBox(height: 12),
          InfoBanner(
            s.events.last.label.split(' — ').last,
            tone: Tone.danger,
            icon: Icons.error_outline_rounded,
          ),
        ],
        const SizedBox(height: 16),
        const Text(
          'Demo: driver response',
          style: TextStyle(fontSize: 12, color: UC.muted),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final (o, label) in const [
              (MomoOutcome.approve, 'Approves'),
              (MomoOutcome.decline, 'Declines'),
              (MomoOutcome.noResponse, 'No response'),
            ])
              ChoiceChip(
                label: Text(label),
                selected: demo == o,
                onSelected: (_) => setState(() => demo = o),
              ),
          ],
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          failed ? 'Send prompt again' : 'Send MoMo prompt',
          leading: Icons.send_to_mobile_rounded,
          trailing: null,
          onPressed: _send,
        ),
      ],
    );
  }

  Widget _waiting(AppState app, ChargeSession s) {
    final deadline = app.momoDeadline(s) ?? DateTime.now();
    final left = deadline.difference(DateTime.now());
    final secs = left.isNegative ? 0 : left.inSeconds;
    final progress = (secs / PaymentFlow.momoTimeout.inSeconds).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        color: UC.teal,
                        backgroundColor: UC.limeSoft,
                      ),
                    ),
                    Text(
                      '0:${secs.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Waiting for the driver',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Ask ${s.driver.name.split(' ').first} to approve ${money(s.due)} on ${s.momoNumber} with their MoMo PIN.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.4,
                  color: UC.muted,
                ),
              ),
              const SizedBox(height: 18),
              const _Step('Prompt sent', done: true),
              const _Step('Driver approves on phone', active: true),
              const _Step('Payment confirmed'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GhostButton(
          'Cancel prompt',
          icon: Icons.close_rounded,
          color: UC.danger,
          onPressed: () => app.cancelMomo(s),
        ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  final String label;
  final bool done;
  final bool active;
  const _Step(this.label, {this.done = false, this.active = false});

  @override
  Widget build(BuildContext context) {
    final color = done || active ? UC.success : UC.faint;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle_rounded
                : active
                ? Icons.timelapse_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              color: done || active ? UC.ink : UC.muted,
            ),
          ),
        ],
      ),
    );
  }
}
