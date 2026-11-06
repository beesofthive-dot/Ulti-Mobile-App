import 'package:flutter/material.dart';

import '../theme.dart';

/// Green clipart of an EV charging terminal, drawn in code so it scales
/// crisply and needs no image asset. With [withCar] an electric car is
/// plugged in beside the terminal.
class ChargerArt extends StatelessWidget {
  final double height;
  final bool withCar;
  const ChargerArt({super.key, this.height = 200, this.withCar = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _ChargerPainter(withCar: withCar)),
    );
  }
}

class _ChargerPainter extends CustomPainter {
  final bool withCar;
  const _ChargerPainter({required this.withCar});

  static const g1 = Color(0xFF43C46F); // light green
  static const g2 = Color(0xFF23934F); // mid green
  static const g3 = Color(0xFF17673A); // dark green

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / 200; // design units: 200 tall
    final cx = size.width / 2;
    final width = withCar ? 300.0 : 200.0;
    canvas.save();
    canvas.translate(cx - width / 2 * s, 0);
    canvas.scale(s);

    // Backdrop and ground.
    canvas.drawCircle(Offset(width / 2, 104), 86, Paint()..color = UC.limeSoft);
    canvas.drawCircle(
      Offset(width / 2, 104),
      64,
      Paint()..color = UC.lime.withValues(alpha: .18),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(width / 2, 184),
        width: width - 50,
        height: 14,
      ),
      Paint()..color = g3.withValues(alpha: .14),
    );

    // The terminal sits on the right when a car is drawn beside it.
    if (withCar) _car(canvas);
    canvas.save();
    if (withCar) canvas.translate(100, 0);
    _charger(canvas);
    canvas.restore();

    // Floating sparkles.
    _bolt(canvas, const Offset(38, 62), 9, g2);
    _spark(canvas, Offset(width - 40, 44), 5, g1);
    _spark(canvas, const Offset(30, 112), 3.5, UC.lime);
    _spark(canvas, Offset(width - 28, 90), 3, g2);

    canvas.restore();
  }

  /// Side-on electric car facing the terminal, charge port lit.
  void _car(Canvas canvas) {
    const ground = 180.0;
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [g1, g2],
      ).createShader(const Rect.fromLTWH(10, 96, 140, 66));

    // Cabin and window.
    final cabin = Path()
      ..moveTo(36, 130)
      ..cubicTo(44, 106, 56, 96, 74, 96)
      ..lineTo(104, 96)
      ..cubicTo(120, 98, 130, 114, 136, 130)
      ..close();
    canvas.drawPath(cabin, bodyPaint);
    final window = Path()
      ..moveTo(48, 128)
      ..cubicTo(53, 112, 61, 104, 74, 104)
      ..lineTo(102, 104)
      ..cubicTo(113, 106, 120, 116, 124, 128)
      ..close();
    canvas.drawPath(window, Paint()..color = UC.primary);
    canvas.drawRect(const Rect.fromLTWH(84, 104, 3, 24), Paint()..color = g2);

    // Lower body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 126, 140, 36),
        const Radius.circular(12),
      ),
      bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 150, 140, 12),
        const Radius.circular(6),
      ),
      Paint()..color = g3.withValues(alpha: .35),
    );
    // Headlight, tail light, door line.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(142, 134, 8, 6),
        const Radius.circular(3),
      ),
      Paint()..color = UC.lime,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 136, 5, 6),
        const Radius.circular(2),
      ),
      Paint()..color = UC.orange,
    );
    canvas.drawLine(
      const Offset(86, 130),
      const Offset(86, 156),
      Paint()
        ..color = g3.withValues(alpha: .4)
        ..strokeWidth = 1.5,
    );

    // Wheels.
    for (final x in const [42.0, 120.0]) {
      canvas.drawCircle(
        Offset(x, ground - 16),
        16,
        Paint()..color = UC.primary,
      );
      canvas.drawCircle(Offset(x, ground - 16), 8, Paint()..color = g1);
      canvas.drawCircle(Offset(x, ground - 16), 3, Paint()..color = UC.primary);
    }

    // Charge port with glow, and the plug seated in it.
    canvas.drawCircle(
      const Offset(136, 140),
      7,
      Paint()..color = UC.lime.withValues(alpha: .3),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(132, 135, 12, 10),
        const Radius.circular(3),
      ),
      Paint()..color = UC.primary,
    );
    // Cable to the terminal (drawn in terminal space: body starts at x=162).
    final cable = Path()
      ..moveTo(162, 152)
      ..cubicTo(154, 176, 146, 168, 143, 142);
    canvas.drawPath(
      cable,
      Paint()
        ..color = g3
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    _bolt(canvas, const Offset(148, 118), 10, UC.lime);
  }

  void _charger(Canvas canvas) {
    // Sprouts at the base.
    if (!withCar) {
      _leaf(canvas, const Offset(36, 182), -0.5, 16);
      _leaf(canvas, const Offset(42, 182), 0.35, 12);
    }
    _leaf(canvas, const Offset(162, 182), 0.5, 14);
    _leaf(canvas, const Offset(156, 182), -0.3, 10);

    // Cable from base of terminal curling out to the plug (alone only).
    if (!withCar) _holsterCable(canvas);

    _terminal(canvas);
  }

  void _holsterCable(Canvas canvas) {
    final cable = Path()
      ..moveTo(122, 160)
      ..cubicTo(150, 176, 168, 160, 160, 128)
      ..cubicTo(156, 112, 150, 104, 142, 96);
    canvas.drawPath(
      cable,
      Paint()
        ..color = g3
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    // Plug resting in holster on the side.
    final plug = RRect.fromRectAndRadius(
      const Rect.fromLTWH(128, 74, 20, 26),
      const Radius.circular(6),
    );
    canvas.drawRRect(plug, Paint()..color = UC.primary);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(131, 68, 14, 8),
        const Radius.circular(3),
      ),
      Paint()..color = g3,
    );
  }

  void _terminal(Canvas canvas) {
    // Terminal body.
    final body = RRect.fromRectAndCorners(
      const Rect.fromLTWH(62, 30, 66, 140),
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: const Radius.circular(6),
      bottomRight: const Radius.circular(6),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [g1, g2],
        ).createShader(body.outerRect),
    );
    // Side shading strip.
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        const Rect.fromLTWH(114, 30, 14, 140),
        topRight: const Radius.circular(18),
        bottomRight: const Radius.circular(6),
      ),
      Paint()..color = g3.withValues(alpha: .35),
    );
    // Top cap.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(58, 24, 74, 14),
        const Radius.circular(7),
      ),
      Paint()..color = g3,
    );
    // Base plinth.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(54, 166, 82, 14),
        const Radius.circular(5),
      ),
      Paint()..color = g3,
    );

    // Screen.
    final screen = RRect.fromRectAndRadius(
      const Rect.fromLTWH(72, 50, 40, 46),
      const Radius.circular(8),
    );
    canvas.drawRRect(screen, Paint()..color = UC.primary);
    _bolt(canvas, const Offset(92, 66), 13, UC.lime);
    // Charge level bars on screen.
    for (var i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(77 + i * 8.0, 84, 6, 5),
          const Radius.circular(1.5),
        ),
        Paint()..color = i < 3 ? UC.lime : Colors.white24,
      );
    }

    // Status light and socket.
    canvas.drawCircle(const Offset(80, 108), 4, Paint()..color = UC.lime);
    canvas.drawCircle(
      const Offset(80, 108),
      7,
      Paint()..color = UC.lime.withValues(alpha: .25),
    );
    canvas.drawCircle(const Offset(95, 130), 11, Paint()..color = g3);
    canvas.drawCircle(const Offset(95, 130), 7, Paint()..color = UC.primary);
    for (final o in const [Offset(92, 128), Offset(98, 128), Offset(95, 133)]) {
      canvas.drawCircle(o, 1.6, Paint()..color = g1);
    }
  }

  void _bolt(Canvas c, Offset o, double h, Color color) {
    final w = h * .62;
    final p = Path()
      ..moveTo(o.dx + w * .15, o.dy - h / 2)
      ..lineTo(o.dx - w / 2, o.dy + h * .08)
      ..lineTo(o.dx - w * .02, o.dy + h * .08)
      ..lineTo(o.dx - w * .2, o.dy + h / 2)
      ..lineTo(o.dx + w / 2, o.dy - h * .12)
      ..lineTo(o.dx + w * .02, o.dy - h * .12)
      ..close();
    c.drawPath(p, Paint()..color = color);
  }

  void _spark(Canvas c, Offset o, double r, Color color) {
    final p = Path()
      ..moveTo(o.dx, o.dy - r * 2)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + r * 2, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r * 2)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - r * 2, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r * 2)
      ..close();
    c.drawPath(p, Paint()..color = color);
  }

  void _leaf(Canvas c, Offset base, double tilt, double len) {
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(tilt);
    final p = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(len * .5, -len * .5, 0, -len)
      ..quadraticBezierTo(-len * .5, -len * .5, 0, 0)
      ..close();
    c.drawPath(p, Paint()..color = g1.withValues(alpha: .85));
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _ChargerPainter old) => old.withCar != withCar;
}
