import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import '../../widgets/receipt.dart';

/// DR-08 Transaction history.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final q = TextEditingController();
  int days = 0; // 0 = all

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final now = DateTime.now();
    final t = q.text.trim().toLowerCase();
    final list = app.myHistory.where((s) {
      if (days > 0 && now.difference(s.startedAt).inDays >= days) return false;
      if (t.isEmpty) return true;
      return s.branch.name.toLowerCase().contains(t) ||
          s.id.toLowerCase().contains(t);
    }).toList();
    final total = list.fold<double>(0, (a, s) => a + s.paidAmount);
    final kwh = list.fold<double>(0, (a, s) => a + (s.kwh ?? 0));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        PageHeader(
          eyebrow: 'Your activity',
          title: 'Transactions',
          subtitle: 'Receipts, payments and disputes in one place.',
          icon: Icons.receipt_long_rounded,
          bottom: Row(
            children: [
              const Text(
                'Total spent  ',
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              CountUp(
                app.myHistory.fold<double>(0, (a, s) => a + s.paidAmount),
                format: money,
                style: const TextStyle(
                  color: UC.teal,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: q,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search station or session ID',
            prefixIcon: Icon(Icons.search_rounded, color: UC.faint),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            for (final (d, l) in [(0, 'All'), (7, '7 days'), (30, '30 days')])
              ChoiceChip(
                label: Text(l),
                selected: days == d,
                showCheckmark: false,
                selectedColor: UC.accent,
                backgroundColor: UC.surface,
                labelStyle: TextStyle(
                  color: days == d ? UC.onAccent : UC.ink,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(color: days == d ? UC.accent : UC.line),
                onSelected: (_) => setState(() => days = d),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _Mini('Spent', money(total))),
            const SizedBox(width: 10),
            Expanded(child: _Mini('Energy', '${kwh.toStringAsFixed(1)} kWh')),
            const SizedBox(width: 10),
            Expanded(child: _Mini('Sessions', '${list.length}')),
          ],
        ),
        const SizedBox(height: 14),
        if (list.isEmpty)
          const Panel(
            child: EmptyState(
              Icons.receipt_long_outlined,
              'No transactions',
              'Try a different search or date range.',
            ),
          )
        else
          Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < list.length; i++) ...[
                  if (i > 0) const Divider(indent: 16, endIndent: 16),
                  FadeSlideIn(index: i, offset: 10, child: HistoryRow(list[i])),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Mini extends StatelessWidget {
  final String label, value;
  const _Mini(this.label, this.value);
  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: UC.muted)),
        const SizedBox(height: 4),
        FittedBox(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class HistoryRow extends StatelessWidget {
  final ChargeSession s;
  const HistoryRow(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = s.paymentStatus;
    final label = s.disputed
        ? const StatusInfo('Disputed', UC.purple, '', '')
        : p == null
        ? sessionInfo(s.status)
        : p == PaymentStatus.confirmed
        ? const StatusInfo('Paid', UC.success, '', '')
        : paymentInfo(p);
    return Padding(
      padding: const EdgeInsets.all(5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => DriverReceiptScreen(s))),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              IconTile(Icons.bolt_rounded, UC.accent, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.branch.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(s.kwh ?? 0).toStringAsFixed(1)} kWh · ${dm(s.startedAt)}, ${hm(s.startedAt)}',
                      style: TextStyle(fontSize: 11.5, color: UC.muted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money(s.paidAmount > 0 ? s.paidAmount : s.due),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label.label,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: label.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DriverReceiptScreen extends StatelessWidget {
  final ChargeSession s;
  const DriverReceiptScreen(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          ReceiptCard(s),
          const SizedBox(height: 14),
          if (s.disputed)
            const InfoBanner(
              'Dispute submitted. Our team will respond within 2 business days.',
              tone: Tone.warning,
              icon: Icons.hourglass_top_rounded,
            ),
          const SizedBox(height: 14),
          GhostButton(
            'Share receipt',
            icon: Icons.ios_share_rounded,
            onPressed: () => copyReceipt(context, s),
          ),
          const SizedBox(height: 10),
          if (!s.disputed)
            GhostButton(
              'Dispute transaction',
              icon: Icons.report_gmailerrorred_rounded,
              color: UC.danger,
              onPressed: () async {
                final r = await reasonDialog(
                  context,
                  title: 'Dispute transaction',
                  hint: 'What is wrong with this charge?',
                );
                if (r != null) {
                  app.dispute(s, r);
                  if (context.mounted) {
                    toast(context, 'Dispute submitted', tone: Tone.success);
                  }
                }
              },
            ),
        ],
      ),
    );
  }
}
