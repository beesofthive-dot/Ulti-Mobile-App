import 'package:flutter_test/flutter_test.dart';
import 'package:ulti_charge/state.dart';

void main() {
  test('a card scan payment notifies the attendant and the driver', () async {
    final app = AppState();
    app.signIn(app.authenticate('020 000 0001', 'attend123')!);
    app.clockIn();
    final driver = app.drivers.first;
    final s = app.startSession(
      driver: driver,
      charger: app.branch!.chargers.first,
    );
    app.recordReadings(
      s,
      kwh: 5,
      amount: 24,
      photo: false,
      notes: '',
      varianceReason: '',
    );
    await app.payWithCard(s, driver.cardId!);

    expect(app.banner?.title, 'Payment received');
    expect(
      app.myNotifications.where((n) => n.isMoney).map((n) => n.title),
      contains('Payment received'),
    );
    app.signOut();
    app.signIn(app.authenticate('024 555 0187', 'driver123')!);
    expect(
      app.myNotifications.map((n) => n.title),
      contains('Payment successful'),
    );
    expect(app.unreadCount, greaterThan(0));
    app.markAllRead();
    expect(app.unreadCount, 0);
  });

  test('loading money notifies the driver only', () async {
    final app = AppState();
    app.signIn(app.authenticate('024 555 0187', 'driver123')!);
    await app.loadMoney(50, '0245550187');
    expect(app.banner?.title, 'Money loaded');
    app.signOut();
    app.signIn(app.authenticate('020 000 0001', 'attend123')!);
    expect(app.myNotifications.any((n) => n.title == 'Money loaded'), false);
  });
}
