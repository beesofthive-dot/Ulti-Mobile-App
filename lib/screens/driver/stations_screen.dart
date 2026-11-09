import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'driver_shell.dart';

/// DR-03 Station map / list.
class StationsScreen extends StatefulWidget {
  const StationsScreen({super.key});

  @override
  State<StationsScreen> createState() => _StationsScreenState();
}

class _StationsScreenState extends State<StationsScreen> {
  bool map = false;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final list = [...app.branches]
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        PageHeader(
          eyebrow: 'Near you',
          title: 'Charging stations',
          subtitle:
              '${list.where((b) => b.status == BranchStatus.open).length} open now \u00b7 nearest ${list.first.distanceKm} km away',
          icon: Icons.location_on_rounded,
          bottom: _ViewToggle(
            map: map,
            onChanged: (v) => setState(() => map = v),
          ),
        ),
        const SizedBox(height: 14),
        const InfoBanner(
          'Availability is updated by branch staff. It is not live machine data — check the “updated” time.',
          tone: Tone.neutral,
        ),
        const SizedBox(height: 14),
        if (map) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(UC.radius),
            child: SizedBox(
              height: 340,
              child: LayoutBuilder(
                builder: (context, c) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: MapPainter(
                            focus: const Offset(.5, .5),
                            pins: list.map((b) => b.mapPos).toList(),
                          ),
                        ),
                      ),
                      for (final b in list)
                        Positioned(
                          left: b.mapPos.dx * c.maxWidth - 60,
                          top: b.mapPos.dy * c.maxHeight - 22,
                          width: 120,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StationDetailScreen(b),
                              ),
                            ),
                            child: Column(
                              children: [
                                MapPin(color: branchInfo(b.status).color),
                                const SizedBox(height: 2),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: UC.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x14000000),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    b.name,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        left: c.maxWidth * .5 - 8,
                        top: c.maxHeight * .55 - 8,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: UC.info,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        for (var i = 0; i < list.length; i++)
          FadeSlideIn(
            index: i + 1,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StationCard(list[i]),
            ),
          ),
      ],
    );
  }
}

/// List / Map switch drawn for the dark header.
class _ViewToggle extends StatelessWidget {
  final bool map;
  final ValueChanged<bool> onChanged;
  const _ViewToggle({required this.map, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget seg(bool value, IconData icon, String label) {
      final on = map == value;
      return Expanded(
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            hoverColor: Colors.white.withValues(alpha: .08),
            splashColor: UC.teal.withValues(alpha: .25),
            onTap: () => onChanged(value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: on ? UC.teal : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17, color: on ? UC.navy : Colors.white70),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: on ? UC.navy : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: .1)),
      ),
      child: Row(
        children: [
          seg(false, Icons.view_agenda_outlined, 'List'),
          seg(true, Icons.map_outlined, 'Map'),
        ],
      ),
    );
  }
}

/// DR-03 opened from Home (not a bottom-menu tab).
class StationsPage extends StatelessWidget {
  const StationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 48),
      body: const StationsScreen(),
    );
  }
}

/// DR-04 Station detail.
class StationDetailScreen extends StatelessWidget {
  final Branch b;
  const StationDetailScreen(this.b, {super.key});

  @override
  Widget build(BuildContext context) {
    final info = branchInfo(b.status);
    return Scaffold(
      appBar: AppBar(title: Text(b.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(UC.radius),
            child: SizedBox(
              height: 170,
              child: CustomPaint(
                painter: MapPainter(focus: b.mapPos, pins: const []),
                child: Center(child: MapPin(color: info.color, size: 44)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          StatusPanel(info, b.statusUpdated),
          const SizedBox(height: 6),
          Text(
            '  Status set by branch staff — not machine telemetry.',
            style: TextStyle(fontSize: 11, color: UC.faint),
          ),
          const SizedBox(height: 14),
          Panel(
            child: Column(
              children: [
                KV('Address', b.address),
                KV('Opening hours', b.hours),
                KV('Contact', b.phone),
                KV('Tariff', '${money(b.tariff)} / kWh', strong: true),
                KV('Chargers', b.chargers.map((c) => c.label).join('\n')),
                KV('Distance', '${b.distanceKm} km'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  'Directions',
                  leading: Icons.navigation_outlined,
                  trailing: null,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: b.address));
                    if (context.mounted) {
                      toast(
                        context,
                        'Address copied — paste into your maps app',
                        tone: Tone.success,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GhostButton(
                  'Call branch',
                  icon: Icons.call_outlined,
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: b.phone));
                    if (context.mounted) {
                      toast(context, '${b.phone} copied', tone: Tone.success);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MapPin extends StatelessWidget {
  final Color color;
  final double size;
  const MapPin({super.key, this.color = UC.primary, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: UC.primary,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Icon(Icons.bolt_rounded, color: UC.lime, size: size * .55),
    );
  }
}

/// Stylised, offline street map so the prototype needs no map SDK or key.
class MapPainter extends CustomPainter {
  final Offset focus;
  final List<Offset> pins;
  MapPainter({required this.focus, required this.pins});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEDEFEA),
    );
    final park = Paint()..color = const Color(0xFFDDE8C9);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .62,
          size.height * .3,
          size.width * .3,
          size.height * .22,
        ),
        const Radius.circular(10),
      ),
      park,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * .06,
          size.height * .52,
          size.width * .18,
          size.height * .3,
        ),
        const Radius.circular(10),
      ),
      park,
    );
    final water = Paint()..color = const Color(0xFFD3E3EE);
    final path = Path()
      ..moveTo(0, size.height * .92)
      ..quadraticBezierTo(
        size.width * .5,
        size.height * .82,
        size.width,
        size.height * .95,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, water);

    final minor = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;
    for (var i = 1; i < 6; i++) {
      final x = size.width * i / 6 + (focus.dx - .5) * 12;
      canvas.drawLine(Offset(x, 0), Offset(x - 14, size.height), minor);
      final y = size.height * i / 6 + (focus.dy - .5) * 12;
      canvas.drawLine(Offset(0, y), Offset(size.width, y + 10), minor);
    }
    final major = Paint()
      ..color = const Color(0xFFF7E7B5)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    final road = Path()
      ..moveTo(0, size.height * .3)
      ..cubicTo(
        size.width * .3,
        size.height * .2,
        size.width * .6,
        size.height * .7,
        size.width,
        size.height * .55,
      );
    canvas.drawPath(road, major);
    canvas.drawLine(
      Offset(size.width * .45, 0),
      Offset(size.width * .55, size.height),
      major..strokeWidth = 6,
    );
  }

  @override
  bool shouldRepaint(covariant MapPainter old) =>
      old.focus != focus || old.pins != pins;
}
