import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// DR-07 Manage cards.
class ManageCardsScreen extends StatelessWidget {
  const ManageCardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('My cards')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          if (app.cards.isEmpty)
            const Panel(
              child: EmptyState(
                Icons.credit_card_off_outlined,
                'No cards linked',
                'Link a physical Ulti Charge QR card.',
              ),
            ),
          for (final c in app.cards)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CardTile(c),
            ),
          const SizedBox(height: 6),
          PrimaryButton(
            'Link a QR card',
            leading: Icons.add_card_rounded,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const LinkCardScreen())),
          ),
          const SizedBox(height: 14),
          const InfoBanner(
            'Lost your card? Block it immediately. Blocked cards are rejected on every scan — you can still pay with My QR in the app.',
            icon: Icons.shield_outlined,
            tone: Tone.neutral,
          ),
        ],
      ),
    );
  }
}

class _CardTile extends StatelessWidget {
  final QrCard c;
  const _CardTile(this.c);

  @override
  Widget build(BuildContext context) {
    final app = AppScope.read(context);
    final info = cardInfo(c.status);
    final live = c.status == CardStatus.active;
    return Container(
      decoration: BoxDecoration(
        color: live ? UC.primary : UC.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: live ? UC.primary : UC.line),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UcLogo(size: 24, wordmark: false),
              const Spacer(),
              StatusChip.of(info),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            '••••  ••••  ${c.last4}',
            style: TextStyle(
              color: live ? Colors.white : UC.ink,
              fontSize: 20,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${c.id} · Last used ${c.lastUsed == null ? 'never' : dm(c.lastUsed!)}',
            style: TextStyle(
              color: live ? Colors.white60 : UC.muted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            info.explanation,
            style: TextStyle(
              color: live ? Colors.white38 : UC.faint,
              fontSize: 11.5,
            ),
          ),
          if (live || c.status == CardStatus.blocked) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 42,
              width: double.infinity,
              child: live
                  ? FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: UC.danger,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.block_rounded, size: 18),
                      label: const Text('Block card'),
                      onPressed: () async {
                        final ok = await confirmDialog(
                          context,
                          title: 'Block card •• ${c.last4}?',
                          confirm: 'Block now',
                          color: UC.danger,
                          body: const Text(
                            'The card will be rejected immediately at every branch. This cannot be undone — you will need a replacement card.',
                          ),
                        );
                        if (ok) {
                          app.blockCard(c);
                          if (context.mounted) {
                            toast(context, 'Card blocked', tone: Tone.warning);
                          }
                        }
                      },
                    )
                  : OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: UC.ink,
                        side: BorderSide(color: UC.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.autorenew_rounded, size: 18),
                      label: const Text('Request replacement'),
                      onPressed: () {
                        app.requestReplacement(c);
                        toast(
                          context,
                          'Replacement requested — collect it at any branch',
                          tone: Tone.success,
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// DR-06 Link QR card.
class LinkCardScreen extends StatefulWidget {
  const LinkCardScreen({super.key});

  @override
  State<LinkCardScreen> createState() => _LinkCardScreenState();
}

class _LinkCardScreenState extends State<LinkCardScreen> {
  final code = TextEditingController();
  final verify = TextEditingController();
  String? err;
  bool busy = false;

  Future<void> _link() async {
    final app = AppScope.read(context);
    final digits = app.me.phone.replaceAll(' ', '');
    if (verify.text.trim() != digits.substring(digits.length - 4)) {
      setState(
        () => err = 'Ownership check failed: enter the last 4 digits of your registered number.',
      );
      return;
    }
    setState(() {
      busy = true;
      err = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final e = app.linkCard(code.text);
    setState(() {
      busy = false;
      err = e;
    });
    if (e == null) {
      toast(context, 'Card linked', tone: Tone.success);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link QR card')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: UC.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    border: Border.all(color: UC.lime, width: 3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white38,
                  size: 56,
                ),
                const Positioned(
                  bottom: 14,
                  child: Text(
                    'Point the camera at the back of your card',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          LabeledField(
            label: 'Or enter card code',
            hint: 'UC-0000-0000',
            icon: Icons.credit_card_rounded,
            controller: code,
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Verify ownership',
            hint: 'Last 4 digits of your mobile',
            icon: Icons.verified_user_outlined,
            controller: verify,
            keyboardType: TextInputType.number,
            helper: 'We only link one card per account. Used or blocked cards are rejected.',
          ),
          if (err != null) ...[
            const SizedBox(height: 14),
            InfoBanner(err!, tone: Tone.danger, icon: Icons.error_outline),
          ],
          const SizedBox(height: 22),
          PrimaryButton('Link card', busy: busy, onPressed: _link),
        ],
      ),
    );
  }
}
