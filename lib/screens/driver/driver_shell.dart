import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/account_sheet.dart';
import '../../widgets/common.dart';
import '../../widgets/info_carousel.dart';
import '../../widgets/motion.dart';
import '../../widgets/notification_host.dart';
import 'cards_screen.dart';
import 'history_screen.dart';
import 'my_qr_screen.dart';
import 'profile_screen.dart';
import 'stations_screen.dart';
import 'wallet/money_sheet.dart';
import 'wallet/wallet_screen.dart';

/// Bottom navigation: Home | Pay | History | Profile.
/// Stations open as their own page from Home.
class DriverShell extends StatefulWidget {
  const DriverShell({super.key});

  @override
  State<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends State<DriverShell>
    with SingleTickerProviderStateMixin {
  int index = 0;

  // Fades / lifts the tab body in on each tab change; IndexedStack keeps
  // each tab's state (search text, QR timer, scroll position).
  late final AnimationController tabAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    value: 1,
  );

  void _go(int i) {
    if (i == index) return;
    setState(() => index = i);
    tabAnim.forward(from: 0);
  }

  @override
  void dispose() {
    tabAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = CurvedAnimation(parent: tabAnim, curve: Curves.easeOutCubic);
    final pages = [
      HomeTab(onTab: _go),
      MyQrScreen(active: index == 1),
      const HistoryScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: FadeTransition(
          opacity: t,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, .025),
              end: Offset.zero,
            ).animate(t),
            child: IndexedStack(index: index, children: pages),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: _go,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_2_rounded),
            selectedIcon: Icon(Icons.qr_code_2_rounded),
            label: 'Pay',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_toggle_off_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// DR-02 Home.
class HomeTab extends StatelessWidget {
  final ValueChanged<int> onTab;
  const HomeTab({super.key, required this.onTab});

