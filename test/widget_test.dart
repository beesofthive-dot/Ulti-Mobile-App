import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulti_charge/main.dart';
import 'package:ulti_charge/models.dart';
import 'package:ulti_charge/state.dart';

void phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> signIn(WidgetTester tester, String number, String password) async {
  await tester.enterText(find.byType(TextField).at(0), number);
  await tester.enterText(find.byType(TextField).at(1), password);
  await tester.tap(find.text('Sign in'));
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
}

/// Pumps the app and waits past the logo loading screen.
Future<void> start(WidgetTester tester) async {
  await tester.pumpWidget(UltiChargeApp(state: AppState()));
  await tester.pump(const Duration(milliseconds: 2500));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  testWidgets('loading screen shows logo tagline', (tester) async {
    phone(tester);
    await tester.pumpWidget(UltiChargeApp(state: AppState()));
    await tester.pump(const Duration(milliseconds: 1800));
    expect(find.text('Your Power, Partner...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('single login screen has no role picker', (tester) async {
    phone(tester);
    await start(tester);
    expect(find.text('Sign in to Ulti Charge'), findsOneWidget);
    expect(find.text('Driver'), findsNothing);
    expect(find.text('Sales attendant'), findsNothing);
  });

  testWidgets('wrong password shows an error', (tester) async {
    phone(tester);
    await start(tester);
    await signIn(tester, '020 000 0001', 'nope');
    expect(find.text('Phone, email or password is incorrect.'), findsOneWidget);
  });

  testWidgets('attendant is view-only until the shift is started', (
    tester,
  ) async {
    phone(tester);
    await start(tester);
    await signIn(tester, '020 000 0001', 'attend123');
    // Lands in the app, off shift: records only.
    expect(find.textContaining('MaxMart 37'), findsWidgets);
    expect(find.text('Start shift'), findsWidgets);
    expect(find.textContaining('pick your branch'), findsNothing);
    // The Record tab is locked.
    await tester.tap(find.text('Record'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('You are not on shift'), findsOneWidget);
    // Starting the shift opens the assigned terminal screen, then the app.
    await tester.tap(find.text('Start shift').hitTestable().first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Assigned terminal'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Start shift'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Start shift').hitTestable().first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Assigned terminal'), findsNothing);
    expect(find.textContaining('You are not on shift'), findsNothing);
  });

  testWidgets('unassigned attendant waits for assignment', (tester) async {
    phone(tester);
    await start(tester);
    await signIn(tester, '020 000 0003', 'attend123');
    expect(find.text('No terminal assigned'), findsOneWidget);
  });

  testWidgets('a top banner shows without errors and can be dismissed', (
    tester,
  ) async {
    phone(tester);
    final app = AppState();
    await tester.pumpWidget(UltiChargeApp(state: app));
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 600));
    app.flash('Hello from a banner');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Hello from a banner'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Hello from a banner'), findsNothing);
  });

  testWidgets('sign in with an SMS code', (tester) async {
    phone(tester);
    await start(tester);
    await tester.tap(find.text('One-time code'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField).at(0), '024 555 0187');
    await tester.tap(find.text('Send code'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Enter your code'), findsOneWidget);
    expect(find.textContaining('Your Ulti Charge code is'), findsOneWidget);
    // The demo SMS fills and submits the code.
    await tester.tap(find.textContaining('Your Ulti Charge code is'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Available balance'), findsOneWidget);
  });

  testWidgets('forgot password resets it with a code', (tester) async {
    phone(tester);
    final app = AppState();
    await tester.pumpWidget(UltiChargeApp(state: app));
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Forgot password?'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Reset your password'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), '024 555 0187');
    await tester.tap(find.text('Send code'));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.textContaining('Your Ulti Charge code is'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Create a new password'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'newpass77');
    await tester.enterText(find.byType(TextField).at(1), 'newpass77');
    await tester.tap(find.text('Save password'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Password updated'), findsOneWidget);
    expect(app.authenticate('0245550187', 'newpass77'), isNotNull);
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('driver number opens driver home', (tester) async {
    phone(tester);
    await start(tester);
    await signIn(tester, '024 555 0187', 'driver123');
    expect(find.text('Available balance'), findsOneWidget);
    expect(find.textContaining('Kwame'), findsWidgets);
  });

  group('desktop-size window still shows a phone app', () {
    void desktop(WidgetTester tester) {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }

    testWidgets('driver screens are phone width', (tester) async {
      desktop(tester);
      await start(tester);
      await signIn(tester, '024 555 0187', 'driver123');
      expect(find.text('Available balance'), findsOneWidget);
      expect(tester.getSize(find.byType(NavigationBar)).width, 430);
    });

    testWidgets('attendant screens are phone width', (tester) async {
      desktop(tester);
      await start(tester);
      await signIn(tester, '020 000 0002', 'attend123');
      expect(find.text('Start shift'), findsWidgets);
      expect(tester.getSize(find.byType(Scaffold).first).width, 430);
    });
  });

  testWidgets('driver approves a scanned QR request and is charged', (
    tester,
  ) async {
    phone(tester);
    final app = AppState();
    // Attendant side: a billed charge, and the driver's QR on screen.
    app.signIn(app.authenticate('020 000 0001', 'attend123')!);
    app.clockIn();
    final s = app.startSession(
      driver: app.drivers.first,
      charger: app.branch!.chargers.first,
    );
    app.recordReadings(
      s,
      kwh: 24 / s.tariff,
      amount: 24,
      photo: false,
      notes: '',
      varianceReason: '',
    );
    app.registerQr(s.driver, 'ABCD2345EFGH', const Duration(seconds: 60));
    final before = s.driver.walletBalance;
    // The scan opens a request (real delay inside, so run it for real).
    late Future<dynamic> result;
    await tester.runAsync(() async {
      result = app.requestQrPayment(s, app.liveQrPayload(s.driver)!);
      await Future<void>.delayed(const Duration(milliseconds: 1300));
    });
    expect(app.awaitingQr(s), isTrue);

    // Driver side: sign in and the approval sheet appears.
    app.signOut();
    app.signIn(app.authenticate('024 555 0187', 'driver123')!);
    await tester.pumpWidget(UltiChargeApp(state: app));
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('PAYMENT REQUEST'), findsOneWidget);
    expect(find.text('Balance after'), findsOneWidget);

    await tester.tap(find.textContaining('Pay GH'));
    await tester.pump();
    await tester.runAsync(() async => await result);
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Payment successful'), findsWidgets);
    expect(s.driver.walletBalance, before - 24);
    expect(s.status, SessionStatus.paid);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
  });
}
