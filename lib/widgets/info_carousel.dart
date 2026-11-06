import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'motion.dart';

/// One card in the [InfoCarousel].
class InfoItem {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final String? action;
  final VoidCallback? onTap;
  const InfoItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.action,
    this.onTap,
  });
}

/// Auto-rotating strip of useful, tappable info cards shown at the top of a
/// dashboard (alerts, tips, nearest station, rewards...). Pauses while the
/// user drags it.
class InfoCarousel extends StatefulWidget {
  final List<InfoItem> items;
  final Duration interval;
  const InfoCarousel({
    super.key,
    required this.items,
    this.interval = const Duration(seconds: 4),
  });

  @override
  State<InfoCarousel> createState() => _InfoCarouselState();
}

class _InfoCarouselState extends State<InfoCarousel> {
  final page = PageController(viewportFraction: .93);
  Timer? timer;
  int current = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    timer?.cancel();
    if (widget.items.length < 2) return;
    timer = Timer.periodic(widget.interval, (_) {
      if (!page.hasClients) return;
      final next = (current + 1) % widget.items.length;
      page.animateToPage(
        next,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant InfoCarousel old) {
    super.didUpdateWidget(old);
    if (current >= widget.items.length) current = 0;
    if (old.items.length != widget.items.length) _start();
  }

  @override
  void dispose() {
    timer?.cancel();
    page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    return FadeSlideIn(
      child: Column(
        children: [
          SizedBox(
            height: 84,
            child: NotificationListener<ScrollStartNotification>(
              onNotification: (n) {
                if (n.dragDetails != null) timer?.cancel();
                return false;
              },
              child: NotificationListener<ScrollEndNotification>(
                onNotification: (_) {
                  _start();
                  return false;
                },
                child: PageView.builder(
                  controller: page,
                  padEnds: false,
                  itemCount: items.length,
                  onPageChanged: (i) => setState(() => current = i),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _InfoCard(items[i]),
                  ),
                ),
              ),
            ),
          ),
          if (items.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < items.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == current ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == current ? UC.teal : UC.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final InfoItem item;
  const _InfoCard(this.item);

  @override
  Widget build(BuildContext context) {
    final c = item.color;
    return PressScale(
      enabled: item.onTap != null,
      child: Material(
        color: UC.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.withValues(alpha: .28)),
            gradient: LinearGradient(
              colors: [c.withValues(alpha: .10), UC.surface],
              stops: const [0, .55],
            ),
          ),
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(item.icon, color: c, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: UC.navy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.3,
                            color: UC.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item.action != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: c.withValues(alpha: .14),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item.action!,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: c,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
