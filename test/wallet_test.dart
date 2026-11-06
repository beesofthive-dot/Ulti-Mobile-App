import 'package:flutter_test/flutter_test.dart';
import 'package:ulti_charge/models.dart';
import 'package:ulti_charge/state.dart';

AppState driverApp() {
  final app = AppState();
  app.signIn(app.authenticate('024 555 0187', 'driver123')!);
  return app;
}

void main() {
  test('loading money credits the balance and records activity', () async {
    final app = driverApp();
    final before = app.me.walletBalance;
    expect(await app.loadMoney(50, '024 555 0187'), isNull);
    expect(app.me.walletBalance, before + 50);
    expect(app.me.ledger.first.kind, WalletEntryKind.load);
    expect(app.banner?.title, 'Money loaded');
  });

  test('withdrawing debits the balance', () async {
    final app = driverApp();
    final before = app.me.walletBalance;
    expect(await app.withdraw(40, '0245550187'), isNull);
    expect(app.me.walletBalance, before - 40);
    expect(app.me.ledger.first.kind, WalletEntryKind.withdraw);
  });

  test('invalid loads and withdrawals are rejected without changes', () async {
    final app = driverApp();
    final before = app.me.walletBalance;
    expect(await app.loadMoney(50, '123'), isNotNull);
    expect(await app.loadMoney(0, '0245550187'), isNotNull);
    expect(await app.loadMoney(99999, '0245550187'), isNotNull);
    expect(await app.withdraw(2, '0245550187'), isNotNull);
    expect(await app.withdraw(before + 1, '0245550187'), isNotNull);
    app.setOnline(false);
    expect(await app.loadMoney(50, '0245550187'), isNotNull);
    expect(app.me.walletBalance, before);
  });
}
