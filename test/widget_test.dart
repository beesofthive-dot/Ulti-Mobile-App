import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulti_charge/main.dart';
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
    expect(find.text('Phone number or password is incorrect.'), findsOneWidget);
  });

  testWidgets('attendant goes straight to clock in at the assigned terminal', (
    tester,
  ) async {
    phone(tester);
    await start(tester);
    await signIn(tester, '020 000 0001', 'attend123');
    expect(find.text('Assigned terminal'), findsOneWidget);
    expect(find.textContaining('MaxMart 37'), findsWidgets);
    expect(find.textContaining('pick your branch'), findsNothing);
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
    await start(tester);
    await tester.tap(find.text('Forgot password?'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('A reset code will be sent'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('A reset code will be sent'), findsNothing);
  });

  testWidgets('driver number opens driver home', (tester) async {
    phone(tester);
    await start(tester);
    await signIn(tester, '024 555 0187', 'driver123');
    expect(find.text('Available balance'), findsOneWidget);
    expect(find.text('Kwame'), findsOneWidget);
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
      expect(find.text('Assigned terminal'), findsOneWidget);
      expect(tester.getSize(find.byType(Scaffold).first).width, 430);
    });
  });
}