  String _greeting() {
    final h = DateTime.now().hour;
    return h < 12
        ? 'Good morning'
        : h < 17
        ? 'Good afternoon'
        : 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final me = app.me;
    final nearest = [...app.branches]
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    final recent = app.myHistory.take(2).toList();
    final card = app.activeCard;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Row(
          children: [
            const UcLogo(size: 42),
            const Spacer(),
            const NotificationBell(),
            const SizedBox(width: 4),
            AccountAvatar(
              initials: me.initials,
              onTap: () => _account(context, app),
            ),
          ],
        ),
        const SizedBox(height: 14),
        InfoCarousel(items: _info(context, app)),
        const SizedBox(height: 22),
        FadeSlideIn(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 3,
                          decoration: BoxDecoration(
                            color: UC.teal,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _greeting().toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.8,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0B8F80),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    GradientText(
                      me.name.split(' ').first,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
                decoration: BoxDecoration(
                  color: UC.success.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PulseDot(size: 6),
                    Text(
                      'Account active',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: UC.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FadeSlideIn(
          index: 1,
          child: _WalletCard(
            balance: me.walletBalance,
            onAdd: () => showMoneySheet(context, MoneyAction.load),
            onWithdraw: () => showMoneySheet(context, MoneyAction.withdraw),
            onOpen: () => _push(context, const WalletScreen()),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Tile(
              Icons.qr_code_2_rounded,
              'My QR',
              0,
              'Show to attendant',
              const Color(0xFF0FB9A5),
              () => onTab(1),
            ),
            _Tile(
              Icons.location_on_outlined,
              'Find stations',
              1,
              'Nearby branches',
              UC.info,
              () => _push(context, const StationsPage()),
            ),
            _Tile(
              Icons.history_rounded,
              'Transactions',
              2,
              'Receipts & payments',
              UC.orange,
              () => onTab(2),
            ),
            _Tile(
              Icons.credit_card_rounded,
              'My card',
              3,
              card == null ? 'No active card' : 'Active •• ${card.last4}',
              UC.purple,
              () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManageCardsScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),
        SectionHeader(
          'Near you',
          'Charging stations',
          action: 'View all',
          onAction: () => _push(context, const StationsPage()),
        ),
        const SizedBox(height: 12),
        FadeSlideIn(index: 3, child: StationCard(nearest.first)),
        const SizedBox(height: 26),
        SectionHeader(
          'Your activity',
          'Recent charging',
          action: 'History',
          onAction: () => onTab(2),
        ),
        const SizedBox(height: 10),
        if (recent.isEmpty)
          const Panel(
            child: EmptyState(
              Icons.bolt_outlined,
              'No charges yet',
              'Show your QR to an attendant to start.',
            ),
          )
        else
          Panel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < recent.length; i++) ...[
                  if (i > 0) const Divider(indent: 16, endIndent: 16),
                  HistoryRow(recent[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }

  void _push(BuildContext context, Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  void _account(BuildContext context, AppState app) {
    final me = app.me;
    final card = app.activeCard;
    showAccountSheet(
      context,
      name: me.name,
      initials: me.initials,
      roleLabel: 'DRIVER',
      details: [
        ('Phone', me.phone),
        ('Vehicle', '${me.plate} · ${me.vehicleType}'),
        ('Wallet', money(me.walletBalance)),
        ('QR card', card == null ? 'None active' : 'Active •• ${card.last4}'),
        ('Reward points', '${app.rewardPoints}'),
      ],
      actions: [
        SheetAction(Icons.person_outline_rounded, 'My profile', () => onTab(3)),
        SheetAction(
          Icons.credit_card_rounded,
          'My cards',
          () => _push(context, const ManageCardsScreen()),
        ),
        SheetAction(
          Icons.card_giftcard_rounded,
          'Rewards',
          () => _push(context, const RewardsScreen()),
        ),
        SheetAction(
          Icons.support_agent_rounded,
          'Help & support',
          () => _push(context, const SupportScreen()),
        ),
      ],
    );
  }

  /// Useful, tappable info for the top of Home.
  List<InfoItem> _info(BuildContext context, AppState app) {
    final me = app.me;
    final open =
        app.branches.where((b) => b.status == BranchStatus.open).toList()
          ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    final offline = app.branches
        .where((b) => b.status == BranchStatus.offline)
        .toList();
    final last = app.myHistory.isEmpty ? null : app.myHistory.first;
    final card = app.activeCard;
    final offer = app.offers
        .where((o) => o.campaignEnabled && app.rewardPoints >= o.points)
        .toList();
    return [
      if (me.walletBalance < 50)
        InfoItem(
          icon: Icons.account_balance_wallet_outlined,
          color: UC.orange,
          title: 'Low balance · ${money(me.walletBalance)}',
          body: 'Top up with Mobile Money before your next charge.',
          action: 'Top up',
          onTap: () => showMoneySheet(context, MoneyAction.load),
        ),
      if (open.isNotEmpty)
        InfoItem(
          icon: Icons.ev_station_rounded,
          color: UC.success,
          title: '${open.first.name} is open · ${open.first.distanceKm} km',
          body:
              '${money(open.first.tariff)}/kWh · staff updated ${ago(open.first.statusUpdated)}',
          action: 'Go',
          onTap: () => _push(context, StationDetailScreen(open.first)),
        ),
      if (last != null)
        InfoItem(
          icon: Icons.receipt_long_rounded,
          color: UC.info,
          title:
              'Last charge · ${(last.kwh ?? 0).toStringAsFixed(1)} kWh · ${money(last.paidAmount)}',
          body:
              '${last.branch.name} · ${ago(last.startedAt)} — tap for receipt',
          onTap: () => _push(context, DriverReceiptScreen(last)),
        ),
      InfoItem(
        icon: Icons.card_giftcard_rounded,
        color: UC.purple,
        title: '${app.rewardPoints} reward points',
        body: offer.isEmpty
            ? 'Earn 1 point for every GH₵ 1 you spend.'
            : '${offer.first.title} is ready to redeem.',
        action: offer.isEmpty ? null : 'Redeem',
        onTap: () => _push(context, const RewardsScreen()),
      ),
      if (card != null)
        InfoItem(
          icon: Icons.credit_card_rounded,
          color: const Color(0xFF0FB9A5),
          title: 'QR card •• ${card.last4} is active',
          body: 'Lost it? Block it instantly so nobody else can use it.',
          onTap: () => _push(context, const ManageCardsScreen()),
        )
      else
        InfoItem(
          icon: Icons.add_card_rounded,
          color: const Color(0xFF0FB9A5),
          title: 'Link your QR card',
          body: 'Pay faster at the branch with a physical card.',
          action: 'Link',
          onTap: () => _push(context, const LinkCardScreen()),
        ),
      for (final b in offline.take(1))
        InfoItem(
          icon: Icons.power_off_rounded,
          color: UC.danger,
          title: '${b.name} reported offline',
          body: 'Updated by staff ${ago(b.statusUpdated)}. Try another branch.',
          onTap: () => _push(context, StationDetailScreen(b)),
        ),
    ];
  }
}

class _WalletCard extends StatelessWidget {
  final double balance;
  final VoidCallback onAdd;
  final VoidCallback onWithdraw;
  final VoidCallback onOpen;
  const _WalletCard({
    required this.balance,
    required this.onAdd,
    required this.onWithdraw,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          gradient: heroGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: UC.navy.withValues(alpha: .28),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const HeroGlow(),
            Positioned(
              right: 16,
              top: 16,
              child: Opacity(
                opacity: .9,
                child: const UcLogo(size: 34, wordmark: false),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available balance',
                    style: TextStyle(color: Colors.white60, fontSize: 12.5),
                  ),
                  const SizedBox(height: 10),
                  CountUp(
                    balance,
                    format: money,
                    duration: const Duration(milliseconds: 1100),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Card balance · tap for activity',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: PressScale(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: UC.teal,
                              foregroundColor: UC.navy,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: onAdd,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add money'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PressScale(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white38),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: onWithdraw,
                            icon: const Icon(
                              Icons.north_east_rounded,
                              size: 18,
                            ),
                            label: const Text('Withdraw'),
                          ),
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
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int index;
  final String sub;
  final Color tint;
  final VoidCallback onTap;
  const _Tile(
    this.icon,
    this.title,
    this.index,
    this.sub,
    this.tint,
    this.onTap,
  );

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FadeSlideIn(
        index: index + 2,
        child: PressScale(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: UC.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: tint.withValues(alpha: .25)),
                      boxShadow: [
                        BoxShadow(
                          color: tint.withValues(alpha: .18),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(icon, size: 22, color: tint),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: UC.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 10.5, color: UC.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Station preview card used on Home and in the station list.
class StationCard extends StatelessWidget {
  final Branch b;
  const StationCard(this.b, {super.key});

  @override
  Widget build(BuildContext context) {
    final info = branchInfo(b.status);
    return Panel(
      padding: const EdgeInsets.all(12),
      onTap: () =>
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => StationDetailScreen(b))),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: MapPainter(focus: b.mapPos, pins: const []),
                child: Center(child: MapPin(color: info.color)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusChip.of(info),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${b.distanceKm} km away',
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: UC.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  b.name,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  b.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: UC.muted),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 15, color: UC.muted),
                    Text(
                      '${money(b.tariff)}/kWh',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Updated ${ago(b.statusUpdated)}',
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, color: UC.faint),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
