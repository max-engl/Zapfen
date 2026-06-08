import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import 'brand_mark.dart';

/// Full-screen pulsing logo — used for app startup and full-screen waits.
class PintLogoLoader extends StatefulWidget {
  final double size;
  const PintLogoLoader({super.key, this.size = 72});

  @override
  State<PintLogoLoader> createState() => _PintLogoLoaderState();
}

class _PintLogoLoaderState extends State<PintLogoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.88, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Scaffold(
      backgroundColor: t.bg,
      body: Center(
        child: ScaleTransition(
          scale: _scale,
          child: BrandMark(size: widget.size),
        ),
      ),
    );
  }
}

/// Inline logo pulse without a Scaffold — for embedding inside existing screens.
class PintLogoLoaderInline extends StatefulWidget {
  final double size;
  const PintLogoLoaderInline({super.key, this.size = 48});

  @override
  State<PintLogoLoaderInline> createState() => _PintLogoLoaderInlineState();
}

class _PintLogoLoaderInlineState extends State<PintLogoLoaderInline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.88, end: 1.08).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: BrandMark(size: widget.size),
    );
  }
}

/// Spinning app logo — drop-in replacement for CircularProgressIndicator.
class SpinningAppLogo extends StatefulWidget {
  final double size;
  const SpinningAppLogo({super.key, this.size = 32});

  @override
  State<SpinningAppLogo> createState() => _SpinningAppLogoState();
}

class _SpinningAppLogoState extends State<SpinningAppLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.size * 0.28),
        child: Image.asset(
          'assets/icons/app_icon.png',
          width: widget.size,
          height: widget.size,
        ),
      ),
    );
  }
}

/// Three staggered pulsing dots — used inline inside buttons and small spaces.
class PintDots extends StatefulWidget {
  final Color color;
  final double dotSize;
  final double spacing;

  const PintDots({
    super.key,
    required this.color,
    this.dotSize = 5,
    this.spacing = 4,
  });

  @override
  State<PintDots> createState() => _PintDotsState();
}

class _PintDotsState extends State<PintDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final phase = (i / 3.0);
            final v = _ctrl.value;
            // Sine wave shifted per dot, clamped to [0.3, 1.0] opacity
            final opacity = 0.3 +
                0.7 *
                    (0.5 +
                            0.5 *
                                math.sin(
                                  2 * math.pi * ((v - phase) % 1.0),
                                ))
                        .clamp(0.0, 1.0);
            return Container(
              margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
              width: widget.dotSize,
              height: widget.dotSize,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}
