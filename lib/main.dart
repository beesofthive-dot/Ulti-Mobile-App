import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'screens/attendant/attendant_shell.dart';
import 'screens/attendant/awaiting_assignment_screen.dart';
import 'screens/driver/driver_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'state.dart';
import 'widgets/notification_host.dart';
import 'theme.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(UltiChargeApp(state: AppState()));
}

class UltiChargeApp extends StatelessWidget {
  final AppState state;
  const UltiChargeApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      // Rebuilds the theme when the user flips light / dark mode.
      child: ValueListenableBuilder<bool>(
        valueListenable: UC.darkNotifier,
        builder: (context, dark, _) {
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: dark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: dark ? Brightness.dark : Brightness.light,
              systemNavigationBarColor: UC.surface,
              systemNavigationBarIconBrightness: dark
                  ? Brightness.light
                  : Brightness.dark,
            ),
          );
          return MaterialApp(
            title: 'Ulti Charge',
            debugShowCheckedModeBanner: false,
            theme: UC.theme(),
            // Every screen (driver and attendant) renders as a phone app.
            navigatorKey: navigatorKey,
            builder: (context, child) => MobileViewport(
              child: _SignOutGuard(
                child: NotificationHost(
                  navigatorKey: navigatorKey,
                  child: child!,
                ),
              ),
            ),
            home: const LaunchGate(),
          );
        },
      ),
    );
  }
}

/// Keeps the whole app at phone width. On a phone it fills the screen; on a
/// tablet, desktop or browser window it is a full-height phone-width column
/// in the middle, with no device border.
class MobileViewport extends StatelessWidget {
  final Widget child;
  const MobileViewport({super.key, required this.child});

  static const maxWidth = 430.0;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (mq.size.width <= maxWidth + 40) return child;
    return ColoredBox(
      color: UC.backdrop,
      child: Center(
        child: Container(
          width: maxWidth,
          height: double.infinity,
          decoration: BoxDecoration(
            color: UC.bg,
            boxShadow: [BoxShadow(color: Color(0x1F0E2142), blurRadius: 30)],
          ),
          clipBehavior: Clip.hardEdge,
          child: MediaQuery(
            data: mq.copyWith(size: Size(maxWidth, mq.size.height)),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Shows the logo loading screen once, then hands over to [RootGate].
class LaunchGate extends StatefulWidget {
  const LaunchGate({super.key});

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> {
  bool loading = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: loading
          ? SplashScreen(onDone: () => setState(() => loading = false))
          : const RootGate(),
    );
  }
}

/// Picks the root screen from the signed-in account and shift state.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return switch (app.role) {
      null => const LoginScreen(),
      Role.driver => const DriverShell(),
      Role.attendant =>
        // Off shift the attendant still lands in the app (view-only);
        // starting a shift is done from the Shift tab.
        app.branch == null
            ? const AwaitingAssignmentScreen()
            : const AttendantShell(),
    };
  }
}

/// Whenever the user signs out, drops every screen that was pushed on top, so
/// the next person to sign in on the device never lands in the previous
/// person's half-finished screen (e.g. a payment page).
class _SignOutGuard extends StatefulWidget {
  final Widget child;
  const _SignOutGuard({required this.child});

  @override
  State<_SignOutGuard> createState() => _SignOutGuardState();
}

class _SignOutGuardState extends State<_SignOutGuard> {
  AppState? _app;
  Role? _role;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app?.removeListener(_check);
    _app = AppScope.read(context)..addListener(_check);
    _role = _app!.role;
  }

  void _check() {
    final role = _app!.role;
    if (_role != null && role == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => navigatorKey.currentState?.popUntil((r) => r.isFirst),
      );
    }
    _role = role;
  }

  @override
  void dispose() {
    _app?.removeListener(_check);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
