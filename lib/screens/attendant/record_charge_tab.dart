import 'package:flutter/material.dart';

import '../../models.dart';
import '../../payments/charge_math.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'session_router.dart';

enum _Mode { kwh, amount }

/// Record a finished charge in one step: pick the port, type either the kWh
/// from the charger or the amount the driver is paying, check it, save it,
/// then take payment.
class RecordChargeTab extends StatefulWidget {
  final Driver? preselected;
  final VoidCallback onPickDriver;
  const RecordChargeTab({
    super.key,
    this.preselected,
    required this.onPickDriver,
  });

  @override
  State<RecordChargeTab> createState() => _RecordChargeTabState();
}

class _RecordChargeTabState extends State<RecordChargeTab> {
  Charger? port;
  Driver? driver;
  _Mode mode = _Mode.kwh;
  final kwhCtl = TextEditingController();
  final amountCtl = TextEditingController();
  bool reviewing = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    driver = widget.preselected;
  }

  @override
  void didUpdateWidget(RecordChargeTab old) {
    super.didUpdateWidget(old);
    // A driver picked on the Drivers tab arrives here without losing what was
    // already typed.
    if (widget.preselected != old.preselected && widget.preselected != null) {
      driver = widget.preselected;
    }
  }

  @override
  void dispose() {
    kwhCtl.dispose();
    amountCtl.dispose();
    super.dispose();
  }

  // ---- the numbers, worked out the same way they will be saved ----
  ({
    int? wh,
    int? amount,
    int? typedAmount,
    bool typed,
    bool tooBig,
    bool invalid,
  })
  _calc(int rate) {
    final text = (mode == _Mode.kwh ? kwhCtl : amountCtl).text;
    final typed = text.trim().isNotEmpty;
    final typedAmount = mode == _Mode.amount
        ? ChargeMath.cedisToPesewas(text)
        : null;
    final wh = mode == _Mode.kwh
        ? ChargeMath.kwhToWh(text)
        : typedAmount == null
        ? null
        : ChargeMath.energyForAmount(typedAmount, rate);
    final amount = wh == null ? null : ChargeMath.amountFor(wh, rate);
    return (
      wh: wh,
      amount: amount,
      typedAmount: typedAmount,
      typed: typed,
      tooBig: wh != null && wh > ChargeMath.maxWh,
      invalid: typed && wh == null,
    );
  }

  String _kwh(int wh) => '${(wh / 1000).toStringAsFixed(3)} kWh';
  String _cedis(int pesewas) => money(pesewas / 100);

  void _switch(_Mode next, int rate) {
    if (next == mode) return;
    final c = _calc(rate);
    // Carry what was typed across, so nothing is typed twice.
    if (next == _Mode.amount && c.wh != null && c.amount != null) {
      amountCtl.text = (c.amount! / 100).toStringAsFixed(2);
    }
    if (next == _Mode.kwh && c.wh != null) {
      kwhCtl.text = (c.wh! / 1000).toString();
    }
    setState(() => mode = next);
  }

  void _save(AppState app, int wh, int amount) {
    if (saving) return;
    setState(() => saving = true);
    final s = app.recordCharge(
      driver: driver!,
      charger: port!,
      kwh: wh / 1000,
      amount: amount / 100,
    );
    setState(() {
      saving = false;
      reviewing = false;
      kwhCtl.clear();
      amountCtl.clear();
      driver = null;
    });
    toast(
      context,
      'Charge ${s.id} saved. Take payment now.',
      tone: Tone.success,
    );
    openSession(context, s);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final b = app.branch!;
    port ??= app.shift.charger ?? b.chargers.first;
    final rate = ChargeMath.ratePesewas(b.tariff);
    final c = _calc(rate);
    final ready =
        port != null &&
        driver != null &&
        c.wh != null &&
        c.amount != null &&
        !c.tooBig;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(.04, 0),
            end: Offset.zero,
          ).animate(a),
          child: child,
        ),
      ),
      child: reviewing && ready
          ? _review(app, b, c.wh!, c.amount!, c.typedAmount, rate)
          : _form(app, b, c, rate, ready),
    );
  }

  // ------------------------------------------------------------------ form

  Widget _form(
    AppState app,
    Branch b,
    ({
      int? wh,
      int? amount,
      int? typedAmount,
      bool typed,
      bool tooBig,
      bool invalid,
    })
    c,
    int rate,
    bool ready,
  ) {
    final rateText = '${_cedis(rate)} per kWh';
    final adjusted =
        mode == _Mode.amount &&
        c.typedAmount != null &&
        c.amount != null &&
        !c.tooBig &&
        c.typedAmount != c.amount;
    return Column(
      key: const ValueKey('form'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              FadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Eyebrow(b.name),
                    const SizedBox(height: 4),
                    Text(
                      'Record a charge',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                        color: UC.title,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Type the kWh from the charger, or the amount the '
                      'driver is paying.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: UC.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const _StepLabel('1. Which port?'),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, box) {
                  final cols = b.chargers.length <= 3 ? b.chargers.length : 2;
                  final w = (box.maxWidth - 10 * (cols - 1)) / cols;
                  return Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final ch in b.chargers)
                        SizedBox(
                          width: w,
                          child: _PortCard(
                            ch,
                            selected: port == ch,
                            inUse: app.activeOn(ch) != null,
                            onTap: () => setState(() => port = ch),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              const _StepLabel('2. What do you have?'),
              const SizedBox(height: 8),
              _Segmented(
                labels: const ['Enter kWh', 'Enter amount'],
                index: mode == _Mode.kwh ? 0 : 1,
                onChanged: (i) =>
                    _switch(i == 0 ? _Mode.kwh : _Mode.amount, rate),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: KeyedSubtree(
                  key: ValueKey(mode),
                  child: LabeledField(
                    label: mode == _Mode.kwh
                        ? 'How many kWh did the charger show?'
                        : 'How much is the driver paying? (GH₵)',
                    hint: mode == _Mode.kwh ? 'e.g. 42.5' : 'e.g. 50',
                    icon: mode == _Mode.kwh
                        ? Icons.bolt_rounded
                        : Icons.payments_outlined,
                    controller: mode == _Mode.kwh ? kwhCtl : amountCtl,
                    big: true,
                    helper: 'Rate: $rateText',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              _Notice(
                show: c.invalid,
                text: mode == _Mode.kwh
                    ? 'Type the kWh as a number, like 42.5.'
                    : 'Type the amount in cedis, like 50 or 50.50.',
                tone: Tone.danger,
              ),
              _Notice(
                show: c.tooBig,
                text:
                    'That is more than one charge can be. Check the '
                    '${mode == _Mode.kwh ? 'kWh' : 'amount'}.',
                tone: Tone.danger,
              ),
              _Notice(
                show: adjusted,
                text:
                    'The closest the charger’s kWh allows to '
                    '${_cedis(c.typedAmount ?? 0)} is ${_cedis(c.amount ?? 0)}, '
                    'so that is what will be saved.',
                tone: Tone.warning,
              ),
              const SizedBox(height: 20),
              const _StepLabel('3. Who is paying?'),
              const SizedBox(height: 8),
              _DriverPanel(driver: driver, onTap: widget.onPickDriver),
              if (!app.online) ...[
                const SizedBox(height: 14),
                const InfoBanner(
                  'Offline — this charge will be saved on the device as UNSYNCED.',
                  tone: Tone.warning,
                  icon: Icons.cloud_off_rounded,
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          decoration: BoxDecoration(
            color: UC.bg,
            border: Border(top: BorderSide(color: UC.line)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ResultCard(
                label: mode == _Mode.kwh
                    ? 'Amount to pay'
                    : 'Energy (worked out)',
                value: c.wh == null || c.amount == null || c.tooBig
                    ? '—'
                    : mode == _Mode.kwh
                    ? _cedis(c.amount!)
                    : _kwh(c.wh!),
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                'Review charge',
                trailing: Icons.arrow_forward_rounded,
                height: 56,
                onPressed: ready
                    ? () => setState(() => reviewing = true)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- review

  Widget _review(
    AppState app,
    Branch b,
    int wh,
    int amount,
    int? typedAmount,
    int rate,
  ) {
    final adjusted =
        mode == _Mode.amount && typedAmount != null && typedAmount != amount;
    return ListView(
      key: const ValueKey('review'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SmallLink(
            'Change',
            icon: Icons.arrow_back_rounded,
            bold: true,
            onTap: () => setState(() => reviewing = false),
          ),
        ),
        const SizedBox(height: 6),
        FadeSlideIn(
          child: Panel(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('Check before you save'),
                const SizedBox(height: 6),
                CountUp(
                  amount / 100,
                  format: money,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: UC.title,
                  ),
                ),
                const SizedBox(height: 14),
                KV('Branch', b.name),
                KV('Port', port!.label),
                KV('Energy', _kwh(wh)),
                KV('Rate', '${_cedis(rate)} / kWh'),
                KV('Driver', driver!.name),
                KV('Vehicle', '${driver!.plate} · ${driver!.vehicleType}'),
              ],
            ),
          ),
        ),
        _Notice(
          show: adjusted,
          text:
              'You entered ${_cedis(typedAmount ?? 0)}. The closest the '
              'charger’s kWh allows is ${_cedis(amount)}, so that is the '
              'amount that will be saved.',
          tone: Tone.warning,
        ),
        const SizedBox(height: 16),
        const InfoBanner(
          'The driver is told the amount due as soon as you save. You can '
          'then take payment by scanning their QR, their card, or MoMo.',
          tone: Tone.neutral,
          icon: Icons.notifications_active_outlined,
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          'Save charge',
          leading: Icons.check_rounded,
          trailing: null,
          busy: saving,
          onPressed: () => _save(app, wh, amount),
        ),
        const SizedBox(height: 10),
        GhostButton(
          'Back',
          onPressed: saving ? null : () => setState(() => reviewing = false),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- small pieces

class _StepLabel extends StatelessWidget {
  final String text;
  const _StepLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
  );
}

class _PortCard extends StatelessWidget {
  final Charger c;
  final bool selected;
  final bool inUse;
  final VoidCallback onTap;
  const _PortCard(
    this.c, {
    required this.selected,
    required this.inUse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? UC.limeSoft : UC.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? UC.accent : UC.line,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: UC.teal.withValues(alpha: .25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Port ${c.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    inUse ? '${c.connector} · charging now' : c.connector,
                    style: TextStyle(
                      fontSize: 12,
                      color: inUse ? UC.info : UC.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Two-option switch with a sliding highlight.
class _Segmented extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;
  const _Segmented({
    required this.labels,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: UC.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: UC.line),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: index == 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 1 / labels.length,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: UC.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: i == index ? UC.onAccent : UC.muted,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A message that slides open when [show] is true.
class _Notice extends StatelessWidget {
  final bool show;
  final String text;
  final Tone tone;
  const _Notice({required this.show, required this.text, required this.tone});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: show
          ? Padding(
              padding: const EdgeInsets.only(top: 12),
              child: InfoBanner(
                text,
                tone: tone,
                icon: tone == Tone.danger
                    ? Icons.error_outline_rounded
                    : Icons.info_outline_rounded,
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label;
  final String value;
  const _ResultCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: UC.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: UC.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: UC.muted,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: ScaleTransition(
                scale: Tween(begin: .92, end: 1.0).animate(a),
                child: c,
              ),
            ),
            child: Text(
              value,
              key: ValueKey(value),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -.5,
                color: value == '—' ? UC.faint : UC.title,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverPanel extends StatelessWidget {
  final Driver? driver;
  final VoidCallback onTap;
  const _DriverPanel({required this.driver, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Panel(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: driver == null
          ? Row(
              children: [
                IconTile(Icons.person_search_outlined, UC.muted, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Search by phone, card or ID',
                    style: TextStyle(color: UC.muted),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: UC.muted),
              ],
            )
          : Row(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: UC.limeSoft,
                  child: Text(
                    driver!.initials,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: UC.accent,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver!.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${driver!.phone} · ${driver!.plate}',
                        style: TextStyle(fontSize: 11.5, color: UC.muted),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: UC.accent,
                  ),
                ),
              ],
            ),
    );
  }
}
