import 'package:flutter/material.dart';
import '../theme.dart';

class ShimmerBox extends StatefulWidget {
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const ShimmerBox({
    super.key,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  const ShimmerBox.circle({super.key})
      : borderRadius = null,
        shape = BoxShape.circle;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    final base =
        t.isDark ? const Color(0xFF1C1C1C) : const Color(0xFFE4DDD2);
    final highlight =
        t.isDark ? const Color(0xFF2E2E2E) : const Color(0xFFF2EDE5);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final v = _ctrl.value * 4 - 1;
        return Container(
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius:
                widget.shape == BoxShape.circle ? null : widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(v - 1, 0),
              end: Alignment(v + 1, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}
