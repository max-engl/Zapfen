import 'package:flutter/material.dart';

/// Golden "B" logo on black rounded square, with foam-bubble dots.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final f = size / 32;
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.2237),
        child: ColoredBox(
          color: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(
                child: Center(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFFE89A),
                        Color(0xFFF6B733),
                        Color(0xFFD98A14),
                        Color(0xFF7A3F06),
                      ],
                      stops: [0.0, 0.30, 0.65, 1.0],
                    ).createShader(bounds),
                    blendMode: BlendMode.srcIn,
                    child: Text(
                      'Z',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.95,
                        fontWeight: FontWeight.w900,
                        height: 0.82,
                        letterSpacing: -size * 0.057,
                      ),
                    ),
                  ),
                ),
              ),
              // Foam bubbles
              Positioned(
                left: size * 0.38,
                top: size * 0.10,
                child: _dot(3.5 * f, Colors.white),
              ),
              Positioned(
                left: size * 0.55,
                top: size * 0.06,
                child: _dot(2.4 * f, Colors.white),
              ),
              Positioned(
                left: size * 0.66,
                top: size * 0.14,
                child: _dot(1.8 * f, const Color(0xFFF0EBDE)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(double diameter, Color color) => Container(
    width: diameter,
    height: diameter,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
