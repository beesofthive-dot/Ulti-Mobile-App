import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets/charger_art.dart';
import '../widgets/common.dart';
import 'driver/signup_screen.dart';

/// AT-01 / driver sign-in. One login: the account behind the phone number
/// decides whether the attendant or driver workspace opens.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phone = TextEditingController();
  final pass = TextEditingController();
  bool showPass = false;
  bool keep = true;
  String? phoneErr, passErr, authErr;
  bool busy = false;

  Future<void> _submit() async {
    final app = AppScope.read(context);
    setState(() {
      authErr = null;
      phoneErr = AppState.localPhone(phone.text).length != 10
          ? 'Enter your 10-digit phone number'
          : null;
      passErr = pass.text.trim().isEmpty ? 'Enter your password' : null;
    });
    if (phoneErr != null || passErr != null) return;
    setState(() => busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final account = app.authenticate(phone.text, pass.text);
    if (account == null) {
      setState(() {
        busy = false;
        authErr = 'Phone number or password is incorrect.';
      });
      return;
    }
    app.signIn(account);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            // Fills a phone edge to edge; stays readable on wide screens.
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              children: [
                // ---- Logo + heading ----
                const Center(child: BrandLogo(height: 104)),
                const SizedBox(height: 22),
                const Center(child: Eyebrow('Welcome back')),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to Ulti Charge',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: UC.navy,
                    letterSpacing: -.6,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Use your phone number. Your account opens the right '
                  'workspace — sales attendant or driver.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, height: 1.45, color: UC.muted),
                ),
                const SizedBox(height: 26),

                // ---- Credentials ----
                LabeledField(
                  label: 'Phone number',
                  hint: '024 000 0000',
                  icon: Icons.phone_iphone_rounded,
                  controller: phone,
                  errorText: phoneErr,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                LabeledField(
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  controller: pass,
                  obscure: !showPass,
                  errorText: passErr,
                  labelTrailing: SmallLink(
                    showPass ? 'Hide' : 'Show',
                    icon: showPass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onTap: () => setState(() => showPass = !showPass),
                  ),
                ),
                if (authErr != null) ...[
                  const SizedBox(height: 14),
                  InfoBanner(
                    authErr!,
                    tone: Tone.danger,
                    icon: Icons.error_outline_rounded,
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: keep,
                        onChanged: (v) => setState(() => keep = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Keep me signed in',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.5, color: UC.muted),
                      ),
                    ),
                    SmallLink(
                      'Forgot password?',
                      bold: true,
                      onTap: () => toast(
                        context,
                        'A reset code will be sent to your phone number.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // ---- Actions ----
                PrimaryButton('Sign in', busy: busy, onPressed: _submit),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      'New driver?',
                      style: TextStyle(fontSize: 13, color: UC.muted),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: UC.navy,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                      ),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      ),
                      child: const Text(
                        'Create an account',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ---- Illustration ----
                const ChargerArt(height: 128, withCar: true),
                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    'Secure access  ·  Privacy protected',
                    style: TextStyle(fontSize: 11, color: UC.faint),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
