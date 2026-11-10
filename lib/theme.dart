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

  // ---- Theme-aware tokens ---------------------------------------------
  // Flip between light and dark. Read them at build time (they cannot be
  // used in `const` expressions). [setDark] rebuilds the whole tree.
  static bool dark = false;
  static final ValueNotifier<bool> darkNotifier = ValueNotifier(false);
  static Color _p(int light, int darkValue) => Color(dark ? darkValue : light);

  // Dark mode: true black canvas, white text, soft grey cards and teal accents.
  static Color get bg => _p(0xFFFFFFFF, 0xFF000000);
  static Color get surface => _p(0xFFFFFFFF, 0xFF111214);
  static Color get ink => _p(0xFF0E1A2E, 0xFFFFFFFF);
  static Color get muted => _p(0xFF6E7A8C, 0xFFA8B0BC);
  static Color get faint => _p(0xFFA5AFBD, 0xFF737B87);
  static Color get line => _p(0xFFE2E7EE, 0xFF26292E);
  static Color get limeSoft => _p(0xFFE0FAF6, 0xFF0E2A2A);

  /// Headings and titles: navy on light, white on dark.
  static Color get title => _p(0xFF0E2142, 0xFFFFFFFF);

  /// Selected / active / primary-button colour: navy on light, teal on dark.
  static Color get accent => _p(0xFF0E2142, 0xFF12E8CF);
  static Color get onAccent => _p(0xFFFFFFFF, 0xFF0E2142);

  /// Teal used for small text and icons (readable on both themes).
  static Color get tealText => _p(0xFF0B8F80, 0xFF12E8CF);

  /// Map and canvas backdrop outside the phone column.
  static Color get backdrop => _p(0xFFE6EBF2, 0xFF000000);

  static const primary = navy;
  static const primarySoft = Color(0xFF1A3159);
  // Accent used on dark surfaces (buttons, highlights): logo teal.
  static const lime = teal;
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
        seedColor: navy,
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: accent,
        onPrimary: onAccent,
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
        foregroundColor: title,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -.3,
          color: title,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? const Color(0xFF17191C) : surface,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        hintStyle: TextStyle(color: faint, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.4),
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
          (s) => s.contains(WidgetState.selected) ? accent : surface,
        ),
        checkColor: WidgetStatePropertyAll(onAccent),
        side: BorderSide(color: faint, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark ? const Color(0xFF1E2126) : navy,
        contentTextStyle: const TextStyle(color: Colors.white),
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

  /// Switches light / dark and repaints every screen in place, keeping the
  /// navigation stack and all screen state.
  static void setDark(bool value) {
    if (dark == value) return;
    dark = value;
    darkNotifier.value = value;
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
  }
}
