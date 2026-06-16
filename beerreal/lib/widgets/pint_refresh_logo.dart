import 'package:flutter/cupertino.dart' show RefreshIndicatorMode;
import 'package:flutter/material.dart';

class PintRefreshLogo extends StatefulWidget {
  final RefreshIndicatorMode state;
  final double pulledExtent;
  final double triggerDistance;

  const PintRefreshLogo({
    super.key,
    required this.state,
    required this.pulledExtent,
    required this.triggerDistance,
  });

  @override
  State<PintRefreshLogo> createState() => _PintRefreshLogoState();
}

class _PintRefreshLogoState extends State<PintRefreshLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  bool get _isRefreshing =>
      widget.state == RefreshIndicatorMode.refresh ||
      widget.state == RefreshIndicatorMode.armed;

  @override
  void didUpdateWidget(PintRefreshLogo old) {
    super.didUpdateWidget(old);
    if (_isRefreshing && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!_isRefreshing && _spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.pulledExtent / widget.triggerDistance).clamp(
      0.0,
      1.0,
    );
    return Center(
      child: Opacity(
        opacity: progress,
        child: RotationTransition(
          turns:
              _isRefreshing ? _spin : AlwaysStoppedAnimation(progress * 0.5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              'assets/icons/app_icon.png',
              width: 36,
              height: 36,
            ),
          ),
        ),
      ),
    );
  }
}
