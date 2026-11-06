import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/account_sheet.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'cards_screen.dart';

/// DR-10 Profile & support.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final me = app.me;
    void push(Widget w) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => w));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        PageHeader(
          eyebrow: 'My account',
          title: me.name,
          subtitle: me.phone,
          trailing: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [UC.teal, UC.brandGreen]),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: UC.navy,
              child: Text(
                me.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          bottom: Row(
            children: [
              const _HeaderChip(Icons.verified_rounded, 'Verified'),
              const SizedBox(width: 8),
              _HeaderChip(Icons.stars_rounded, '${app.rewardPoints} pts'),
              const Spacer(),
              PressScale(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: UC.navy,
                    backgroundColor: UC.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => push(const EditProfileScreen()),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text(
                    'Edit',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Group('Vehicles', [
          _Item(
            Icons.directions_car_outlined,
            me.plate,
            me.vehicleType,
            () => push(const EditProfileScreen()),
          ),
        ]),
        _Group('Payments', [
          _Item(
            Icons.credit_card_rounded,
            'My cards',
            app.activeCard == null
                ? 'No active card'
                : 'Active •• ${app.activeCard!.last4}',
            () => push(const ManageCardsScreen()),
          ),
          _Item(
            Icons.add_card_rounded,
            'Link QR card',
            'Scan a physical card',
            () => push(const LinkCardScreen()),
          ),
          _Item(
            Icons.card_giftcard_rounded,
            'Rewards',
            '${app.rewardPoints} points',
            () => push(const RewardsScreen()),
          ),
        ]),
        _Group('Settings', [
          _Item(
            Icons.lock_outline_rounded,
            'Security',
            'Password, PIN',
            () => toast(context, 'Security settings are coming soon.'),
          ),
          _Item(
            Icons.notifications_none_rounded,
            'Notifications',
            'Receipts, offers, card alerts',
            () => toast(context, 'Notification preferences are coming soon.'),
          ),
          _Item(
            Icons.support_agent_rounded,
            'Help & support',
            'Raise an issue',
            () => push(const SupportScreen()),
          ),
        ]),
        const SizedBox(height: 6),
        GhostButton(
          'Log out',
          icon: Icons.logout_rounded,
          color: UC.danger,
          onPressed: () async {
            if (await confirmLogout(context)) app.signOut();
          },
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeaderChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: UC.teal),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> items;
  const _Group(this.title, this.items);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Eyebrow(title),
          ),
          Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(indent: 60),
                  items[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String title, sub;
  final VoidCallback onTap;
  const _Item(this.icon, this.title, this.sub, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InsetTile(
      onTap: onTap,
      leading: IconTile(icon, UC.primary, size: 36),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        sub,
        style: const TextStyle(fontSize: 12, color: UC.muted),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: UC.faint),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final AppState app = AppScope.read(context);
  late final name = TextEditingController(text: app.me.name);
  late final plate = TextEditingController(text: app.me.plate);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          LabeledField(
            label: 'Full name',
            icon: Icons.person_outline,
            controller: name,
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Mobile number',
            icon: Icons.phone_iphone_rounded,
            controller: TextEditingController(text: app.me.phone),
            readOnly: true,
            helper: 'Changing your number requires OTP verification.',
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Vehicle plate',
            icon: Icons.directions_car_outlined,
            controller: plate,
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            'Save changes',
            onPressed: () {
              app.me
                ..name = name.text.trim()
                ..plate = plate.text.trim().toUpperCase();
              app.touch();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

/// DR-09 Rewards.
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: UC.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Points balance',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${app.rewardPoints}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        '1 point per GH₵ 1 spent',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const IconTile(Icons.card_giftcard_rounded, UC.lime, size: 56),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionHeader('Offers', 'Active offers'),
          const SizedBox(height: 10),
          for (final o in app.offers)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            o.title,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        o.campaignEnabled
                            ? StatusChip(
                                '${o.points} pts',
                                UC.primary,
                                dot: false,
                              )
                            : const StatusChip(
                                'Coming soon',
                                UC.muted,
                                dot: false,
                              ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      o.detail,
                      style: const TextStyle(fontSize: 12.5, color: UC.muted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Expires ${dmy(o.expires)} · Terms apply',
                      style: const TextStyle(fontSize: 11, color: UC.faint),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: UC.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed:
                            o.campaignEnabled && app.rewardPoints >= o.points
                            ? () async {
                                final ok = await confirmDialog(
                                  context,
                                  title: 'Redeem ${o.title}?',
                                  confirm: 'Redeem',
                                  body: Text(
                                    '${o.points} points will be deducted. Show the confirmation to the attendant on your next charge.',
                                  ),
                                );
                                if (ok && app.redeem(o) && context.mounted) {
                                  toast(
                                    context,
                                    'Redeemed ${o.title}',
                                    tone: Tone.success,
                                  );
                                }
                              }
                            : null,
                        child: Text(
                          !o.campaignEnabled
                              ? 'Campaign not live'
                              : app.rewardPoints < o.points
                              ? 'Not enough points'
                              : 'Redeem',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          const SectionHeader('History', 'Redemptions'),
          const SizedBox(height: 10),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (app.redemptions.isEmpty)
                  const Text(
                    'No redemptions yet',
                    style: TextStyle(color: UC.muted),
                  ),
                for (final r in app.redemptions)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(r, style: const TextStyle(fontSize: 13)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String topic = 'Charge or payment';
  final msg = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          const Text(
            'What do you need help with?',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in const [
                'Charge or payment',
                'QR card',
                'Wallet top-up',
                'Station issue',
                'Account',
              ])
                ChoiceChip(
                  label: Text(t),
                  selected: topic == t,
                  showCheckmark: false,
                  selectedColor: UC.limeSoft,
                  backgroundColor: UC.surface,
                  side: BorderSide(color: topic == t ? UC.primary : UC.line),
                  onSelected: (_) => setState(() => topic = t),
                ),
            ],
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Describe the issue',
            hint: 'Include session ID if you have it',
            controller: msg,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            'Submit issue',
            onPressed: msg.text.trim().length < 10
                ? null
                : () {
                    toast(
                      context,
                      'Issue submitted — we will reply by SMS',
                      tone: Tone.success,
                    );
                    Navigator.of(context).pop();
                  },
          ),
          const SizedBox(height: 18),
          const InfoBanner(
            'Urgent? Call the branch from the station page.',
            icon: Icons.call_outlined,
            tone: Tone.neutral,
          ),
        ],
      ),
    );
  }
}
