import '../models.dart';

/// Who is making the payment.
enum PaymentParty {
  /// The driver pays from their own app.
  driver,

  /// A sales attendant collects at the branch machine.
  sales,
}

/// Single place for what each party may pay with and what each method needs.
class PaymentRules {
  const PaymentRules._();

  /// At the branch: scan the driver's QR from their app (wallet), scan the
  /// QR card on the machine, or send a Mobile Money prompt.
  static List<PayMethod> methodsFor(PaymentParty party) => switch (party) {
    PaymentParty.driver => const [PayMethod.wallet, PayMethod.momo],
    PaymentParty.sales => const [
      PayMethod.wallet,
      PayMethod.card,
      PayMethod.momo,
    ],
  };

  /// Why the scanned card cannot pay for [s], or null when it can.
  static String? cardProblem(ChargeSession s, String scannedCard) {
    if (s.driver.cardId == null) {
      return 'No QR card is linked to ${s.driver.name}.';
    }
    if (scannedCard.trim().toUpperCase() != s.driver.cardId) {
      return 'This card is not linked to ${s.driver.name}.';
    }
    if (s.driver.walletBalance < s.due) {
      return 'Card balance ${money(s.driver.walletBalance)} is lower than ${money(s.due)}.';
    }
    return null;
  }

  /// Local-format Ghana mobile number (0XXXXXXXXX), or null if invalid.
  static String? momoNumber(String input) {
    var d = input.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('233') && d.length == 12) d = '0${d.substring(3)}';
    return RegExp(r'^0[235]\d{8}$').hasMatch(d) ? d : null;
  }
}
