import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ulti_charge/main.dart';
import 'package:ulti_charge/state.dart';

void main() {
  testWidgets('driver menu has four tabs; stations open from Home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final app = AppState();
    await tester.pumpWidget(UltiChargeApp(state: app));
    await tester.pump(const Duration(milliseconds: 3100));
    app.signIn(app.authenticate('024 555 0187', 'driver123')!);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final labels = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .map((d) => d.label)
        .toList();
    expect(labels, ['Home', 'Alerts', 'History', 'Profile']);

    await tester.tap(find.text('Find stations'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Charging stations'), findsWidgets);
    expect(find.text('MaxMart 37'), findsWidgets);
  });
}
