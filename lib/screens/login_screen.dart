import 'package:flutter/material.dart';

import '../state.dart';
import '../theme.dart';
import '../widgets/charger_art.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';
import 'driver/signup_screen.dart';
import 'otp_screen.dart';

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
  bool codeMode = false; // sign in with a texted code instead of a password
  String? phoneErr, passErr, authErr;
  bool busy = false;

  Future<void> _submit() async {
    final app = AppScope.read(context);
    setState(() {
      authErr = null;
      phoneErr = !AppState.validId(phone.text)
          ? 'Enter a 10-digit phone number or a valid email'
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
        authErr = 'Phone, email or password is incorrect.';
      });
      return;
    }
    app.signIn(account);
  }

  void _sendCode() {
    setState(() {
      authErr = null;
      phoneErr = !AppState.validId(phone.text)
          ? 'Enter a 10-digit phone number or a valid email'
          : null;
    });
    if (phoneErr != null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpFlowScreen(
          purpose: OtpPurpose.login,
          phone: AppState.normalizeId(phone.text),
        ),
      ),
    );
  }

  void _forgot() {
    final ok = AppState.validId(phone.text);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OtpFlowScreen(
          purpose: OtpPurpose.reset,
          phone: ok ? AppState.normalizeId(phone.text) : null,
        ),
      ),
    );
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
                // ---- Brand hero ----
                FadeSlideIn(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: heroGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: UC.navy.withValues(alpha: UC.dark ? .5 : .22),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        const BrandRings(strength: 1.6),
                        const HeroGlow(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                          child: Column(
                            children: [
                              const Align(
                                alignment: Alignment.centerRight,
                                child: ThemeIconButton(),
                              ),
                              const Bob(child: BrandLogo(height: 92)),
                              const SizedBox(height: 16),
                              const Eyebrow('Welcome back', color: UC.teal),
                              const SizedBox(height: 8),
                              const Text(
                                'Sign in to Ulti Charge',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -.6,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Use your phone number. Your account opens '
                                'the right workspace — sales attendant or '
                                'driver.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.45,
                                  color: Color(0xFFB4C3D9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 26),

                FadeSlideIn(
                  index: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ---- Credentials ----
                      _ModeSwitch(
                        codeMode: codeMode,
                        onChanged: (v) => setState(() {
                          codeMode = v;
                          authErr = phoneErr = passErr = null;
                        }),
                      ),
                      const SizedBox(height: 18),
                      LabeledField(
                        label: 'Phone number or email',
                        hint: '024 000 0000 or you@example.com',
                        icon: Icons.alternate_email_rounded,
                        controller: phone,
                        errorText: phoneErr,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: codeMode
                            ? Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.sms_outlined,
                                      size: 16,
                                      color: UC.tealText,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'We will send a 6-digit code to this phone '
                                        'or email. No password needed.',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          height: 1.4,
                                          color: UC.muted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
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
                                      onTap: () =>
                                          setState(() => showPass = !showPass),
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
                                          onChanged: (v) =>
                                              setState(() => keep = v ?? false),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Keep me signed in',
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: UC.muted,
                                          ),
                                        ),
                                      ),
                                      SmallLink(
                                        'Forgot password?',
                                        bold: true,
                                        onTap: _forgot,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 22),
                    ],
                  ),
                ),
                FadeSlideIn(
                  index: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ---- Actions ----
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: codeMode
                            ? PrimaryButton(
                                'Send code',
                                key: const ValueKey('code'),
                                leading: Icons.send_rounded,
                                trailing: null,
                                onPressed: _sendCode,
                              )
                            : PrimaryButton(
                                'Sign in',
                                key: const ValueKey('pw'),
                                busy: busy,
                                onPressed: _submit,
                              ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'New driver?',
                            style: TextStyle(fontSize: 13, color: UC.muted),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: UC.accent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SignupScreen(),
                              ),
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
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                // ---- Illustration ----
                const FadeSlideIn(
                  index: 6,
                  child: Bob(
                    amplitude: 3,
                    child: ChargerArt(height: 128, withCar: true),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
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

/// Password | SMS code switch with a sliding highlight.
class _ModeSwitch extends StatelessWidget {
  final bool codeMode;
  final ValueChanged<bool> onChanged;
  const _ModeSwitch({required this.codeMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, IconData icon, bool code) {
      final on = codeMode == code;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(code),
          child: Container(
            height: 42,
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 17, color: on ? UC.onAccent : UC.muted),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: on ? UC.onAccent : UC.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: UC.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: UC.line),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: codeMode ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: .5,
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: UC.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Row(
            children: [
              tab('Password', Icons.lock_outline_rounded, false),
              tab('One-time code', Icons.pin_outlined, true),
            ],
          ),
        ],
      ),
    );
  }
}
