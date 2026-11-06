import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models.dart';
import '../notifications/app_notification.dart';
import 'payment_rules.dart';

/// How a payment attempt ended.
enum PaymentResult { confirmed, declined, timedOut, cancelled, failed }

/// What the (simulated) driver does with a MoMo prompt. Demo only.
enum MomoOutcome { approve, decline, noResponse }

/// Card scans and MoMo prompts for a charge session.
///
/// Card: the driver's QR card is read on the machine and paid from the
/// linked wallet. MoMo: the attendant sends a prompt to the driver's phone;
/// the driver approves it with their MoMo PIN. Both only become "confirmed"
/// after the provider answers.
mixin PaymentFlow on ChangeNotifier {
  bool get online;

  /// Tells the attendant and the driver about a money event on [s].
  void moneyNote(
    ChargeSession s, {
    required Tone tone,
    required String attendantTitle,
    required String driverTitle,
    required String detail,
  });

  /// How long a MoMo prompt stays valid.
  static const momoTimeout = Duration(seconds: 45);

  final Map<String, Completer<PaymentResult>> _prompts = {};
  final Map<String, List<Timer>> _timers = {};
  final Map<String, DateTime> _deadlines = {};

  bool awaitingMomo(ChargeSession s) => _prompts.containsKey(s.id);

  /// When the open MoMo prompt on [s] expires, if there is one.
  DateTime? momoDeadline(ChargeSession s) => _deadlines[s.id];

  // ---------- card ----------

  /// Reads [scannedCard] on the machine and pays from the linked wallet.
  Future<PaymentResult> payWithCard(ChargeSession s, String scannedCard) async {
    _begin(s, PayMethod.card, scannedCard);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    final problem = !online
        ? 'No connection — the card cannot be verified. Reconnect and scan again.'
        : PaymentRules.cardProblem(s, scannedCard);
    if (problem != null) {
      _fail(s, PayMethod.card, problem);
      return PaymentResult.failed;
    }
    s.driver.walletBalance -= s.due;
    s.driver.ledger.insert(
      0,
      WalletEntry(WalletEntryKind.charge, s.due, 'Charge ${s.id}'),
    );
    _paid(s, PayMethod.card);
    return PaymentResult.confirmed;
  }

  // ---------- mobile money ----------

  /// Sends a prompt to [number] and waits until the driver answers, it
  /// expires, or the attendant cancels it.
  Future<PaymentResult> requestMomo(
    ChargeSession s,
    String number, {
    MomoOutcome demo = MomoOutcome.approve,
  }) {
    _clear(s);
    if (!online) {
      _begin(s, PayMethod.momo, number);
      _fail(
        s,
        PayMethod.momo,
        'No connection — the prompt could not be sent. Reconnect and try again.',
      );
      return Future.value(PaymentResult.failed);
    }
    s.momoNumber = number;
    _begin(s, PayMethod.momo, 'MOMO-${s.id.substring(s.id.length - 4)}');
    final done = Completer<PaymentResult>();
    _prompts[s.id] = done;
    _deadlines[s.id] = DateTime.now().add(momoTimeout);
    _timers[s.id] = [
      Timer(momoTimeout, () => resolveMomo(s, PaymentResult.timedOut)),
      if (demo == MomoOutcome.approve)
        Timer(
          const Duration(seconds: 5),
          () => resolveMomo(s, PaymentResult.confirmed),
        ),
      if (demo == MomoOutcome.decline)
        Timer(
          const Duration(seconds: 4),
          () => resolveMomo(s, PaymentResult.declined),
        ),
    ];
    final amount = money(s.due);
    moneyNote(
      s,
      tone: Tone.info,
      attendantTitle: 'MoMo prompt sent',
      driverTitle: 'Approve $amount',
      detail:
          'Ulti Charge requested $amount on $number. Enter your MoMo PIN to approve.',
    );
    notifyListeners();
    return done.future.then((r) {
      _finishMomo(s, r);
      return r;
    });
  }

  /// Provider answer for the open prompt on [s].
  void resolveMomo(ChargeSession s, PaymentResult result) {
    final c = _prompts[s.id];
    if (c == null || c.isCompleted) return;
    c.complete(result);
  }

  void cancelMomo(ChargeSession s) => resolveMomo(s, PaymentResult.cancelled);

  void _finishMomo(ChargeSession s, PaymentResult r) {
    _clear(s);
    switch (r) {
      case PaymentResult.confirmed:
        _paid(s, PayMethod.momo);
      case PaymentResult.declined:
        _fail(s, PayMethod.momo, 'The driver declined the MoMo prompt.');
      case PaymentResult.timedOut:
        _fail(
          s,
          PayMethod.momo,
          'The prompt expired before the driver approved it.',
        );
      case PaymentResult.cancelled:
        s
          ..paymentStatus = null
          ..events.add(SessionEvent('MoMo prompt cancelled by attendant'));
        notifyListeners();
      case PaymentResult.failed:
        break;
    }
  }

  void _clear(ChargeSession s) {
    for (final t in _timers.remove(s.id) ?? const <Timer>[]) {
      t.cancel();
    }
    _prompts.remove(s.id);
    _deadlines.remove(s.id);
  }

  // ---------- shared ----------

  void _begin(ChargeSession s, PayMethod m, String ref) {
    s
      ..payMethod = m
      ..paymentRef = ref
      ..paymentStatus = PaymentStatus.pending;
    s.events.add(
      SessionEvent(
        '${payMethodLabel(m)} payment initiated (key ${s.idempotencyKey.substring(0, 8)}…)',
      ),
    );
    notifyListeners();
  }

  void _paid(ChargeSession s, PayMethod m) {
    s
      ..paymentStatus = PaymentStatus.confirmed
      ..paidAmount = s.due
      ..status = s.varianceFlag ? SessionStatus.exception : SessionStatus.paid;
    s.events.add(SessionEvent('${payMethodLabel(m)} payment confirmed'));
    moneyNote(
      s,
      tone: Tone.success,
      attendantTitle: 'Payment received',
      driverTitle: 'Payment successful',
      detail:
          '${money(s.due)} via ${payMethodLabel(m)} for ${s.id}. Receipt is ready.',
    );
  }

  void _fail(ChargeSession s, PayMethod m, String reason) {
    s.paymentStatus = PaymentStatus.failed;
    s.events.add(SessionEvent('${payMethodLabel(m)} payment failed — $reason'));
    moneyNote(
      s,
      tone: Tone.danger,
      attendantTitle: 'Payment failed',
      driverTitle: 'Payment failed',
      detail: '$reason Nothing was charged — you can try again.',
    );
  }
}
