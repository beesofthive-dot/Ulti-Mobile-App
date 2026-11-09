import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models.dart';
import '../../../payments/wallet_flow.dart';
import '../../../state.dart';
import '../../../theme.dart';
import '../../../widgets/common.dart';

enum MoneyAction { load, withdraw }

/// Bottom sheet to load money onto the card balance or withdraw it, both
/// through Mobile Money.
Future<void> showMoneySheet(BuildContext context, MoneyAction action) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: UC.surface,
    builder: (_) => _MoneySheet(action),
  );
}

enum _Phase { form, working, done }

class _MoneySheet extends StatefulWidget {
  final MoneyAction action;
  const _MoneySheet(this.action);

  @override
  State<_MoneySheet> createState() => _MoneySheetState();
}

class _MoneySheetState extends State<_MoneySheet> {
  final amount = TextEditingController(text: '50');
  late final number = TextEditingController(
    text: AppScope.read(context).me.phone,
  );
  _Phase phase = _Phase.form;
  String? error;
  double sent = 0;
  late String sentTo = number.text;

  bool get isLoad => widget.action == MoneyAction.load;
  double get value => double.tryParse(amount.text.trim()) ?? 0;

  @override
  void dispose() {
    amount.dispose();
    number.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final app = AppScope.read(context);
    final v = value;
    setState(() {
      error = null;
      phase = _Phase.working;
      sent = v;
      sentTo = number.text.trim();
    });
    final err = isLoad
        ? await app.loadMoney(v, number.text)
        : await app.withdraw(v, number.text);
    if (!mounted) return;
    setState(() {
      error = err;
      phase = err == null ? _Phase.done : _Phase.form;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: phase != _Phase.working,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          alignment: Alignment.topCenter,
          child: switch (phase) {
            _Phase.form => _form(context),
            _Phase.working => _working(),
            _Phase.done => _done(context),
          },
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final app = AppScope.of(context);
    final balance = app.me.walletBalance;
    final after = isLoad ? balance + value : balance - value;
    final chips = isLoad
        ? const [20.0, 50.0, 100.0, 200.0]
        : const [10.0, 20.0, 50.0];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconTile(
              isLoad ? Icons.add_card_rounded : Icons.north_east_rounded,
              isLoad ? UC.success : UC.info,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoad ? 'Load money' : 'Withdraw',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    isLoad
                        ? 'From Mobile Money to your card'
                        : 'From your card to Mobile Money',
                    style: TextStyle(fontSize: 12.5, color: UC.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LabeledField(
          label: 'Amount',
          prefixText: 'GH₵ ',
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() => error = null),
          helper: isLoad
              ? 'Between ${money(WalletFlow.minLoad)} and ${money(WalletFlow.maxLoad)}'
              : 'Available ${money(balance)} · minimum ${money(WalletFlow.minWithdraw)}',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in chips)
              ChoiceChip(
                label: Text(money(v)),
                selected: value == v,
                showCheckmark: false,
                onSelected: (_) => setState(() {
                  amount.text = v.toStringAsFixed(0);
                  error = null;
                }),
              ),
            if (!isLoad && balance >= WalletFlow.minWithdraw)
              ActionChip(
                label: const Text('All'),
                onPressed: () => setState(() {
                  amount.text = balance.toStringAsFixed(2);
                  error = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 16),
        LabeledField(
          label: isLoad ? 'Pay from MoMo number' : 'Send to MoMo number',
          icon: Icons.phone_android_rounded,
          controller: number,
          keyboardType: TextInputType.phone,
          onChanged: (_) => setState(() => error = null),
        ),
        const SizedBox(height: 14),
        Panel(
          color: UC.bg,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(
            children: [
              KV('Current balance', money(balance)),
              KV(
                'Balance after',
                money(after < 0 ? 0 : after),
                color: after < 0 ? UC.danger : UC.success,
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          InfoBanner(
            error!,
            tone: Tone.danger,
            icon: Icons.error_outline_rounded,
          ),
        ],
        const SizedBox(height: 16),
        PrimaryButton(
          isLoad ? 'Send MoMo prompt' : 'Withdraw ${money(value)}',
          leading: isLoad
              ? Icons.send_to_mobile_rounded
              : Icons.north_east_rounded,
          trailing: null,
          onPressed: value <= 0 ? null : _submit,
        ),
      ],
    );
  }

  Widget _working() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(strokeWidth: 5, color: UC.teal),
          ),
          const SizedBox(height: 22),
          Text(
            isLoad ? 'Approve on your phone' : 'Sending your money',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            isLoad
                ? 'We sent a prompt for ${money(sent)} to $sentTo. Enter your MoMo PIN to approve.'
                : '${money(sent)} is on its way to $sentTo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.45, color: UC.muted),
          ),
        ],
      ),
    );
  }

  Widget _done(BuildContext context) {
    final balance = AppScope.of(context).me.walletBalance;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: .4, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.elasticOut,
              builder: (_, t, child) => Transform.scale(scale: t, child: child),
              child: Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: UC.success.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: UC.success,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isLoad ? '${money(sent)} added' : '${money(sent)} sent',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            isLoad
                ? 'Your card balance is now ${money(balance)}.'
                : 'Sent to $sentTo. Your card balance is now ${money(balance)}.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: UC.muted),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            'Done',
            trailing: null,
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
