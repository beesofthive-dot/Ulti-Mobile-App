import 'package:flutter/material.dart';

import '../../../models.dart';
import '../../../state.dart';
import '../../../theme.dart';
import '../../../widgets/common.dart';
import '../../../widgets/motion.dart';
import 'money_sheet.dart';

/// Card balance: load money, withdraw, and the full activity list.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final me = app.me;
    final card = app.activeCard;
    final entries = me.ledger;
    return Scaffold(
      appBar: AppBar(title: const Text('My card balance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: heroGradient,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: UC.navy.withValues(alpha: .26),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                const HeroGlow(),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Available balance',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12.5,
                            ),
                          ),
                          const Spacer(),
                          const UcLogo(size: 28, wordmark: false),
                        ],
                      ),
                      const SizedBox(height: 8),
                      CountUp(
                        me.walletBalance,
                        format: money,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        card == null
                            ? 'No QR card linked'
                            : 'QR card •• ${card.last4}  ·  ${me.name}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _Action(
                              icon: Icons.add_rounded,
                              label: 'Load money',
                              filled: true,
                              onTap: () =>
                                  showMoneySheet(context, MoneyAction.load),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Action(
                              icon: Icons.north_east_rounded,
                              label: 'Withdraw',
                              onTap: () =>
                                  showMoneySheet(context, MoneyAction.withdraw),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader('Card balance', 'Activity'),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Panel(
              child: EmptyState(
                Icons.receipt_long_outlined,
                'No activity yet',
                'Loads, withdrawals and charges paid by card appear here.',
              ),
            )
          else
            Panel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) const Divider(indent: 68),
                    _EntryRow(entries[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: SizedBox(
        height: 48,
        child: filled
            ? FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: UC.teal,
                  foregroundColor: UC.navy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                onPressed: onTap,
                icon: Icon(icon, size: 20),
                label: Text(label),
              )
            : OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white38),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                onPressed: onTap,
                icon: Icon(icon, size: 20),
                label: Text(label),
              ),
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  final WalletEntry e;
  const _EntryRow(this.e);

  @override
  Widget build(BuildContext context) {
    final (icon, color, title) = switch (e.kind) {
      WalletEntryKind.load => (
        Icons.add_card_rounded,
        UC.success,
        'Money loaded',
      ),
      WalletEntryKind.withdraw => (
        Icons.north_east_rounded,
        UC.info,
        'Withdrawal',
      ),
      WalletEntryKind.charge => (
        Icons.bolt_rounded,
        UC.orange,
        'Charging payment',
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconTile(icon, color, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${e.label} · ${stamp(e.at)}',
                  style: TextStyle(fontSize: 11.5, color: UC.muted),
                ),
              ],
            ),
          ),
          Text(
            '${e.isCredit ? '+' : '−'} ${money(e.amount)}',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: e.isCredit ? UC.success : UC.ink,
            ),
          ),
        ],
      ),
    );
  }
}
