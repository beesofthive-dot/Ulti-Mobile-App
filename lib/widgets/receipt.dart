import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';
import 'common.dart';

/// Immutable receipt view shared by attendant (AT-09) and driver (DR-08).
class ReceiptCard extends StatelessWidget {
  final ChargeSession s;
  const ReceiptCard(this.s, {super.key});

  static String asText(ChargeSession s) {
    final b = StringBuffer()
      ..writeln('ULTI CHARGE — RECEIPT')
      ..writeln('Session: ${s.id}')
      ..writeln('Branch: ${s.branch.name}')
      ..writeln('Charger: ${s.charger.label}')
      ..writeln('Date: ${dmy(s.startedAt)} ${hm(s.startedAt)}')
      ..writeln('Energy: ${(s.kwh ?? 0).toStringAsFixed(2)} kWh')
      ..writeln('Tariff: ${money(s.tariff)}/kWh')
      ..writeln('Machine amount: ${money(s.machineAmount ?? 0)}')
      ..writeln(
        'Paid: ${money(s.paidAmount)} via ${s.payMethod == null ? '—' : payMethodLabel(s.payMethod!)}',
      )
      ..writeln('Reference: ${s.paymentRef.isEmpty ? '—' : s.paymentRef}');
    return b.toString();
  }

  @override
  Widget build(BuildContext context) {
    final p = s.paymentStatus;
    final cashPending = s.payMethod == PayMethod.cash;
    return Container(
      decoration: BoxDecoration(
        color: UC.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: UC.line),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: const BoxDecoration(
              color: UC.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const UcLogo(size: 26, wordmark: false),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Charging receipt',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (p != null)
                      StatusChip(
                        cashPending
                            ? 'Cash · reconciling'
                            : paymentInfo(p).label,
                        cashPending ? UC.lime : paymentInfo(p).color,
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Amount paid',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  money(s.paidAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: [
                KV('Session ID', s.id),
                KV('Date', '${dmy(s.startedAt)} · ${hm(s.startedAt)}'),
                KV('Branch', s.branch.name),
                KV('Charger', s.charger.label),
                KV('Driver', s.driver.name),
                KV('Vehicle', s.driver.plate),
                const Divider(height: 20),
                KV(
                  'Energy delivered',
                  '${(s.kwh ?? 0).toStringAsFixed(2)} kWh',
                ),
                KV('Tariff', '${money(s.tariff)} / kWh'),
                KV('Machine amount', money(s.machineAmount ?? 0)),
                if (s.varianceFlag)
                  KV(
                    'Variance',
                    '${(s.variance ?? 0) >= 0 ? '+' : ''}${(s.variance ?? 0).toStringAsFixed(2)} · under review',
                    color: UC.danger,
                  ),
                const Divider(height: 20),
                KV(
                  'Payment method',
                  s.payMethod == null ? '—' : payMethodLabel(s.payMethod!),
                ),
                KV(
                  'Payment reference',
                  s.paymentRef.isEmpty ? '—' : s.paymentRef,
                ),
                KV('Attendant', s.attendant),
                KV('Paid amount', money(s.paidAmount), strong: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> copyReceipt(BuildContext context, ChargeSession s) async {
  await Clipboard.setData(ClipboardData(text: ReceiptCard.asText(s)));
  if (context.mounted) {
    toast(
      context,
      'Receipt copied — paste to share or print',
      tone: Tone.success,
    );
  }
}

/// Immutable audit trail of events for a session.
class EventTrail extends StatelessWidget {
  final ChargeSession s;
  const EventTrail(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Event trail'),
          const SizedBox(height: 10),
          for (final e in s.events)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: UC.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.label,
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                  Text(
                    hm(e.at),
                    style: TextStyle(fontSize: 11.5, color: UC.muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
