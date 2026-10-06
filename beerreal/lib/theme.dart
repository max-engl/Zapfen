import 'package:flutter/material.dart';

class PintTheme {
  final String name;
  final Color bg;
  final Color surface;
  final Color surfaceWeak;
  final Color surfaceWeaker;
  final Color text;
  final Color textMuted;
  final Color textFaint;
  final Color border;
  final Color borderWeak;
  final Color divider;
  final bool isDark;

  final Color gold;
  final Color goldInk;
  final Color goldText;
  final Color goldFaint;
  final Color goldSoft;
  final Color goldStrong;
  final Color goldBorder;
  final Color goldBorderStrong;

  final Color chipBg;
  final Color chipBorder;
  final Color pinBg;
  final Color selfieBorder;
  final Color selfieOutline;
  final Color onlineDotRing;
  final List<Color> streakCell;

  const PintTheme({
    required this.name,
    required this.bg,
    required this.surface,
    required this.surfaceWeak,
    required this.surfaceWeaker,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.border,
    required this.borderWeak,
    required this.divider,
    required this.isDark,
    required this.gold,
    required this.goldInk,
    required this.goldText,
    required this.goldFaint,
    required this.goldSoft,
    required this.goldStrong,
    required this.goldBorder,
    required this.goldBorderStrong,
    required this.chipBg,
    required this.chipBorder,
    required this.pinBg,
    required this.selfieBorder,
    required this.selfieOutline,
    required this.onlineDotRing,
    required this.streakCell,
  });

  static const dark = PintTheme(
    name: 'dark',
    bg: Color(0xFF0A0A0A),
    surface: Color(0xFF141414),
    surfaceWeak: Color(0x0FFFFFFF),   // rgba(255,255,255,0.06)
    surfaceWeaker: Color(0x0AFFFFFF), // rgba(255,255,255,0.04)
    text: Color(0xFFFFFFFF),
    textMuted: Color(0x8CFFFFFF),     // rgba(255,255,255,0.55)
    textFaint: Color(0x66FFFFFF),     // rgba(255,255,255,0.40)
    border: Color(0x14FFFFFF),        // rgba(255,255,255,0.08)
    borderWeak: Color(0x0AFFFFFF),    // rgba(255,255,255,0.04)
    divider: Color(0x0AFFFFFF),       // rgba(255,255,255,0.04)
    isDark: true,
    gold: Color(0xFF4DB8FF),
    goldInk: Color(0xFF062030),
    goldText: Color(0xFF4DB8FF),
    goldFaint: Color(0x144DB8FF),     // rgba(77,184,255,0.08)
    goldSoft: Color(0x264DB8FF),      // rgba(77,184,255,0.15)
    goldStrong: Color(0x404DB8FF),    // rgba(77,184,255,0.25)
    goldBorder: Color(0x4D4DB8FF),    // rgba(77,184,255,0.30)
    goldBorderStrong: Color(0x664DB8FF), // rgba(77,184,255,0.40)
    chipBg: Color(0xB2000000),        // rgba(0,0,0,0.70)
    chipBorder: Color(0x1FFFFFFF),    // rgba(255,255,255,0.12)
    pinBg: Color(0xD9000000),         // rgba(0,0,0,0.85)
    selfieBorder: Color(0xFF000000),
    selfieOutline: Color(0x2EFFFFFF), // rgba(255,255,255,0.18)
    onlineDotRing: Color(0xFF0A0A0A),
    streakCell: [
      Color(0x0AFFFFFF), // 0 drinks  – empty
      Color(0x334DB8FF), // 1 drink   – faint blue
      Color(0x704DB8FF), // 2–3       – light blue
      Color(0xCC4DB8FF), // 4–6       – strong blue
      Color(0xFF4DB8FF), // 7–9       – full sky blue
      Color(0xFF0090D4), // 10+       – vivid deep blue
    ],
  );

  static const light = PintTheme(
    name: 'light',
    bg: Color(0xFFF0F5FA),
    surface: Color(0xFFFFFFFF),
    surfaceWeak: Color(0x0A000000),   // rgba(0,0,0,0.04)
    surfaceWeaker: Color(0x06000000), // rgba(0,0,0,0.025)
    text: Color(0xFF0A0A0A),
    textMuted: Color(0x8C000000),     // rgba(0,0,0,0.55)
    textFaint: Color(0x66000000),     // rgba(0,0,0,0.40)
    border: Color(0x17000000),        // rgba(0,0,0,0.09)
    borderWeak: Color(0x0F000000),    // rgba(0,0,0,0.06)
    divider: Color(0x0D000000),       // rgba(0,0,0,0.05)
    isDark: false,
    gold: Color(0xFF4DB8FF),
    goldInk: Color(0xFF062030),
    goldText: Color(0xFF1480B8),
    goldFaint: Color(0x1F4DB8FF),     // rgba(77,184,255,0.12)
    goldSoft: Color(0x334DB8FF),      // rgba(77,184,255,0.20)
    goldStrong: Color(0x474DB8FF),    // rgba(77,184,255,0.28)
    goldBorder: Color(0x801480B8),    // rgba(20,128,184,0.50)
    goldBorderStrong: Color(0xB21480B8), // rgba(20,128,184,0.70)
    chipBg: Color(0xB2000000),
    chipBorder: Color(0x2EFFFFFF),    // rgba(255,255,255,0.18)
    pinBg: Color(0xFF0A0A0A),
    selfieBorder: Color(0xFFFFFFFF),
    selfieOutline: Color(0x2E000000), // rgba(0,0,0,0.18)
    onlineDotRing: Color(0xFFF0F5FA),
    streakCell: [
      Color(0x0D000000), // 0 drinks  – empty
      Color(0x334DB8FF), // 1 drink   – faint blue
      Color(0x801480B8), // 2–3       – medium blue
      Color(0xCC1480B8), // 4–6       – strong blue
      Color(0xFF1480B8), // 7–9       – full blue
      Color(0xFF005FA3), // 10+       – deep blue
    ],
  );
}

class PintThemeProvider extends InheritedWidget {
  final PintTheme theme;

  const PintThemeProvider({
    super.key,
    required this.theme,
    required super.child,
  });

  static PintTheme of(BuildContext context) {
    final p = context.dependOnInheritedWidgetOfExactType<PintThemeProvider>();
    return p?.theme ?? PintTheme.dark;
  }

  @override
  bool updateShouldNotify(PintThemeProvider old) => theme.name != old.theme.name;
}
