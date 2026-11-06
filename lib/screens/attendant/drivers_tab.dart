import 'package:flutter/material.dart';

import '../../models.dart';
import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/motion.dart';

/// AT-04 Find / register driver.
class DriversTab extends StatefulWidget {
  final ValueChanged<Driver> onStartCharge;
  const DriversTab({super.key, required this.onStartCharge});

  @override
  State<DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends State<DriversTab> {
  final q = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final results = app.searchDrivers(q.text);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        PageHeader(
          eyebrow: 'Drivers',
          title: 'Find a driver',
          subtitle:
              'Search by phone, card, ID or plate — or register someone new.',
          icon: Icons.person_search_rounded,
          bottom: Text(
            '${app.drivers.length} registered drivers',
            style: const TextStyle(
              color: UC.teal,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: q,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Phone, card ID, driver ID or plate',
            prefixIcon: const Icon(Icons.search_rounded, color: UC.faint),
            suffixIcon: IconButton(
              tooltip: 'Scan driver QR',
              icon: const Icon(Icons.qr_code_scanner_rounded, color: UC.muted),
              onPressed: () => toast(
                context,
                'Camera scanning connects here — type the card ID for now',
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        GhostButton(
          'Register new driver',
          icon: Icons.person_add_alt_1_outlined,
          onPressed: () async {
            final d = await Navigator.of(context).push<Driver>(
              MaterialPageRoute(
                builder: (_) => RegisterDriverScreen(prefill: q.text),
              ),
            );
            if (d != null) widget.onStartCharge(d);
          },
        ),
        const SizedBox(height: 18),
        Text(
          '${results.length} result${results.length == 1 ? '' : 's'}',
          style: const TextStyle(fontSize: 12, color: UC.muted),
        ),
        const SizedBox(height: 8),
        if (results.isEmpty)
          const Panel(
            child: EmptyState(
              Icons.person_search_outlined,
              'No driver found',
              'Check the number or register the driver.',
            ),
          ),
        for (final d in results)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: UC.limeSoft,
                    child: Text(
                      d.initials,
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
                          d.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${d.phone} · ${d.plate}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: UC.muted,
                          ),
                        ),
                        Text(
                          '${d.vehicleType} · ${d.cardId ?? 'No card'}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: UC.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: UC.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => widget.onStartCharge(d),
                    child: const Text('Charge'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class RegisterDriverScreen extends StatefulWidget {
  final String prefill;
  const RegisterDriverScreen({super.key, this.prefill = ''});

  @override
  State<RegisterDriverScreen> createState() => _RegisterDriverScreenState();
}

class _RegisterDriverScreenState extends State<RegisterDriverScreen> {
  final name = TextEditingController();
  late final phone = TextEditingController(
    text: RegExp(r'^[\d ]+$').hasMatch(widget.prefill) ? widget.prefill : '',
  );
  final plate = TextEditingController();
  String type = 'Sedan EV';
  bool consent = false;
  String? nameErr, phoneErr, plateErr;
  Driver? duplicate;

  static const types = [
    'Sedan EV',
    'Hatchback EV',
    'SUV EV',
    'Electric motorbike',
    'Electric tricycle',
    'Commercial EV',
  ];

  void _save() {
    final app = AppScope.read(context);
    setState(() {
      nameErr = name.text.trim().length < 3 ? 'Enter full name' : null;
      phoneErr = phone.text.replaceAll(' ', '').length < 10
          ? 'Enter a 10-digit mobile number'
          : null;
      plateErr = plate.text.trim().length < 4 ? 'Enter vehicle plate' : null;
      duplicate = (phoneErr == null && plateErr == null)
          ? app.findDuplicate(phone.text, plate.text)
          : null;
    });
    if (nameErr != null ||
        phoneErr != null ||
        plateErr != null ||
        duplicate != null ||
        !consent) {
      return;
    }
    final d = app.registerDriver(
      name.text.trim(),
      phone.text.trim(),
      plate.text.trim(),
      type,
    );
    toast(context, '${d.name} registered', tone: Tone.success);
    Navigator.of(context).pop(d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register driver')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          LabeledField(
            label: 'Full name',
            hint: 'As on ID',
            icon: Icons.person_outline,
            controller: name,
            errorText: nameErr,
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Mobile number',
            hint: '024 000 0000',
            icon: Icons.phone_iphone_rounded,
            controller: phone,
            errorText: phoneErr,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          LabeledField(
            label: 'Vehicle plate',
            hint: 'GR 0000-24',
            icon: Icons.directions_car_outlined,
            controller: plate,
            errorText: plateErr,
          ),
          const SizedBox(height: 16),
          const Text(
            'Vehicle type',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in types)
                ChoiceChip(
                  label: Text(t),
                  selected: type == t,
                  showCheckmark: false,
                  selectedColor: UC.limeSoft,
                  backgroundColor: UC.surface,
                  side: BorderSide(color: type == t ? UC.primary : UC.line),
                  labelStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => setState(() => type = t),
                ),
            ],
          ),
          if (duplicate != null) ...[
            const SizedBox(height: 16),
            InfoBanner(
              'Possible duplicate: ${duplicate!.name} (${duplicate!.phone}, ${duplicate!.plate}) is already registered.',
              tone: Tone.danger,
              icon: Icons.content_copy_rounded,
              action: TextButton(
                onPressed: () => Navigator.of(context).pop(duplicate),
                child: const Text('Use'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            value: consent,
            onChanged: (v) => setState(() => consent = v ?? false),
            title: const Text(
              'Driver consents to Ulti Charge storing their name, mobile and vehicle details for charging and receipts.',
              style: TextStyle(fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            'Register & continue',
            onPressed: consent ? _save : null,
          ),
        ],
      ),
    );
  }
}
