/// Charge arithmetic for "Record a charge": kWh and amount are worked out
/// from each other at the branch rate, kept in whole Wh and whole pesewas so
/// what is shown is exactly what gets saved.
class ChargeMath {
  const ChargeMath._();

  /// The most energy one charge can hold (1,000 kWh), in Wh.
  static const maxWh = 1000000;

  /// Rate in pesewas per kWh from a tariff in cedis (4.80 → 480).
  static int ratePesewas(double tariffCedis) => (tariffCedis * 100).round();

  /// "42.5" → 42500 Wh, or null when it is not a usable kWh figure (up to
  /// three decimals, above zero).
  static int? kwhToWh(String input) {
    final t = input.trim();
    if (!RegExp(r'^\d+(\.\d{1,3})?$').hasMatch(t)) return null;
    final wh = (double.parse(t) * 1000).round();
    return wh > 0 ? wh : null;
  }

  /// "50" or "50.5" → 5000 / 5050 pesewas, or null when it is not an amount
  /// in cedis (up to two decimals, above zero). A leading GHS / GH₵ is fine.
  static int? cedisToPesewas(String input) {
    final t = input.trim().replaceFirst(
      RegExp(r'^(GHS|GH₵)\s*', caseSensitive: false),
      '',
    );
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(t)) return null;
    final p = (double.parse(t) * 100).round();
    return p > 0 ? p : null;
  }

  /// Price of [wh] at [ratePesewasPerKwh], rounded half-up to a pesewa.
  static int amountFor(int wh, int ratePesewasPerKwh) =>
      (wh * ratePesewasPerKwh + 500) ~/ 1000;

  /// The whole number of Wh whose price comes closest to [amountPesewas].
  static int energyForAmount(int amountPesewas, int ratePesewasPerKwh) {
    final nearest =
        (amountPesewas * 1000 + ratePesewasPerKwh ~/ 2) ~/ ratePesewasPerKwh;
    var best = nearest;
    var bestGap = (amountFor(nearest, ratePesewasPerKwh) - amountPesewas).abs();
    for (final c in [nearest - 1, nearest + 1]) {
      if (c <= 0) continue;
      final gap = (amountFor(c, ratePesewasPerKwh) - amountPesewas).abs();
      if (gap < bestGap) {
        best = c;
        bestGap = gap;
      }
    }
    return best;
  }
}
