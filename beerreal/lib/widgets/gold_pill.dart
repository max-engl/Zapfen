import 'package:flutter/material.dart';
import '../theme.dart';

class GoldPill extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double fontSize;

  const GoldPill({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: t.gold,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children
            .map(
              (w) => DefaultTextStyle(
                style: TextStyle(
                  color: t.goldInk,
                  fontWeight: FontWeight.w700,
                  fontSize: fontSize,
                  letterSpacing: -0.01 * fontSize,
                ),
                child: w,
              ),
            )
            .toList(),
      ),
    );
  }
}
