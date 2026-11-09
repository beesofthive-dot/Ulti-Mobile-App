import 'package:flutter_test/flutter_test.dart';
import 'package:ulti_charge/auth/otp_flow.dart';
import 'package:ulti_charge/models.dart';
import 'package:ulti_charge/payments/payment_flow.dart';
import 'package:ulti_charge/state.dart';

ChargeSession billed(AppState app, {double amount = 24}) {
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
  group('driver QR payment', () {
    // The scan is read after a short delay; wait for the request to open.
    Future<void> opened() =>
        Future<void>.delayed(const Duration(milliseconds: 1300));

    test(
      'scan sends a request; approving takes the money and tells both',
      () async {
        final app = AppState();
        final s = billed(app);
        app.registerQr(s.driver, 'ABCD2345EFGH', const Duration(seconds: 60));
        final before = s.driver.walletBalance;
        final payload = app.liveQrPayload(s.driver)!;
        expect(payload, 'ulticharge:pay:${s.driver.id}:ABCD2345EFGH');

        final result = app.requestQrPayment(s, payload);
        await opened();
        // Request is open on the driver's side; nothing has been taken yet.
        expect(app.awaitingQr(s), isTrue);
        expect(app.qrRequestFor(s.driver), same(s));
        expect(s.driver.walletBalance, before);
        expect(s.status, isNot(SessionStatus.paid));
        final titles = app.notifications.map((n) => n.title).toList();
        expect(titles, contains('QR scanned')); // attendant
        expect(titles.any((t) => t.startsWith('Approve')), isTrue); // driver

        app.approveQrPayment(s);
        expect(await result, PaymentResult.confirmed);
        expect(s.status, SessionStatus.paid);
        expect(s.driver.walletBalance, before - 24);
        expect(app.qrRequestFor(s.driver), isNull);
        expect(app.qrPaid('ABCD2345EFGH'), isTrue);
        final after = app.notifications.map((n) => n.title).toList();
        expect(after, contains('Payment received')); // attendant
        expect(after, contains('Payment successful')); // driver
      },
    );

    test('declining takes nothing and tells both', () async {
      final app = AppState();
      final s = billed(app);
      app.registerQr(s.driver, 'ABCD2345EFGH', const Duration(seconds: 60));
      final before = s.driver.walletBalance;
      final result = app.requestQrPayment(s, app.liveQrPayload(s.driver)!);
      await opened();
      app.declineQrPayment(s);
      expect(await result, PaymentResult.declined);
      expect(s.driver.walletBalance, before);
      expect(s.paymentStatus, PaymentStatus.failed);
      expect(
        app.notifications.where((n) => n.title == 'Payment failed').length,
        2,
      );
    });

    test('the attendant can cancel an open request', () async {
      final app = AppState();
      final s = billed(app);
      app.registerQr(s.driver, 'ABCD2345EFGH', const Duration(seconds: 60));
      final result = app.requestQrPayment(s, app.liveQrPayload(s.driver)!);
      await opened();
      app.cancelQrPayment(s);
      expect(await result, PaymentResult.cancelled);
      expect(app.awaitingQr(s), isFalse);
      expect(s.driver.walletBalance, greaterThan(0));
    });

    test('a scanned code cannot be used for a second request', () async {
      final app = AppState();
      final s = billed(app);
      app.registerQr(s.driver, 'ABCD2345EFGH', const Duration(seconds: 60));
      final first = app.requestQrPayment(s, 'ABCD2345EFGH');
      await opened();
      app.approveQrPayment(s);
      await first;
      final s2 = billed(app);
      expect(
        await app.requestQrPayment(s2, 'ABCD2345EFGH'),
        PaymentResult.failed,
      );
      expect(app.awaitingQr(s2), isFalse);
    });

    test(
      'no QR, expired QR or another driver fail without a request',
      () async {
        final app = AppState();
        final s = billed(app);
        final before = s.driver.walletBalance;
        expect(app.liveQrPayload(s.driver), isNull);
        expect(await app.requestQrPayment(s, ''), PaymentResult.failed);

        app.registerQr(s.driver, 'EXPIRED22222', const Duration(seconds: -1));
        expect(
          await app.requestQrPayment(s, 'EXPIRED22222'),
          PaymentResult.failed,
        );

        app.registerQr(
          app.drivers[1],
          'OTHERDRIVER2',
          const Duration(seconds: 60),
        );
        expect(
          await app.requestQrPayment(s, 'OTHERDRIVER2'),
          PaymentResult.failed,
        );
        expect(app.awaitingQr(s), isFalse);
        expect(s.driver.walletBalance, before);
      },
    );

    test(
      'not enough balance fails at the scan, or at approval if it dropped',
      () async {
        final app = AppState();
        final big = billed(app, amount: 5000);
        app.registerQr(big.driver, 'ABCD2345EFGH', const Duration(seconds: 60));
        expect(
          await app.requestQrPayment(big, 'ABCD2345EFGH'),
          PaymentResult.failed,
        );

        final app2 = AppState();
        final s = billed(app2);
        app2.registerQr(s.driver, 'ABCD2345EFGH', const Duration(seconds: 60));
        final result = app2.requestQrPayment(s, 'ABCD2345EFGH');
        await opened();
        s.driver.walletBalance = 1; // spent elsewhere before approving
        app2.approveQrPayment(s);
        expect(await result, PaymentResult.failed);
        expect(s.driver.walletBalance, 1);
      },
    );
  });

  group('one-time codes', () {
    test('a right code signs in once; the same code is then spent', () {
      final app = AppState();
      expect(app.sendOtp('024 555 0187'), isTrue);
      final code = app.demoSmsCode('0245550187')!;
      expect(code.length, OtpFlow.otpLength);

      final r = app.verifyOtp('024 555 0187', code);
      expect(r.error, isNull);
      expect(r.account?.role, Role.driver);
      expect(app.verifyOtp('0245550187', code).error, isNotNull);
    });

    test('wrong codes count down, then lock the code', () {
      final app = AppState();
      app.sendOtp('0245550187');
      final code = app.demoSmsCode('0245550187')!;
      final wrong = code == '000000' ? '111111' : '000000';
      for (var i = 0; i < OtpFlow.otpMaxAttempts; i++) {
        expect(app.verifyOtp('0245550187', wrong).account, isNull);
      }
      // Even the right code is refused after too many attempts.
      expect(app.verifyOtp('0245550187', code).account, isNull);
    });

    test('resend is throttled, and an unknown number gets no code', () {
      final app = AppState();
      expect(app.sendOtp('0245550187'), isTrue);
      expect(app.sendOtp('0245550187'), isFalse);
      expect(app.otpResendAt('0245550187')!.isAfter(DateTime.now()), isTrue);

      expect(app.sendOtp('0999999999'), isTrue);
      expect(app.demoSmsCode('0999999999'), isNull);
      expect(app.verifyOtp('0999999999', '123456').account, isNull);
    });

    test('reset password changes the credentials', () {
      final app = AppState();
      expect(app.authenticate('0245550187', 'driver123'), isNotNull);
      expect(app.resetPassword('024 555 0187', 'brandnew9'), isTrue);
      expect(app.authenticate('0245550187', 'driver123'), isNull);
      expect(app.authenticate('0245550187', 'brandnew9'), isNotNull);
      expect(app.resetPassword('0999999999', 'whatever1'), isFalse);
    });
  });

  group('email sign-in', () {
    test('password works with a phone number or an email (any case)', () {
      final app = AppState();
      expect(app.authenticate('024 555 0187', 'driver123'), isNotNull);
      expect(
        app.authenticate('Kwame.Mensah@Example.com', 'driver123')?.role,
        Role.driver,
      );
      expect(
        app.authenticate(' efua.asante@ulticharge.com ', 'attend123')?.role,
        Role.attendant,
      );
      expect(app.authenticate('kwame.mensah@example.com', 'wrong'), isNull);
      expect(app.authenticate('nobody@example.com', 'driver123'), isNull);
    });

    test('a one-time code can be asked for with an email', () {
      final app = AppState();
      expect(app.otpChannel('kwame.mensah@example.com'), 'email');
      expect(app.sendOtp('kwame.mensah@example.com'), isTrue);
      final code = app.demoSmsCode('kwame.mensah@example.com')!;
      // Same account, so the same pending code is visible by its phone too.
      expect(app.demoSmsCode('0245550187'), code);
      expect(
        app.verifyOtp('kwame.mensah@example.com', code).account?.role,
        Role.driver,
      );
    });

    test('an unknown email gets no code; ids are validated', () {
      final app = AppState();
      expect(app.sendOtp('ghost@example.com'), isTrue);
      expect(app.demoSmsCode('ghost@example.com'), isNull);
      expect(AppState.validId('a@b.co'), isTrue);
      expect(AppState.validId('not-an-email@'), isFalse);
      expect(AppState.validId('024 555 0187'), isTrue);
      expect(AppState.validId('12345'), isFalse);
    });

    test('reset password through the email address', () {
      final app = AppState();
      expect(
        app.resetPassword('kwame.mensah@example.com', 'freshpass1'),
        isTrue,
      );
      expect(app.authenticate('0245550187', 'freshpass1'), isNotNull);
    });
  });

  group('one notification feed', () {
    test('driver feed gets charge, bill, payment and account events', () async {
      final app = AppState();
      final s = billed(app);
      app.registerQr(s.driver, 'ABCD2345EFGH', const Duration(seconds: 60));
      final paying = app.requestQrPayment(s, 'ABCD2345EFGH');
      await Future<void>.delayed(const Duration(milliseconds: 1300));
      app.approveQrPayment(s);
      await paying;
      app.signOut();

      app.resetPassword('0245550187', 'newpass77');
      app.sendOtp('0245550187');
      final r = app.verifyOtp('0245550187', app.demoSmsCode('0245550187')!);
      app.signIn(r.account!, viaCode: true);

      final titles = app.myNotifications.map((n) => n.title).toList();
      expect(titles, contains('Charging started'));
      expect(titles.any((t) => t.startsWith('Charge complete')), isTrue);
      expect(titles, contains('Payment successful'));
      expect(titles, contains('Password changed'));
      expect(titles, contains('Signed in with a one-time code'));
      // Every one of them is in this single list, none held elsewhere.
      expect(app.myNotifications.length, greaterThanOrEqualTo(5));
    });
  });
}
