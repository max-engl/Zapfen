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
    gold: Color(0xFFF6B733),
    goldInk: Color(0xFF3A1F02),
    goldText: Color(0xFFF6B733),
    goldFaint: Color(0x14F6B733),     // rgba(246,183,51,0.08)
    goldSoft: Color(0x26F6B733),      // rgba(246,183,51,0.15)
    goldStrong: Color(0x40F6B733),    // rgba(246,183,51,0.25)
    goldBorder: Color(0x4DF6B733),    // rgba(246,183,51,0.30)
    goldBorderStrong: Color(0x66F6B733), // rgba(246,183,51,0.40)
    chipBg: Color(0xB2000000),        // rgba(0,0,0,0.70)
    chipBorder: Color(0x1FFFFFFF),    // rgba(255,255,255,0.12)
    pinBg: Color(0xD9000000),         // rgba(0,0,0,0.85)
    selfieBorder: Color(0xFF000000),
    selfieOutline: Color(0x2EFFFFFF), // rgba(255,255,255,0.18)
    onlineDotRing: Color(0xFF0A0A0A),
    streakCell: [
      Color(0x0AFFFFFF), // empty
      Color(0x40F6B733), // low
      Color(0x8CF6B733), // mid
      Color(0xF2F6B733), // full
    ],
  );

  static const light = PintTheme(
    name: 'light',
    bg: Color(0xFFF6F2EA),
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
    gold: Color(0xFFF6B733),
    goldInk: Color(0xFF3A1F02),
    goldText: Color(0xFF9C6610),
    goldFaint: Color(0x1FF6B733),     // rgba(246,183,51,0.12)
    goldSoft: Color(0x33F6B733),      // rgba(246,183,51,0.20)
    goldStrong: Color(0x47F6B733),    // rgba(246,183,51,0.28)
    goldBorder: Color(0x80D98A14),    // rgba(217,138,20,0.50)
    goldBorderStrong: Color(0xB2D98A14), // rgba(217,138,20,0.70)
    chipBg: Color(0xB2000000),
    chipBorder: Color(0x2EFFFFFF),    // rgba(255,255,255,0.18)
    pinBg: Color(0xFF0A0A0A),
    selfieBorder: Color(0xFFFFFFFF),
    selfieOutline: Color(0x2E000000), // rgba(0,0,0,0.18)
    onlineDotRing: Color(0xFFF6F2EA),
    streakCell: [
      Color(0x0D000000), // empty
      Color(0x4DF6B733), // low
      Color(0x99F6B733), // mid
      Color(0xF2D98A14), // full
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
