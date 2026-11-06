import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'screens/attendant/attendant_shell.dart';
import 'screens/attendant/awaiting_assignment_screen.dart';
import 'screens/attendant/clock_in_screen.dart';
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
      child: MaterialApp(
        title: 'Ulti Charge',
        debugShowCheckedModeBanner: false,
        theme: UC.theme(),
        // Every screen (driver and attendant) renders as a phone app.
        navigatorKey: navigatorKey,
        builder: (context, child) => MobileViewport(
          child: NotificationHost(navigatorKey: navigatorKey, child: child!),
        ),
        home: const LaunchGate(),
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
      color: const Color(0xFFE6EBF2),
      child: Center(
        child: Container(
          width: maxWidth,
          height: double.infinity,
          decoration: const BoxDecoration(
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
        app.branch == null
            ? const AwaitingAssignmentScreen()
            : app.shift.status == ShiftStatus.notStarted
            ? const ClockInScreen()
            : const AttendantShell(),
    };
  }
}
