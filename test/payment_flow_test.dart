import 'package:flutter_test/flutter_test.dart';
import 'package:ulti_charge/models.dart';
import 'package:ulti_charge/payments/payment_flow.dart';
import 'package:ulti_charge/payments/payment_rules.dart';
import 'package:ulti_charge/state.dart';

ChargeSession billedSession(AppState app, {double amount = 24}) {
  app.signIn(app.authenticate('020 000 0001', 'attend123')!);
  app.clockIn();
  final s = app.startSession(
    driver: app.drivers.first,
    charger: app.branch!.chargers.first,
  );
  app.recordReadings(
    s,
    kwh: amount / s.tariff,
    amount: amount,
    photo: false,
    notes: '',
    varianceReason: '',
  );
  return s;
}

void main() {
  test('sales accept only card and MoMo', () {
    expect(PaymentRules.methodsFor(PaymentParty.sales), [
      PayMethod.card,
      PayMethod.momo,
    ]);
  });

  test('MoMo numbers are normalised and validated', () {
    expect(PaymentRules.momoNumber('+233 24 555 0187'), '0245550187');
    expect(PaymentRules.momoNumber('024 555 0187'), '0245550187');
    expect(PaymentRules.momoNumber('12345'), isNull);
  });

  test('scanning the driver card pays from the linked balance', () async {
    final app = AppState();
    final s = billedSession(app);
    final before = s.driver.walletBalance;
    final r = await app.payWithCard(s, s.driver.cardId!);
    expect(r, PaymentResult.confirmed);
    expect(s.status, SessionStatus.paid);
    expect(s.driver.walletBalance, before - 24);
  });

  test(
    'a card from another driver is rejected and nothing is charged',
    () async {
      final app = AppState();
      final s = billedSession(app);
      final before = s.driver.walletBalance;
      final r = await app.payWithCard(s, app.drivers[1].cardId!);
      expect(r, PaymentResult.failed);
      expect(s.paymentStatus, PaymentStatus.failed);
      expect(s.driver.walletBalance, before);
      expect(app.banner?.title, 'Payment failed');
    },
  );

  test('card without enough balance fails', () async {
    final app = AppState();
    final s = billedSession(app, amount: 500);
    expect(await app.payWithCard(s, s.driver.cardId!), PaymentResult.failed);
  });

  test('MoMo prompt waits, then confirms when the driver approves', () async {
    final app = AppState();
    final s = billedSession(app);
    final pending = app.requestMomo(
      s,
      '0245550187',
      demo: MomoOutcome.noResponse,
    );
    expect(app.awaitingMomo(s), isTrue);
    expect(s.paymentStatus, PaymentStatus.pending);
    expect(app.momoDeadline(s), isNotNull);
    app.resolveMomo(s, PaymentResult.confirmed);
    expect(await pending, PaymentResult.confirmed);
    expect(app.awaitingMomo(s), isFalse);
    expect(s.status, SessionStatus.paid);
    expect(s.momoNumber, '0245550187');
  });

  test('declined and cancelled MoMo prompts leave the bill unpaid', () async {
    final app = AppState();
    final s = billedSession(app);
    var pending = app.requestMomo(
      s,
      '0245550187',
      demo: MomoOutcome.noResponse,
    );
    app.resolveMomo(s, PaymentResult.declined);
    expect(await pending, PaymentResult.declined);
    expect(s.paymentStatus, PaymentStatus.failed);
    expect(s.status, SessionStatus.awaitingPayment);

    pending = app.requestMomo(s, '0245550187', demo: MomoOutcome.noResponse);
    app.cancelMomo(s);
    expect(await pending, PaymentResult.cancelled);
    expect(s.paymentStatus, isNull);
    expect(s.paidAmount, 0);
  });

  test('offline MoMo fails immediately without sending a prompt', () async {
    final app = AppState();
    final s = billedSession(app);
    app.setOnline(false);
    expect(await app.requestMomo(s, '0245550187'), PaymentResult.failed);
    expect(app.awaitingMomo(s), isFalse);
  });
}
