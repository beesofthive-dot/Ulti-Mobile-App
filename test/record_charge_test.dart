import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulti_charge/main.dart';
import 'package:ulti_charge/models.dart';
import 'package:ulti_charge/payments/charge_math.dart';
import 'package:ulti_charge/state.dart';

void main() {
  group('charge arithmetic', () {
    test('typed kWh and cedis are parsed strictly', () {
      expect(ChargeMath.kwhToWh('42.5'), 42500);
      expect(ChargeMath.kwhToWh(' 1 '), 1000);
      expect(ChargeMath.kwhToWh('0.001'), 1);
      expect(ChargeMath.kwhToWh('0'), isNull);
      expect(ChargeMath.kwhToWh('abc'), isNull);
      expect(ChargeMath.kwhToWh('1.2345'), isNull);
      expect(ChargeMath.cedisToPesewas('50'), 5000);
      expect(ChargeMath.cedisToPesewas('50.5'), 5050);
      expect(ChargeMath.cedisToPesewas('GHS 12.30'), 1230);
      expect(ChargeMath.cedisToPesewas('1.234'), isNull);
      expect(ChargeMath.cedisToPesewas('-3'), isNull);
    });

    test('amounts match the web portal (rate GH₵ 0.70/kWh)', () {
      const rate = 70;
      expect(ChargeMath.amountFor(1000, rate), 70); // 1 kWh  → GH₵ 0.70
      expect(ChargeMath.amountFor(1500, rate), 105); // 1.5 kWh → GH₵ 1.05
      // 50 cedis buys the whole number of Wh that comes closest to it.
      final wh = ChargeMath.energyForAmount(5000, rate);
      expect(wh, 71429);
      expect(ChargeMath.amountFor(wh, rate), 5000);
    });

    test('amount → kWh → amount never drifts by more than a pesewa', () {
      for (final rate in [70, 480, 515]) {
        for (var p = 1; p < 3000; p += 37) {
          final wh = ChargeMath.energyForAmount(p, rate);
          expect(
            (ChargeMath.amountFor(wh, rate) - p).abs(),
            lessThanOrEqualTo(1),
          );
        }
      }
    });
  });

  group('record a charge', () {
    AppState attendant() {
      final app = AppState();
      app.signIn(app.authenticate('020 000 0001', 'attend123')!);
      app.clockIn();
      return app;
    }

    test('saves it awaiting payment and tells both sides', () {
      final app = attendant();
      final s = app.recordCharge(
        driver: app.drivers.first,
        charger: app.branch!.chargers.first,
        kwh: 1.5,
        amount: 7.2,
      );
      expect(s.status, SessionStatus.awaitingPayment);
      expect(s.kwh, 1.5);
      expect(s.due, 7.2);
      expect(s.stoppedAt, isNotNull);
      expect(s.varianceFlag, isFalse);
      expect(app.todaySessions, contains(s));

      final titles = app.notifications.map((n) => n.title).toList();
      expect(titles, contains('Charge recorded')); // attendant
      expect(
        titles.any((t) => t.startsWith('Charge complete')),
        isTrue,
      ); // driver
    });

    test('shift cannot close while a charge is unpaid, and counts it', () {
      final app = attendant();
      final s = app.recordCharge(
        driver: app.drivers.first,
        charger: app.branch!.chargers.first,
        kwh: 2,
        amount: 9.6,
      );
      expect(app.pendingPayments, 1);
      expect(app.collected, 0);
      app.requestVoid(s, 'Recorded by mistake');
      expect(s.voidRequested, isTrue);
    });
  });

  testWidgets('Record tab works the number out, Shift tab blocks closing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final app = AppState();
    app.signIn(app.authenticate('020 000 0001', 'attend123')!);
    app.clockIn();
    await tester.pumpWidget(UltiChargeApp(state: app));
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 900));

    await tester.tap(find.text('Record').last);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Record a charge'), findsOneWidget);
    expect(find.text('1. Which port?'), findsOneWidget);
    expect(find.text('Enter kWh'), findsOneWidget);

    // 1.5 kWh at the branch tariff, shown before anything is saved.
    // The field is below the port cards: scroll the form up to it.
    await tester.drag(
      find.descendant(
        of: find.byKey(const ValueKey('form')),
        matching: find.byType(ListView),
      ),
      const Offset(0, -250),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), '1.5');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(money(app.branch!.tariff * 1.5)), findsOneWidget);

    // Switching to amount carries the figure across.
    await tester.tap(find.text('Enter amount'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Energy (worked out)'), findsOneWidget);

    // A recorded, unpaid charge stops the shift from closing.
    app.recordCharge(
      driver: app.drivers.first,
      charger: app.branch!.chargers.first,
      kwh: 1.5,
      amount: 7.2,
    );
    await tester.tap(find.text('Shift').last);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      find.textContaining('You cannot close the shift yet.'),
      findsOneWidget,
    );
    // Closing is disabled until the charge is paid or cancelled.
    await tester.drag(
      find.byType(ListView).hitTestable(),
      const Offset(0, -350),
    );
    await tester.pump(const Duration(milliseconds: 400));
    final close = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Close shift'),
    );
    expect(close.onPressed, isNull);
    await tester.pump(const Duration(seconds: 1));
  });
}
