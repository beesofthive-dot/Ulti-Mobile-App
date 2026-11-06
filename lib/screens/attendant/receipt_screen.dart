import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state.dart';
import '../../widgets/common.dart';
import '../../widgets/receipt.dart';

/// AT-09 Receipt.
class ReceiptScreen extends StatelessWidget {
  final ChargeSession s;
  const ReceiptScreen(this.s, {super.key});

  @override
  Widget build(BuildContext context) {
    AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          StatusPanel(sessionInfo(s.status), s.events.last.at),
          const SizedBox(height: 14),
          ReceiptCard(s),
          const SizedBox(height: 12),
          const InfoBanner(
            'Receipts cannot be edited. Corrections require a void request approved by a manager.',
            tone: Tone.neutral,
            icon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GhostButton(
                  'Share',
                  icon: Icons.ios_share_rounded,
                  onPressed: () => copyReceipt(context, s),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GhostButton(
                  'Print',
                  icon: Icons.print_outlined,
                  onPressed: () => copyReceipt(context, s),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          EventTrail(s),
          const SizedBox(height: 18),
          PrimaryButton(
            'Done',
            trailing: null,
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
    );
  }
}
