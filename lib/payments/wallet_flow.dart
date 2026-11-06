import 'package:flutter/foundation.dart';

import '../models.dart';
import '../notifications/app_notification.dart';
import '../notifications/notification_feed.dart';
import 'payment_rules.dart';

/// Loading money onto the driver's card balance and withdrawing it, both
/// through Mobile Money. The provider answer is simulated.
mixin WalletFlow on ChangeNotifier, NotificationFeed {
  bool get online;
  Driver get me;

  static const minLoad = 1.0;
  static const maxLoad = 2000.0;
  static const minWithdraw = 5.0;

  /// Sends a MoMo prompt to [number] for [amount]; the balance is credited
  /// only after the driver approves. Returns an error message, or null.
  Future<String?> loadMoney(double amount, String number) async {
    final n = PaymentRules.momoNumber(number);
    if (n == null) return 'Enter a valid 10-digit MoMo number.';
    if (amount < minLoad) return 'Enter at least ${money(minLoad)}.';
    if (amount > maxLoad) {
      return 'The most you can load at once is ${money(maxLoad)}.';
    }
    if (!online) return 'No connection. Reconnect and try again.';
    final d = me;
    await Future<void>.delayed(const Duration(seconds: 3));
    d.walletBalance += amount;
    d.ledger.insert(0, WalletEntry(WalletEntryKind.load, amount, 'MoMo $n'));
    _note(
      d,
      'Money loaded',
      '${money(amount)} added from $n. New balance ${money(d.walletBalance)}.',
      Tone.success,
    );
    return null;
  }

  /// Sends [amount] from the card balance to the MoMo wallet at [number].
  /// Returns an error message, or null.
  Future<String?> withdraw(double amount, String number) async {
    final n = PaymentRules.momoNumber(number);
    final d = me;
    if (n == null) return 'Enter a valid 10-digit MoMo number.';
    if (amount < minWithdraw) {
      return 'The minimum withdrawal is ${money(minWithdraw)}.';
    }
    if (amount > d.walletBalance) {
      return 'You only have ${money(d.walletBalance)} available.';
    }
    if (!online) return 'No connection. Reconnect and try again.';
    await Future<void>.delayed(const Duration(seconds: 2));
    d.walletBalance -= amount;
    d.ledger.insert(
      0,
      WalletEntry(WalletEntryKind.withdraw, amount, 'MoMo $n'),
    );
    _note(
      d,
      'Withdrawal sent',
      '${money(amount)} sent to $n. New balance ${money(d.walletBalance)}.',
      Tone.success,
    );
    return null;
  }

  void _note(Driver d, String title, String body, Tone tone) => notify(
    AppNotification(
      title: title,
      body: body,
      tone: tone,
      category: NoteCategory.money,
      audience: Role.driver,
      driver: d,
    ),
  );
}
