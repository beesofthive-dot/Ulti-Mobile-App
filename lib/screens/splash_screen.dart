import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

/// Landing / loading screen: the main logo pops in, the tagline fades up,
/// and a teal bar fills while the app gets ready.
class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;
  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  late final logoScale = Tween(begin: .72, end: 1.0).animate(
    CurvedAnimation(
      parent: c,
      curve: const Interval(0, .45, curve: Curves.easeOutBack),
    ),
  );
  late final logoFade = CurvedAnimation(
    parent: c,
    curve: const Interval(0, .3, curve: Curves.easeOut),
  );
  late final tagFade = CurvedAnimation(
    parent: c,
    curve: const Interval(.4, .65, curve: Curves.easeOut),
  );
  late final progress = CurvedAnimation(
    parent: c,
    curve: const Interval(.35, 1, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    c.forward().whenComplete(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UC.surface,
      body: Stack(
        children: [
          const BrandRings(),
          SafeArea(
            child: AnimatedBuilder(
              animation: c,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(width: double.infinity),
                  const Spacer(flex: 3),
                  Opacity(
                    opacity: logoFade.value,
                    child: Transform.scale(
                      scale: logoScale.value,
                      child: const BrandLogo(height: 150),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Opacity(
                    opacity: tagFade.value,
                    child: Transform.translate(
                      offset: Offset(0, 10 * (1 - tagFade.value)),
                      child: Column(
                        children: [
                          Text(
                            'Ulti Charge',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: UC.title,
                              letterSpacing: -.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Your Power, Partner...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.2,
                              color: UC.brandGreen.withValues(alpha: .95),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.value,
                        minHeight: 4,
                        color: UC.teal,
                        backgroundColor: UC.line,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Loading…',
                    style: TextStyle(fontSize: 12, color: UC.muted),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
