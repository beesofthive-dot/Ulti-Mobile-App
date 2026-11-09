import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/otp_flow.dart';
import '../state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/motion.dart';

enum OtpPurpose { login, reset }

/// Sign in with a texted code, or reset a forgotten password.
///
/// Steps: phone number (reset only, or when none was passed) → 6-digit code
/// with a resend countdown → new password (reset only) → done.
class OtpFlowScreen extends StatefulWidget {
  final OtpPurpose purpose;
  final String? phone;
  const OtpFlowScreen({super.key, required this.purpose, this.phone});

  @override
  State<OtpFlowScreen> createState() => _OtpFlowScreenState();
}

enum _Step { phone, code, password, done }

class _OtpFlowScreenState extends State<OtpFlowScreen>
    with SingleTickerProviderStateMixin {
  late _Step step;
  final phoneCtl = TextEditingController();
  final codeCtl = TextEditingController();
  final passCtl = TextEditingController();
  final pass2Ctl = TextEditingController();
  final codeFocus = FocusNode();
  late final AnimationController shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );
  Timer? tick;
  String phone = '';
  String? error;
  bool busy = false;
  bool showPass = false;
  int secondsLeft = 0;

  bool get isReset => widget.purpose == OtpPurpose.reset;

  @override
  void initState() {
    super.initState();
    phoneCtl.text = widget.phone ?? '';
    step = _Step.phone;
    // Sign-in arrives with the number already typed: go straight to sending.
    if (widget.phone != null && !isReset) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
    }
  }

  @override
  void dispose() {
    tick?.cancel();
    shake.dispose();
    phoneCtl.dispose();
    codeCtl.dispose();
    passCtl.dispose();
    pass2Ctl.dispose();
    codeFocus.dispose();
    super.dispose();
  }

  void _startTicker(AppState app) {
    tick?.cancel();
    void update() {
      final at = app.otpResendAt(phone);
      final left = at == null
          ? 0
          : at.difference(DateTime.now()).inSeconds.clamp(0, 999) +
                (at.isAfter(DateTime.now()) &&
                        at.difference(DateTime.now()).inMilliseconds % 1000 > 0
                    ? 1
                    : 0);
      if (mounted && left != secondsLeft) setState(() => secondsLeft = left);
    }

    update();
    tick = Timer.periodic(const Duration(milliseconds: 500), (_) => update());
  }

  Future<void> _sendCode({bool resend = false}) async {
    final app = AppScope.read(context);
    final p = AppState.normalizeId(phoneCtl.text);
    if (!AppState.validId(phoneCtl.text)) {
      setState(() => error = 'Enter a 10-digit phone number or a valid email');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    final sent = app.sendOtp(p);
    setState(() {
      busy = false;
      phone = p;
      if (!sent) {
        error = 'Please wait before asking for another code.';
        return;
      }
      step = _Step.code;
      codeCtl.clear();
    });
    _startTicker(app);
    if (resend) toast(context, 'A new code has been sent to $p.');
    Future<void>.delayed(
      const Duration(milliseconds: 350),
      () => mounted ? codeFocus.requestFocus() : null,
    );
  }

  void _verify() {
    final app = AppScope.read(context);
    final r = app.verifyOtp(phone, codeCtl.text);
    if (r.error != null) {
      setState(() => error = r.error);
      codeCtl.clear();
      shake.forward(from: 0);
      HapticFeedback.mediumImpact();
      codeFocus.requestFocus();
      return;
    }
    tick?.cancel();
    if (isReset) {
      setState(() {
        error = null;
        step = _Step.password;
      });
      return;
    }
    final account = r.account;
    if (account == null) {
      setState(() => error = 'No account found for that number.');
      return;
    }
    app.signIn(account, viaCode: true);
    // The app root swaps to the right workspace; drop the sign-in routes.
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  void _savePassword() {
    final app = AppScope.read(context);
    final a = passCtl.text.trim(), b = pass2Ctl.text.trim();
    String? e;
    if (a.length < 6) {
      e = 'Choose a password of at least 6 characters';
    } else if (a != b) {
      e = 'The two passwords do not match';
    }
    if (e != null) {
      setState(() => error = e);
      return;
    }
    if (!app.resetPassword(phone, a)) {
      setState(() => error = 'Could not update the password. Try again.');
      return;
    }
    setState(() {
      error = null;
      step = _Step.done;
    });
  }

  String get _title => switch (step) {
    _Step.phone => isReset ? 'Reset your password' : 'Sign in with a code',
    _Step.code => 'Enter your code',
    _Step.password => 'Create a new password',
    _Step.done => 'Password updated',
  };

  String get _subtitle => switch (step) {
    _Step.phone =>
      isReset
          ? 'Enter the phone number or email on your account and we will '
                'send you a code to confirm it is you.'
          : 'No password needed. We will send a 6-digit code to your phone '
                'or email.',
    _Step.code => 'We sent a 6-digit code to $phone.',
    _Step.password => 'Choose something you have not used before.',
    _Step.done => 'You can now sign in with your new password.',
  };

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              children: [
                FadeSlideIn(
                  child: Center(
                    child: Bob(
                      amplitude: 4,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          gradient: heroGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: UC.navy.withValues(alpha: .25),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            switch (step) {
                              _Step.phone => Icons.mark_email_unread_outlined,
                              _Step.code => Icons.pin_outlined,
                              _Step.password => Icons.lock_reset_rounded,
                              _Step.done => Icons.check_circle_rounded,
                            },
                            key: ValueKey(step),
                            color: UC.teal,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  child: Column(
                    key: ValueKey(step),
                    children: [
                      Text(
                        _title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.5,
                          color: UC.title,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: UC.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: FadeSlideIn(
                      key: ValueKey(error),
                      offset: 8,
                      child: InfoBanner(
                        error!,
                        tone: Tone.danger,
                        icon: Icons.error_outline_rounded,
                      ),
                    ),
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOutCubic,
                  transitionBuilder: (c, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(.08, 0),
                        end: Offset.zero,
                      ).animate(a),
                      child: c,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(step),
                    child: switch (step) {
                      _Step.phone => _phoneStep(),
                      _Step.code => _codeStep(app),
                      _Step.password => _passwordStep(),
                      _Step.done => _doneStep(),
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---- steps ----

  Widget _phoneStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LabeledField(
        label: 'Phone number or email',
        hint: '024 000 0000 or you@example.com',
        icon: Icons.alternate_email_rounded,
        controller: phoneCtl,
        keyboardType: TextInputType.emailAddress,
      ),
      const SizedBox(height: 20),
      PrimaryButton(
        'Send code',
        leading: Icons.send_rounded,
        trailing: null,
        busy: busy,
        onPressed: _sendCode,
      ),
    ],
  );

  Widget _codeStep(AppState app) {
    final sms = app.demoSmsCode(phone);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedBuilder(
          animation: shake,
          builder: (_, child) => Transform.translate(
            offset: Offset(
              math.sin(shake.value * math.pi * 6) * 10 * (1 - shake.value),
              0,
            ),
            child: child,
          ),
          child: _CodeBoxes(
            controller: codeCtl,
            focus: codeFocus,
            hasError: error != null,
            onChanged: (v) {
              if (error != null) setState(() => error = null);
              if (v.length == OtpFlow.otpLength) _verify();
            },
          ),
        ),
        const SizedBox(height: 18),
        _SmsBubble(
          code: sms,
          email: phone.contains('@'),
          onTap: sms == null ? null : _fill,
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          isReset ? 'Verify code' : 'Verify and sign in',
          trailing: null,
          onPressed: codeCtl.text.length == OtpFlow.otpLength ? _verify : null,
        ),
        const SizedBox(height: 14),
        Center(
          child: secondsLeft > 0
              ? Text.rich(
                  TextSpan(
                    text: 'Resend code in ',
                    style: TextStyle(fontSize: 13, color: UC.muted),
                    children: [
                      TextSpan(
                        text: '0:${secondsLeft.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: UC.ink,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                )
              : SmallLink(
                  busy ? 'Sending…' : "Didn't get it? Resend code",
                  icon: Icons.refresh_rounded,
                  bold: true,
                  onTap: busy ? () {} : () => _sendCode(resend: true),
                ),
        ),
        Center(
          child: SmallLink(
            'Use a different number',
            onTap: () => setState(() {
              tick?.cancel();
              error = null;
              step = _Step.phone;
            }),
          ),
        ),
      ],
    );
  }

  void _fill() {
    final c = AppScope.read(context).demoSmsCode(phone);
    if (c == null) return;
    codeCtl.text = c;
    setState(() {});
    _verify();
  }

  Widget _passwordStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LabeledField(
        label: 'New password',
        hint: 'At least 6 characters',
        icon: Icons.lock_outline_rounded,
        controller: passCtl,
        obscure: !showPass,
        labelTrailing: SmallLink(
          showPass ? 'Hide' : 'Show',
          icon: showPass
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          onTap: () => setState(() => showPass = !showPass),
        ),
      ),
      const SizedBox(height: 16),
      LabeledField(
        label: 'Confirm password',
        hint: 'Type it again',
        icon: Icons.lock_outline_rounded,
        controller: pass2Ctl,
        obscure: !showPass,
      ),
      const SizedBox(height: 22),
      PrimaryButton('Save password', trailing: null, onPressed: _savePassword),
    ],
  );

  Widget _doneStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.elasticOut,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Icon(Icons.check_circle_rounded, size: 84, color: UC.success),
      ),
      const SizedBox(height: 26),
      PrimaryButton(
        'Back to sign in',
        trailing: null,
        onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
    ],
  );
}

/// Six digit boxes driven by one invisible text field, so paste, the number
/// pad and one-time-code autofill all work.
class _CodeBoxes extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final bool hasError;
  final ValueChanged<String> onChanged;
  const _CodeBoxes({
    required this.controller,
    required this.focus,
    required this.hasError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: focus.requestFocus,
      child: Stack(
        children: [
          ListenableBuilder(
            listenable: Listenable.merge([controller, focus]),
            builder: (context, _) {
              final text = controller.text;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < OtpFlow.otpLength; i++)
                    _Box(
                      digit: i < text.length ? text[i] : '',
                      active: focus.hasFocus && i == text.length,
                      error: hasError,
                    ),
                ],
              );
            },
          ),
          // The real field: invisible but focusable and pasteable.
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focus,
                autofocus: true,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(OtpFlow.otpLength),
                ],
                onChanged: onChanged,
                showCursor: false,
                enableInteractiveSelection: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final String digit;
  final bool active;
  final bool error;
  const _Box({required this.digit, required this.active, required this.error});

  @override
  Widget build(BuildContext context) {
    final filled = digit.isNotEmpty;
    final border = error
        ? UC.danger
        : active
        ? UC.accent
        : filled
        ? UC.accent.withValues(alpha: .5)
        : UC.line;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 46,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: UC.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: active ? 2 : 1.2),
        boxShadow: [
          if (active)
            BoxShadow(color: UC.teal.withValues(alpha: .28), blurRadius: 12),
        ],
      ),
      child: AnimatedScale(
        scale: filled ? 1 : .4,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        child: AnimatedOpacity(
          opacity: filled ? 1 : 0,
          duration: const Duration(milliseconds: 120),
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: UC.title,
            ),
          ),
        ),
      ),
    );
  }
}

/// Simulated text or email showing the code (no SMS/email gateway yet).
class _SmsBubble extends StatelessWidget {
  final String? code;
  final bool email;
  final VoidCallback? onTap;
  const _SmsBubble({
    required this.code,
    required this.email,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      transitionBuilder: (c, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, -.25),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
          child: c,
        ),
      ),
      child: code == null
          ? const SizedBox(key: ValueKey('nosms'), width: double.infinity)
          : Panel(
              key: ValueKey(code),
              onTap: onTap,
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconTile(
                    email ? Icons.mark_email_read_rounded : Icons.sms_rounded,
                    UC.info,
                    size: 38,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Ulti Charge',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: UC.ink,
                              ),
                            ),
                            const Spacer(),
                            const StatusChip(
                              'DEMO SMS',
                              UC.warning,
                              dot: false,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your Ulti Charge code is ${code!.substring(0, 3)} '
                          '${code!.substring(3)}. It expires in 5 minutes. '
                          'Never share it.',
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: UC.muted,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap to fill the code',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: UC.tealText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
