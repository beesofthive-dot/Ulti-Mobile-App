import 'package:flutter/material.dart';

import '../../state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// DR-01 Welcome & signup: mobile → OTP → profile → consent.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  int step = 0;
  final phone = TextEditingController();
  final otp = TextEditingController();
  final name = TextEditingController();
  final plate = TextEditingController();
  final password = TextEditingController();
  final email = TextEditingController();
  String type = 'Sedan EV';
  bool consent = false;
  bool marketing = false;
  String? err;
  bool busy = false;

  static const titles = [
    'Enter your mobile number',
    'Verify your number',
    'Your profile',
    'Privacy & consent',
  ];

  Future<void> _next() async {
    final app = AppScope.read(context);
    String? e;
    switch (step) {
      case 0:
        if (phone.text.replaceAll(' ', '').length < 10) {
          e = 'Enter a 10-digit mobile number';
        } else if (app.findDuplicate(phone.text, '') != null) {
          e = 'This number already has an account. Sign in instead.';
        }
      case 1:
        if (otp.text.trim().length != 6) e = 'Enter the 6-digit code';
      case 2:
        if (name.text.trim().length < 3) {
          e = 'Enter your full name';
        } else if (plate.text.trim().length < 4) {
          e = 'Enter your vehicle plate';
        } else if (app.findDuplicate('—', plate.text) != null) {
          e = 'This plate is already registered to another driver.';
        } else if (email.text.trim().isNotEmpty &&
            !AppState.isEmail(email.text)) {
          e = 'Enter a valid email address or leave it blank';
        } else if (email.text.trim().isNotEmpty &&
            app.accountForId(email.text) != null) {
          e = 'This email already has an account. Sign in instead.';
        } else if (password.text.length < 6) {
          e = 'Choose a password of at least 6 characters';
        }
      case 3:
        if (!consent) e = 'Consent is required to create an account';
    }
    setState(() => err = e);
    if (e != null) return;
    if (step < 3) {
      setState(() => busy = true);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() {
        busy = false;
        step++;
      });
      return;
    }
    final a = app.registerDriverAccount(
      name.text.trim(),
      phone.text.trim(),
      plate.text.trim(),
      type,
      password.text,
      email: email.text,
    );
    Navigator.of(context).pop();
    app.signIn(a);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => step == 0
              ? Navigator.of(context).pop()
              : setState(() {
                  step--;
                  err = null;
                }),
        ),
        title: const UcLogo(size: 28),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: i <= step ? UC.accent : UC.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          Eyebrow('Step ${step + 1} of 4'),
          const SizedBox(height: 8),
          Text(
            titles[step],
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 24),
          ...switch (step) {
            0 => [
              LabeledField(
                label: 'Mobile number',
                hint: '024 000 0000',
                icon: Icons.phone_iphone_rounded,
                controller: phone,
                keyboardType: TextInputType.phone,
                helper: 'We will text you a 6-digit code.',
              ),
            ],
            1 => [
              Text(
                'Code sent to ${phone.text}',
                style: TextStyle(color: UC.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: otp,
                maxLength: 6,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  letterSpacing: 14,
                  fontWeight: FontWeight.w800,
                ),
                decoration: const InputDecoration(
                  hintText: '••••••',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    toast(context, 'New code sent', tone: Tone.success),
                child: const Text('Resend code'),
              ),
            ],
            2 => [
              LabeledField(
                label: 'Full name',
                hint: 'Kwame Mensah',
                icon: Icons.person_outline,
                controller: name,
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Vehicle plate',
                hint: 'GR 0000-24',
                icon: Icons.directions_car_outlined,
                controller: plate,
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Email',
                optional: true,
                hint: 'you@example.com',
                icon: Icons.alternate_email_rounded,
                controller: email,
                keyboardType: TextInputType.emailAddress,
                helper: 'Lets you sign in and reset your password by email.',
              ),
              const SizedBox(height: 16),
              LabeledField(
                label: 'Create password',
                hint: 'At least 6 characters',
                icon: Icons.lock_outline_rounded,
                controller: password,
                obscure: true,
                helper: 'You will sign in with your phone number or email and this password.',
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
                  for (final t in const [
                    'Sedan EV',
                    'Hatchback EV',
                    'SUV EV',
                    'Electric motorbike',
                  ])
                    ChoiceChip(
                      label: Text(t),
                      selected: type == t,
                      showCheckmark: false,
                      selectedColor: UC.limeSoft,
                      backgroundColor: UC.surface,
                      side: BorderSide(color: type == t ? UC.accent : UC.line),
                      onSelected: (_) => setState(() => type = t),
                    ),
                ],
              ),
            ],
            _ => [
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      value: consent,
                      onChanged: (v) => setState(() => consent = v ?? false),
                      title: const Text(
                        'I agree to the Terms and Privacy Policy and allow Ulti Charge to store my mobile and vehicle details for charging and receipts.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                    CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      value: marketing,
                      onChanged: (v) => setState(() => marketing = v ?? false),
                      title: const Text(
                        'Send me offers and rewards updates (optional).',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          },
          if (err != null) ...[
            const SizedBox(height: 14),
            InfoBanner(err!, tone: Tone.danger, icon: Icons.error_outline),
          ],
          const SizedBox(height: 28),
          PrimaryButton(
            step == 3 ? 'Create account' : 'Continue',
            busy: busy,
            onPressed: _next,
          ),
        ],
      ),
    );
  }
}
