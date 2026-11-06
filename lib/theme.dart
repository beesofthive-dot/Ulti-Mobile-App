import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Design tokens taken from the Ulti Charge mockups: off-white canvas,
/// deep green-charcoal for primary actions and the wallet card, lime accent.
class UC {
  // Brand colours sampled from the Ulti Charge logo.
  static const navy = Color(0xFF0E2142);
  static const teal = Color(0xFF12E8CF);
  static const brandGreen = Color(0xFF96C949);
  static const bolt = Color(0xFF66FAE9);

  static const bg = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const ink = Color(0xFF0E1A2E);
  static const muted = Color(0xFF6E7A8C);
  static const faint = Color(0xFFA5AFBD);
  static const line = Color(0xFFE2E7EE);
  static const primary = navy;
  static const primarySoft = Color(0xFF1A3159);
  // Accent used on dark surfaces (buttons, highlights): logo teal.
  static const lime = teal;
  static const limeSoft = Color(0xFFE0FAF6);
  static const success = Color(0xFF2E9E5B);
  static const warning = Color(0xFFD48A06);
  static const danger = Color(0xFFD14343);
  static const info = Color(0xFF3B7BE6);
  static const purple = Color(0xFF7C5CD6);
  static const orange = Color(0xFFE8833A);

  static const radius = 14.0;

  static ThemeData theme() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: lime,
        surface: surface,
        error: danger,
      ),
      scaffoldBackgroundColor: bg,
    );
    final text = base.textTheme.apply(bodyColor: ink, displayColor: ink);
    return base.copyWith(
      textTheme: text,
      // One soft teal feedback style for hover, press and keyboard focus.
      hoverColor: teal.withValues(alpha: .07),
      highlightColor: teal.withValues(alpha: .06),
      splashColor: teal.withValues(alpha: .14),
      focusColor: teal.withValues(alpha: .12),
      splashFactory: InkRipple.splashFactory,
      // Standalone list rows (checkbox rows, sheet rows) get rounded
      // highlights with breathing room around their content.
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        horizontalTitleGap: 12,
        minVerticalPadding: 10,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          hoverColor: teal.withValues(alpha: .10),
          highlightColor: teal.withValues(alpha: .14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
      // Every pushed screen slides/fades in the same way on all platforms.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: navy.withValues(alpha: .12),
        foregroundColor: navy,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -.3,
          color: navy,
        ),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        hintStyle: const TextStyle(color: faint, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: danger, width: 1.4),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? primary : surface,
        ),
        side: const BorderSide(color: faint, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
        elevation: 6,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: limeSoft,
        surfaceTintColor: Colors.transparent,
        height: 66,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 11,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: s.contains(WidgetState.selected) ? ink : muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 22,
            color: s.contains(WidgetState.selected) ? ink : muted,
          ),
        ),
      ),
    );
  }
}
