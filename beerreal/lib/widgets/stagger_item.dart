import 'package:flutter/material.dart';

/// Wraps [child] in a staggered fade+slide-from-top-left entrance.
/// Use for list items where [index] determines the delay.
/// Delay is capped at [_maxStagger] so long lists stay snappy.
class StaggerItem extends StatelessWidget {
  final int index;
  final Widget child;

  const StaggerItem({super.key, required this.index, required this.child});

  static const _animMs = 180;
  static const _staggerMs = 45;
  static const _maxStagger = 5;
  static const _totalMs = _animMs + _staggerMs * _maxStagger; // 405ms

  @override
  Widget build(BuildContext context) {
    final i = index.clamp(0, _maxStagger);
    final start = (_staggerMs * i) / _totalMs;
    final end = (_staggerMs * i + _animMs) / _totalMs;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: _totalMs),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(-10 * (1 - value), -10 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Wraps [child] in a staggered fade+slide entrance keyed to a grid diagonal.
/// Pass [diagonalIndex] = col + row so the wave sweeps top-left → bottom-right.
class DiagonalStaggerItem extends StatelessWidget {
  final int diagonalIndex;
  final Widget child;

  const DiagonalStaggerItem({
    super.key,
    required this.diagonalIndex,
    required this.child,
  });

  static const _animMs = 380;
  static const _staggerMs = 70;
  static const _maxDiag = 6;
  static const _totalMs = _animMs + _staggerMs * _maxDiag; // 800ms

  @override
  Widget build(BuildContext context) {
    final d = diagonalIndex.clamp(0, _maxDiag);
    final start = (_staggerMs * d) / _totalMs;
    final end = (_staggerMs * d + _animMs) / _totalMs;
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: _totalMs),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Interval(start, end.clamp(0.0, 1.0), curve: Curves.easeOutCubic),
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(-18 * (1 - value), -18 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
