// The sales attendant and the driver working together on one charge.
//
// There is one app state, and the two people take turns signing in, exactly
// as they would on a shared demo device. Every step that crosses from one
// role to the other goes through the real screens.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulti_charge/main.dart';
import 'package:ulti_charge/models.dart';
import 'package:ulti_charge/payments/payment_flow.dart';
import 'package:ulti_charge/state.dart';

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> settle(WidgetTester tester, [int ms = 700]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
  await tester.pump(Duration(milliseconds: ms));
}

/// Types the credentials on the real sign-in screen and signs in.
Future<void> signInUi(WidgetTester tester, String id, String password) async {
  await tester.enterText(find.byType(TextField).at(0), id);
  await tester.enterText(find.byType(TextField).at(1), password);
  await tester.tap(find.text('Sign in'));
  await tester.pump(const Duration(seconds: 1));
  await settle(tester, 900);
}

/// Real elapsed time (the payment flows have short simulated delays).
Future<void> realWait(WidgetTester tester, int ms) =>
    tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));

/// The attendant has clocked in and recorded a charge for the first driver.
ChargeSession recordedCharge(AppState app, {double kwh = 2.5}) {
  app.signIn(app.authenticate('020 000 0001', 'attend123')!);
  app.clockIn();
  final tariff = app.branch!.tariff;
  return app.recordCharge(
    driver: app.drivers.first,
    charger: app.branch!.chargers.first,
    kwh: kwh,
    amount: double.parse((kwh * tariff).toStringAsFixed(2)),
  );
}

/// Attendant opens the unpaid charge from their Shift tab.
Future<void> openChargeAsAttendant(WidgetTester tester, ChargeSession s) async {
  await tester.tap(find.text('Shift').last);
  await settle(tester);
  await tester.tap(find.text(s.id).first);
  await settle(tester);
  expect(find.text('Collect payment'), findsOneWidget);
}

/// Everything the given role has been told about [s].
List<String> titlesFor(AppState app) =>
    app.myNotifications.map((n) => n.title).toList();

Future<AppState> startApp(WidgetTester tester, AppState app) async {
  phone(tester);
  await tester.pumpWidget(UltiChargeApp(state: app));
  await tester.pump(const Duration(milliseconds: 2500));
  await tester.pump(const Duration(milliseconds: 900));
  return app;
}

