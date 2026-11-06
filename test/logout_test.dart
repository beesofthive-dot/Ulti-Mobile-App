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

Future<void> start(WidgetTester tester, AppState app) async {
  await tester.pumpWidget(UltiChargeApp(state: app));
  await tester.pump(const Duration(milliseconds: 2500));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  test('attendant shift survives log out and is private to the account', () {
    final app = AppState();
    final efua = app.authenticate('020 000 0001', 'attend123')!;
    app.signIn(efua);
    app.clockIn();
    app.signOut();

    // Another attendant does not see Efua's shift.
    app.signIn(app.authenticate('020 000 0002', 'attend123')!);
    expect(app.shift.status, ShiftStatus.notStarted);
    app.signOut();

    // Efua comes back to her open shift at the same branch.
    app.signIn(efua);
    expect(app.shift.status, ShiftStatus.active);
    expect(app.branch?.name, 'MaxMart 37');
  });

  testWidgets('driver logs out from the account sheet', (tester) async {
    phone(tester);
    final app = AppState();
    await start(tester, app);
    app.signIn(app.authenticate('024 555 0187', 'driver123')!);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('KM').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('DRIVER'), findsOneWidget);
    await tester.ensureVisible(find.text('Log out'));
    await tester.pump();
    await tester.tap(find.text('Log out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(app.role, isNull);
    expect(find.text('Sign in to Ulti Charge'), findsOneWidget);
  });

  testWidgets('attendant top bar opens account sheet with shift warning', (
    tester,
  ) async {
    phone(tester);
    final app = AppState();
    await start(tester, app);
    app.signIn(app.authenticate('020 000 0002', 'attend123')!);
    app.clockIn();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('Shift running'), findsWidgets);
    await tester.tap(find.text('KA').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('SALES ATTENDANT'), findsOneWidget);
    await tester.ensureVisible(find.text('Log out'));
    await tester.pump();
    await tester.tap(find.text('Log out'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Your shift is still open'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(app.role, isNull);
    expect(app.authenticate('020 000 0002', 'attend123'), isNotNull);
  });
}
