import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

/// DR-05 My QR — expiring payment token with countdown.
class MyQrScreen extends StatefulWidget {
  final bool active;
  const MyQrScreen({super.key, required this.active});

  @override
  State<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends State<MyQrScreen> {
  static const ttl = 60;
  final _rng = Random.secure();
  late String token;
  int left = ttl;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _regen();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!widget.active) return;
      setState(() {
        left--;
        if (left <= 0) _regen();
      });
    });
  }

  void _regen() {
    token = List.generate(
      12,
      (_) => 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'[_rng.nextInt(31)],
    ).join();
    left = ttl;
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final me = app.me;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        const PageTitle(
          eyebrow: 'Pay',
          title: 'My QR',
          subtitle: 'Show this code to the sales attendant to pay.',
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: heroGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: UC.navy.withValues(alpha: .25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const UcLogo(size: 26, wordmark: false),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          me.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          me.plate,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    money(me.walletBalance),
                    style: const TextStyle(
                      color: UC.lime,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: QrImageView(
                      key: ValueKey(token),
                      data: 'ulticharge:pay:${me.id}:$token',
                      padding: EdgeInsets.zero,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: UC.ink,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: UC.ink,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${token.substring(0, 4)} ${token.substring(4, 8)} ${token.substring(8)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: left / ttl,
                  minHeight: 5,
                  color: left <= 10 ? UC.orange : UC.lime,
                  backgroundColor: Colors.white12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Expires in ${left}s · single use',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GhostButton(
          'Regenerate code',
          icon: Icons.refresh_rounded,
          onPressed: () => setState(_regen),
        ),
        const SizedBox(height: 14),
        const InfoBanner(
          'Codes rotate every minute and can be used once. Never share a screenshot of your code.',
          icon: Icons.shield_outlined,
          tone: Tone.neutral,
        ),
      ],
    );
  }
}
