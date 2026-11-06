import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Fades and slides its child up into place. [index] staggers lists.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int index;
  final double offset;
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 18,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> t = CurvedAnimation(
    parent: c,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 60 * math.min(widget.index, 10));
    if (delay == Duration.zero) {
      c.forward();
    } else {
      _start = Timer(delay, c.forward);
    }
  }

  Timer? _start;

  @override
  void dispose() {
    _start?.cancel();
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: t.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - t.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Animates a number from its previous value to [value].
class CountUp extends StatelessWidget {
  final double value;
  final String Function(double) format;
  final TextStyle? style;
  final Duration duration;
  const CountUp(
    this.value, {
    super.key,
    required this.format,
    this.style,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(format(v), style: style),
    );
  }
}

/// Shrinks slightly while pressed, for tactile cards and tiles.
class PressScale extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const PressScale({super.key, required this.child, this.enabled = true});

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool down = false;

  void _set(bool v) {
    if (widget.enabled && down != v) setState(() => down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: down ? .97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// A status dot with a soft repeating ripple.
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulseDot({super.key, this.color = UC.success, this.size = 7});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return SizedBox(
      width: s * 2.4,
      height: s * 2.4,
      child: AnimatedBuilder(
        animation: c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: s + s * 1.4 * c.value,
              height: s + s * 1.4 * c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: .35 * (1 - c.value)),
              ),
            ),
            Container(
              width: s,
              height: s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text painted with the brand navy → teal gradient.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  const GradientText(this.text, {super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (r) => const LinearGradient(
        colors: [UC.navy, Color(0xFF1B5E8C), Color(0xFF0FB9A5)],
        stops: [0, .55, 1],
      ).createShader(r),
      child: Text(text, style: style),
    );
  }
}

/// Brand gradient used by hero cards and headers.
const heroGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF0E2142), Color(0xFF16345F), Color(0xFF0F4C6B)],
  stops: [0, .6, 1],
);

/// Soft teal / green glow circles drawn behind hero content.
class HeroGlow extends StatelessWidget {
  const HeroGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -50,
              child: _circle(150, UC.teal.withValues(alpha: .16)),
            ),
            Positioned(
              right: 50,
              bottom: -70,
              child: _circle(130, UC.brandGreen.withValues(alpha: .14)),
            ),
            Positioned(
              left: -30,
              bottom: -40,
              child: _circle(90, Colors.white.withValues(alpha: .04)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(double d, Color c) => Container(
    width: d,
    height: d,
    decoration: BoxDecoration(shape: BoxShape.circle, color: c),
  );
}

/// Gently bobbing icon used as a decoration in headers.
class FloatingIcon extends StatefulWidget {
  final IconData icon;
  final double size;
  final Color color;
  const FloatingIcon(
    this.icon, {
    super.key,
    this.size = 26,
    this.color = UC.teal,
  });

  @override
  State<FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<FloatingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -4 + 8 * Curves.easeInOut.transform(c.value)),
        child: child,
      ),
      child: Container(
        width: widget.size * 1.9,
        height: widget.size * 1.9,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(widget.size * .6),
          border: Border.all(color: Colors.white.withValues(alpha: .14)),
        ),
        child: Icon(widget.icon, size: widget.size, color: widget.color),
      ),
    );
  }
}

/// Page heading for every main tab: gradient card, eyebrow, title,
/// subtitle, a floating icon and an optional trailing / bottom widget.
class PageHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final Widget? bottom;
  const PageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.icon = Icons.bolt_rounded,
    this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: Container(
        decoration: BoxDecoration(
          gradient: heroGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: UC.navy.withValues(alpha: .22),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            const HeroGlow(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                    eyebrow.toUpperCase(),
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 1.8,
                                      fontWeight: FontWeight.w700,
                                      color: UC.teal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 25,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.5,
                                color: Colors.white,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                subtitle!,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.4,
                                  color: Colors.white.withValues(alpha: .68),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      trailing ?? FloatingIcon(icon),
                    ],
                  ),
                  if (bottom != null) ...[const SizedBox(height: 16), bottom!],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Light heading for pages whose main card is already dark: teal accent,
/// eyebrow, gradient title and subtitle.
class PageTitle extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  const PageTitle({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
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
              Text(
                eyebrow.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0B8F80),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          GradientText(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -.6,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(fontSize: 13, color: UC.muted),
            ),
          ],
        ],
      ),
    );
  }
}
