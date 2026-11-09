import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'payment_screen.dart';

/// AT-07 Stop charge — enter machine readings and check variance.
class StopChargeScreen extends StatefulWidget {
  final ChargeSession s;
  const StopChargeScreen(this.s, {super.key});

  @override
  State<StopChargeScreen> createState() => _StopChargeScreenState();
}

class _StopChargeScreenState extends State<StopChargeScreen> {
  final kwh = TextEditingController();
  final amount = TextEditingController();
  final notes = TextEditingController();
  final reason = TextEditingController();
  bool photo = false;
  bool displayUnavailable = false;
  String? kwhErr, amtErr, reasonErr;

  @override
  void initState() {
    super.initState();
    if (widget.s.kwh != null) kwh.text = widget.s.kwh!.toString();
    if (widget.s.machineAmount != null) {
      amount.text = widget.s.machineAmount!.toStringAsFixed(2);
    }
    notes.text = widget.s.notes;
  }

  double? get _kwh => double.tryParse(kwh.text.trim());
  double? get _amt => double.tryParse(amount.text.trim());
  double? get _expected => _kwh == null ? null : _kwh! * widget.s.tariff;
  double? get _variance =>
      (_expected == null || _amt == null) ? null : _amt! - _expected!;
  bool get _hasVariance => (_variance ?? 0).abs() >= 0.01;

  Future<void> _submit() async {
    final app = AppScope.read(context);
    final s = widget.s;
    if (displayUnavailable) {
      final ok = await confirmDialog(
        context,
        title: 'Mark as awaiting evidence?',
        body: const Text(
          'The session cannot be finalised or paid until machine readings are entered.',
        ),
        confirm: 'Save',
      );
      if (!ok || !mounted) return;
      app.markAwaitingEvidence(s, notes.text.trim());
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      kwhErr = (_kwh == null || _kwh! <= 0)
          ? 'Enter kWh from the machine'
          : null;
      amtErr = (_amt == null || _amt! <= 0)
          ? 'Enter GH₵ from the machine'
          : null;
      reasonErr = _hasVariance && reason.text.trim().length < 5
          ? 'Explain the variance (required)'
          : null;
    });
    if (kwhErr != null || amtErr != null || reasonErr != null) return;

    final ok = await confirmDialog(
      context,
      title: 'Confirm readings',
      confirm: 'Save readings',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          KV('Machine kWh', '${_kwh!.toStringAsFixed(2)} kWh'),
          KV('Machine amount', money(_amt!)),
          KV('Expected', money(_expected!)),
          KV(
            'Variance',
            '${_variance! >= 0 ? '+' : ''}${_variance!.toStringAsFixed(2)}',
            color: _hasVariance ? UC.danger : UC.success,
          ),
          if (_hasVariance) ...[
            const SizedBox(height: 8),
            const InfoBanner(
              'This session will be flagged for supervisor review before final closure.',
              tone: Tone.danger,
              icon: Icons.flag_outlined,
            ),
          ],
        ],
      ),
    );
    if (!ok || !mounted) return;
    app.recordReadings(
      s,
      kwh: _kwh!,
      amount: _amt!,
      photo: photo,
      notes: notes.text.trim(),
      varianceReason: reason.text.trim(),
    );
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => PaymentScreen(s)));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final v = _variance;
    return Scaffold(
      appBar: AppBar(title: const Text('Stop charge')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Panel(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.id,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${s.driver.name} · ${s.charger.id}',
                        style: TextStyle(fontSize: 12, color: UC.muted),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Elapsed',
                      style: TextStyle(fontSize: 11, color: UC.muted),
                    ),
                    Text(
                      clock(s.elapsed),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            value: displayUnavailable,
            onChanged: (x) => setState(() => displayUnavailable = x ?? false),
            title: const Text(
              'Machine display unavailable',
              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Session becomes “Awaiting evidence” and cannot be finalised.',
              style: TextStyle(fontSize: 11.5),
            ),
          ),
          if (!displayUnavailable) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: LabeledField(
                    label: 'Machine kWh',
                    hint: '0.00',
                    suffixText: 'kWh',
                    controller: kwh,
                    errorText: kwhErr,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LabeledField(
                    label: 'Machine GH₵',
                    hint: '0.00',
                    prefixText: 'GH₵ ',
                    controller: amount,
                    errorText: amtErr,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Panel(
              child: Column(
                children: [
                  KV('Tariff', '${money(s.tariff)} / kWh'),
                  KV(
                    'Expected (kWh × tariff)',
                    _expected == null ? '—' : money(_expected!),
                    strong: true,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Variance',
                        style: TextStyle(fontSize: 13, color: UC.muted),
                      ),
                      const Spacer(),
                      if (v == null)
                        StatusChip('Enter readings', UC.faint, dot: false)
                      else if (!_hasVariance)
                        const StatusChip('Matches', UC.success)
                      else
                        StatusChip(
                          '${v >= 0 ? '+' : ''}${v.toStringAsFixed(2)} GH₵',
                          UC.danger,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (_hasVariance) ...[
              const SizedBox(height: 14),
              LabeledField(
                label: 'Variance explanation',
                hint: 'Why does the machine amount differ?',
                controller: reason,
                errorText: reasonErr,
                maxLines: 2,
                helper: 'Required. A supervisor reviews this before closure.',
              ),
            ],
          ],
          const SizedBox(height: 14),
          Panel(
            padding: const EdgeInsets.all(12),
            onTap: () => setState(() => photo = !photo),
            child: Row(
              children: [
                IconTile(
                  photo ? Icons.check_rounded : Icons.photo_camera_outlined,
                  photo ? UC.success : UC.muted,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        photo ? 'Photo attached' : 'Attach photo of display',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Optional evidence',
                        style: TextStyle(fontSize: 11.5, color: UC.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  photo ? 'Remove' : 'Add',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          LabeledField(
            label: 'Notes',
            optional: true,
            hint: 'Anything the supervisor should know',
            controller: notes,
            maxLines: 2,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          decoration: BoxDecoration(
            color: UC.bg,
            border: Border(top: BorderSide(color: UC.line)),
          ),
          child: PrimaryButton(
            displayUnavailable ? 'SAVE AS AWAITING EVIDENCE' : 'STOP & REVIEW',
            height: 56,
            onPressed: _submit,
          ),
        ),
      ),
    );
  }
}