void main() {
  testWidgets('QR: attendant scans, driver approves, both are told', (
    tester,
  ) async {
    final app = AppState();
    final s = recordedCharge(app);
    final before = s.driver.walletBalance;
    await startApp(tester, app);

    // --- Attendant: open the charge and scan the driver's QR ---
    await openChargeAsAttendant(tester, s);
    expect(find.text('Scan driver QR'), findsOneWidget);
    await tester.tap(find.text('Scan driver QR'));
    await tester.pump();
    await realWait(tester, 1300);
    await settle(tester);
    expect(find.textContaining('Waiting for Kwame to approve'), findsOneWidget);
    expect(app.awaitingQr(s), isTrue);
    // Nothing is taken yet.
    expect(s.driver.walletBalance, before);

    // --- Hand over: attendant signs out, the driver signs in ---
    app.signOut();
    await settle(tester);
    await signInUi(tester, 'kwame.mensah@example.com', 'driver123');
    // The request is waiting on the driver's screen.
    expect(find.text('PAYMENT REQUEST'), findsOneWidget);
    expect(find.text('Balance after'), findsOneWidget);
    // And in the driver's feed.
    expect(
      titlesFor(app).any((t) => t.startsWith('Approve')),
      isTrue,
      reason: 'driver is notified of the request',
    );

    await tester.tap(find.textContaining('Pay GH'));
    await tester.pump();
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
    await settle(tester);
    expect(find.text('Payment successful'), findsWidgets);
    expect(s.driver.walletBalance, closeTo(before - s.due, 0.001));
    expect(s.status, SessionStatus.paid);
    // The sheet closes by itself, leaving the driver on Home.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('PAYMENT REQUEST'), findsNothing);
    final driverFeed = titlesFor(app);
    expect(driverFeed, contains('Payment successful'));
    expect(driverFeed.any((t) => t.startsWith('Charge complete')), isTrue);

    // --- Hand back: the attendant sees it paid ---
    app.signOut();
    await settle(tester);
    await signInUi(tester, '020 000 0001', 'attend123');
    expect(titlesFor(app), contains('Payment received'));
    expect(app.collected, closeTo(s.due, 0.001));
    expect(app.pendingPayments, 0);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('MoMo: attendant sends a prompt, driver approves with a PIN', (
    tester,
  ) async {
    final app = AppState();
    final s = recordedCharge(app);
    final before = s.driver.walletBalance;
    await startApp(tester, app);

    // --- Attendant: choose MoMo and send the prompt ---
    await openChargeAsAttendant(tester, s);
    await tester.tap(find.text('MoMo').first);
    await settle(tester);
    expect(find.text('Send MoMo prompt'), findsOneWidget);
    await tester.tap(find.text('Send MoMo prompt'));
    await tester.pump();
    await settle(tester);
    expect(app.awaitingMomo(s), isTrue);
    expect(find.text('Waiting for the driver'), findsOneWidget);

    // --- Driver gets it in their own app ---
    app.signOut();
    await settle(tester);
    await signInUi(tester, '024 555 0187', 'driver123');
    expect(find.text('MOBILE MONEY REQUEST'), findsOneWidget);
    // Needs the PIN: cannot approve without it.
    final approveBtn = find.textContaining('Approve GH');
    expect(approveBtn, findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '4821');
    await settle(tester, 300);
    await tester.tap(approveBtn);
    await tester.pump();
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
    await settle(tester);
    expect(find.text('Payment successful'), findsWidgets);
    expect(s.status, SessionStatus.paid);
    expect(s.payMethod, PayMethod.momo);
    // MoMo is paid from the driver's phone, not the app wallet.
    expect(s.driver.walletBalance, before);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));

    // --- Attendant sees it settled ---
    app.signOut();
    await settle(tester);
    await signInUi(tester, '020 000 0001', 'attend123');
    expect(titlesFor(app), contains('Payment received'));
    expect(app.collected, closeTo(s.due, 0.001));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a declined request leaves the charge open for another try', (
    tester,
  ) async {
    final app = AppState();
    final s = recordedCharge(app);
    final before = s.driver.walletBalance;
    await startApp(tester, app);

    await openChargeAsAttendant(tester, s);
    await tester.tap(find.text('Scan driver QR'));
    await tester.pump();
    await realWait(tester, 1300);
    await settle(tester);
    app.signOut();
    await settle(tester);
    await signInUi(tester, '024 555 0187', 'driver123');

    await tester.tap(find.text('Decline'));
    await tester.pump();
    await tester.runAsync(() async => Future<void>.delayed(Duration.zero));
    await settle(tester);
    expect(find.text('Payment not made'), findsOneWidget);
    expect(s.driver.walletBalance, before);
    expect(s.paymentStatus, PaymentStatus.failed);
    expect(s.status, SessionStatus.awaitingPayment);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));

    // The attendant is told, and can still collect another way.
    expect(titlesFor(app), contains('Payment failed'));
    app.signOut();
    await settle(tester);
    await signInUi(tester, '020 000 0001', 'attend123');
    expect(titlesFor(app), contains('Payment failed'));
    expect(app.pendingPayments, 1);
    await tester.pump(const Duration(seconds: 1));
  });

  group('the same charge seen from both sides', () {
    test('driver history, wallet ledger and attendant totals agree', () async {
      final app = AppState();
      final s = recordedCharge(app);
      app.registerQr(s.driver, 'ABCD2345EFGH', const Duration(seconds: 60));
      final before = s.driver.walletBalance;
      final paying = app.requestQrPayment(s, app.liveQrPayload(s.driver)!);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      app.signOut();
      app.signIn(app.authenticate('0245550187', 'driver123')!);
      expect(app.qrRequestFor(app.me), same(s));
      app.approveQrPayment(s);
      await paying;

      // Driver's side.
      expect(app.myHistory, contains(s));
      final entry = s.driver.ledger.first;
      expect(entry.kind, WalletEntryKind.charge);
      expect(entry.amount, closeTo(s.due, 0.001));
      expect(s.driver.walletBalance, closeTo(before - s.due, 0.001));

      // Attendant's side.
      app.signOut();
      app.signIn(app.authenticate('020 000 0001', 'attend123')!);
      expect(app.todaySessions, contains(s));
      expect(app.collected, closeTo(s.due, 0.001));
      expect(s.paidAmount, closeTo(s.due, 0.001));
      expect(s.status, SessionStatus.paid);
    });

    test(
      'a new driver signs up, is found by the attendant, tops up, pays',
      () async {
        final app = AppState();
        // Driver registers their own account.
        final account = app.registerDriverAccount(
          'Ama Test',
          '0551234567',
          'GR 7777-24',
          'Sedan EV',
          'secret99',
          email: 'ama.test@example.com',
        );
        expect(app.authenticate('ama.test@example.com', 'secret99'), account);
        expect(app.authenticate('0551234567', 'secret99'), account);
        final driver = account.driver!;
        expect(driver.walletBalance, 0);

        // Attendant finds them and records a charge.
        app.signIn(app.authenticate('020 000 0001', 'attend123')!);
        app.clockIn();
        expect(app.findDuplicate('0551234567', ''), same(driver));
        final s = app.recordCharge(
          driver: driver,
          charger: app.branch!.chargers.first,
          kwh: 1,
          amount: app.branch!.tariff,
        );

        // With an empty wallet the QR payment cannot go through...
        app.registerQr(driver, 'ZZZZ2345EFGH', const Duration(seconds: 60));
        expect(
          await app.requestQrPayment(s, 'ZZZZ2345EFGH'),
          PaymentResult.failed,
        );
        expect(s.status, SessionStatus.awaitingPayment);

        // ...but MoMo, which does not use the wallet, still works.
        final momo = app.requestMomo(s, '0551234567', demo: MomoOutcome.driver);
        expect(app.momoRequestFor(driver), same(s));
        app.signOut();
        app.signIn(account);
        expect(app.momoRequestFor(app.me), same(s));
        app.approveMomo(s);
        expect(await momo, PaymentResult.confirmed);
        expect(s.status, SessionStatus.paid);
        expect(s.payMethod, PayMethod.momo);
      },
    );
  });
}
