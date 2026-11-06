import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';
import 'active_session_screen.dart';

/// AT-05 Start charge.
class StartChargeTab extends StatefulWidget {
  final Driver? preselected;
  final VoidCallback onPickDriver;
  const StartChargeTab({
    super.key,
    this.preselected,
    required this.onPickDriver,
  });

  @override
  State<StartChargeTab> createState() => _StartChargeTabState();
}

class _StartChargeTabState extends State<StartChargeTab> {
  Driver? driver;
  Charger? charger;
  final reading = TextEditingController();
  bool overrideConnector = false;

  @override
  void initState() {
    super.initState();
    driver = widget.preselected;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final b = app.branch!;
    charger ??= app.shift.charger ?? b.chargers.first;
    final busy = app.activeOn(charger!);
    final blocked = busy != null && !overrideConnector;
    final canStart = driver != null && !blocked;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              PageHeader(
                eyebrow: 'New session · ${b.name}',
                title: 'Start charge',
                subtitle: 'Pick the driver and connector. START records the time only.',
                icon: Icons.ev_station_rounded,
              ),
              const SizedBox(height: 18),
              const Text(
                'Driver',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Panel(
                padding: const EdgeInsets.all(14),
                onTap: widget.onPickDriver,
                child: driver == null
                    ? const Row(
                        children: [
                          IconTile(
                            Icons.person_search_outlined,
                            UC.muted,
                            size: 38,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Search by phone, card or ID',
                              style: TextStyle(color: UC.muted),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: UC.muted),
                        ],
                      )
                    : Row(
                        children: [
                          CircleAvatar(
                            radius: 19,
                            backgroundColor: UC.limeSoft,
                            child: Text(
                              driver!.initials,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: UC.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${driver!.phone} · ${driver!.id}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: UC.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Change',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Vehicle registration',
                hint: 'Select a driver first',
                icon: Icons.directions_car_outlined,
                readOnly: true,
                controller: TextEditingController(
                  text: driver == null
                      ? ''
                      : '${driver!.plate} · ${driver!.vehicleType}',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Charger / connector',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in b.chargers)
                    ChoiceChip(
                      label: Text(c.label),
                      selected: charger == c,
                      showCheckmark: false,
                      selectedColor: UC.limeSoft,
                      backgroundColor: UC.surface,
                      side: BorderSide(
                        color: charger == c ? UC.primary : UC.line,
                      ),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                      avatar: app.activeOn(c) != null
                          ? const Icon(Icons.circle, size: 9, color: UC.info)
                          : null,
                      onSelected: (_) => setState(() {
                        charger = c;
                        overrideConnector = false;
                      }),
                    ),
                ],
              ),
              if (busy != null) ...[
                const SizedBox(height: 10),
                InfoBanner(
                  'Connector ${charger!.id} already has an active session (${busy.id}, ${busy.driver.name}). Only one active session per connector is allowed.',
                  tone: Tone.warning,
                  icon: Icons.warning_amber_rounded,
                ),
                CheckboxListTile(
                  controlAffinity: ListTileControlAffinity.leading,
                  value: overrideConnector,
                  onChanged: (v) =>
                      setState(() => overrideConnector = v ?? false),
                  title: const Text(
                    'Override — supervisor authorised',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Panel(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    KV('Tariff', '${money(b.tariff)} / kWh', strong: true),
                    KV('Branch', b.name),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Starting reading',
                optional: true,
                hint: 'Charger display kWh',
                icon: Icons.speed_rounded,
                suffixText: 'kWh',
                controller: reading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              const InfoBanner(
                'Charging machine is operated separately. START only records a software timestamp — it does not switch on the charger.',
              ),
              if (!app.online) ...[
                const SizedBox(height: 10),
                const InfoBanner(
                  'Offline — this session will be saved on the device as UNSYNCED.',
                  tone: Tone.warning,
                  icon: Icons.cloud_off_rounded,
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          decoration: const BoxDecoration(
            color: UC.bg,
            border: Border(top: BorderSide(color: UC.line)),
          ),
          child: PrimaryButton(
            'START CHARGE',
            leading: Icons.play_arrow_rounded,
            trailing: null,
            height: 58,
            onPressed: canStart
                ? () {
                    final s = app.startSession(
                      driver: driver!,
                      charger: charger!,
                      startReading: double.tryParse(reading.text.trim()),
                      override: busy != null && overrideConnector,
                    );
                    setState(() {
                      driver = null;
                      reading.clear();
                      overrideConnector = false;
                    });
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ActiveSessionScreen(s)),
                    );
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
