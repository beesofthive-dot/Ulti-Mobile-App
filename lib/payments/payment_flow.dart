import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models.dart';
import '../notifications/app_notification.dart';
import 'payment_rules.dart';

/// How a payment attempt ended.
enum PaymentResult { confirmed, declined, timedOut, cancelled, failed }

/// What the (simulated) driver does with a MoMo prompt. Demo only.
enum MomoOutcome {
  /// The driver answers in their own app (no automatic answer).
  driver,
  approve,
  decline,
  noResponse,
}

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
  // Long enough for the driver to be handed the phone, or for the two
  // people to switch accounts on one device.
  static const momoTimeout = Duration(seconds: 120);

  final Map<String, Completer<PaymentResult>> _prompts = {};
  final Map<String, List<Timer>> _timers = {};
  final Map<String, DateTime> _deadlines = {};
  final Map<String, ChargeSession> _momoSessions = {};

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

  // ---------- driver QR ----------

  final Map<String, _QrToken> _qr = {};

  /// Called by the driver's QR screen each time it shows a code, so the
  /// attendant's scan can be checked against it. A driver has one live code.
  void registerQr(Driver d, String token, Duration ttl) {
    _qr.removeWhere((_, t) => t.driverId == d.id && !t.used);
    _qr[token] = _QrToken(d.id, DateTime.now().add(ttl));
  }

  /// What the driver's QR currently encodes (what a camera would read), or
  /// null when they have no live code on screen.
  String? liveQrPayload(Driver d) {
    final now = DateTime.now();
    for (final e in _qr.entries) {
      if (e.value.driverId == d.id &&
          !e.value.used &&
          e.value.expires.isAfter(now)) {
        return 'ulticharge:pay:${d.id}:${e.key}';
      }
    }
    return null;
  }

  /// Demo only: puts a fresh QR on the driver's "phone" (as if they had Pay
  /// open) and returns what a camera would read from it.
  String showDriverQr(Driver d) {
    final rng = Random.secure();
    final token = List.generate(
      12,
      (_) => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'[rng.nextInt(31)],
    ).join();
    registerQr(d, token, const Duration(seconds: 60));
    return 'ulticharge:pay:${d.id}:$token';
  }

  bool qrUsed(String token) => _qr[token]?.used ?? false;

  /// True once the driver has approved and paid with this code.
  bool qrPaid(String token) => _qr[token]?.paid ?? false;

  // ---- QR payment request ----
  // The attendant scans the driver's QR; that sends a payment request to the
  // driver's app. Nothing is taken until the driver approves it there.

  static const qrTimeout = Duration(seconds: 120);
  final Map<String, Completer<PaymentResult>> _qrPrompts = {};
  final Map<String, ChargeSession> _qrSessions = {};
  final Map<String, Timer> _qrTimers = {};
  final Map<String, String> _qrReasons = {};
  final Map<String, String> _qrTokenOf = {};

  bool awaitingQr(ChargeSession s) => _qrPrompts.containsKey(s.id);

  /// The scanned-QR payment waiting for [d] to approve, if any.
  ChargeSession? qrRequestFor(Driver d) {
    for (final s in _qrSessions.values) {
      if (s.driver.id == d.id && _qrPrompts.containsKey(s.id)) return s;
    }
    return null;
  }

  /// Verifies the scanned QR and sends the driver a payment request. Completes
  /// when the driver approves or declines, it expires, or it is cancelled.
  Future<PaymentResult> requestQrPayment(
    ChargeSession s,
    String scanned,
  ) async {
    _clearQr(s);
    _begin(s, PayMethod.wallet, 'QR');
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    var raw = scanned.trim();
    String? claimedDriver;
    if (raw.toLowerCase().startsWith('ulticharge:pay:')) {
      final parts = raw.split(':');
      if (parts.length == 4) {
        claimedDriver = parts[2];
        raw = parts[3];
      }
    }
    final token = raw.replaceAll(RegExp(r'\s'), '').toUpperCase();
    final t = _qr[token];
    final problem = !online
        ? 'No connection — the QR cannot be verified. Reconnect and scan again.'
        : token.isEmpty
        ? 'No QR was read. Ask ${s.driver.name} to open Pay and hold it up.'
        : t == null
        ? 'This QR is not recognised. Ask the driver to refresh their code.'
        : t.used
        ? 'This QR was already used. Ask the driver for a new code.'
        : t.expires.isBefore(DateTime.now())
        ? 'This QR has expired. Ask the driver for a new code.'
        : (t.driverId != s.driver.id ||
              (claimedDriver != null && claimedDriver != s.driver.id))
        ? 'This QR belongs to a different driver than ${s.driver.name}.'
        : s.driver.walletBalance < s.due
        ? 'Wallet balance ${money(s.driver.walletBalance)} is lower than ${money(s.due)}.'
        : null;
    if (problem != null) {
      _fail(s, PayMethod.wallet, problem);
      return PaymentResult.failed;
    }
    t!.used = true; // one scan, one request
    _qrTokenOf[s.id] = token;
    final done = Completer<PaymentResult>();
    _qrPrompts[s.id] = done;
    _qrSessions[s.id] = s;
    _qrTimers[s.id] = Timer(
      qrTimeout,
      () => _resolveQr(s, PaymentResult.timedOut),
    );
    s.events.add(
      SessionEvent('QR scanned — waiting for the driver to approve'),
    );
    final amount = money(s.due);
    moneyNote(
      s,
      tone: Tone.info,
      attendantTitle: 'QR scanned',
      driverTitle: 'Approve $amount',
      detail:
          'A payment request for $amount (${s.id}) was sent to '
          '${s.driver.name}. It is paid from their wallet once approved in Pay.',
    );
    notifyListeners();
    return done.future.then((r) {
      _finishQr(s, r);
      return r;
    });
  }

  void _resolveQr(ChargeSession s, PaymentResult r) {
    final c = _qrPrompts[s.id];
    if (c == null || c.isCompleted) return;
    c.complete(r);
  }

  /// The driver approves: the amount is taken from their wallet.
  void approveQrPayment(ChargeSession s) {
    if (!awaitingQr(s)) return;
    if (s.driver.walletBalance < s.due) {
      _qrReasons[s.id] =
          'Wallet balance ${money(s.driver.walletBalance)} is lower than ${money(s.due)}. Add money and try again.';
      _resolveQr(s, PaymentResult.failed);
      return;
    }
    _resolveQr(s, PaymentResult.confirmed);
  }

  void declineQrPayment(ChargeSession s) =>
      _resolveQr(s, PaymentResult.declined);

  /// The attendant withdraws the request.
  void cancelQrPayment(ChargeSession s) =>
      _resolveQr(s, PaymentResult.cancelled);

  void _finishQr(ChargeSession s, PaymentResult r) {
    final reason = _qrReasons.remove(s.id);
    _clearQr(s);
    switch (r) {
      case PaymentResult.confirmed:
        s.driver.walletBalance -= s.due;
        s.driver.ledger.insert(
          0,
          WalletEntry(WalletEntryKind.charge, s.due, 'Charge ${s.id} (QR)'),
        );
        final t = _qr[_qrTokenOf[s.id]];
        if (t != null) t.paid = true;
        _paid(s, PayMethod.wallet);
      case PaymentResult.declined:
        _fail(s, PayMethod.wallet, 'The driver declined the payment.');
      case PaymentResult.timedOut:
        _fail(
          s,
          PayMethod.wallet,
          'The payment request expired before the driver approved it.',
        );
      case PaymentResult.failed:
        _fail(s, PayMethod.wallet, reason ?? 'The payment could not be made.');
      case PaymentResult.cancelled:
        s
          ..paymentStatus = null
          ..events.add(
            SessionEvent('QR payment request cancelled by attendant'),
          );
        notifyListeners();
    }
  }

  void _clearQr(ChargeSession s) {
    _qrTimers.remove(s.id)?.cancel();
    _qrPrompts.remove(s.id);
    _qrSessions.remove(s.id);
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
    _momoSessions[s.id] = s;
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
          'A Mobile Money request for $amount (${s.id}) was sent to $number. '
          'The driver approves it with their MoMo PIN.',
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

  /// The MoMo prompt waiting for [d] to answer in their app, if any.
  ChargeSession? momoRequestFor(Driver d) {
    for (final s in _momoSessions.values) {
      if (s.driver.id == d.id && _prompts.containsKey(s.id)) return s;
    }
    return null;
  }

  /// The driver approves the prompt (after entering their MoMo PIN).
  void approveMomo(ChargeSession s) => resolveMomo(s, PaymentResult.confirmed);

  void declineMomo(ChargeSession s) => resolveMomo(s, PaymentResult.declined);

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
    _momoSessions.remove(s.id);
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

class _QrToken {
  final String driverId;
  final DateTime expires;
  bool used = false;
  bool paid = false;
  _QrToken(this.driverId, this.expires);
}
