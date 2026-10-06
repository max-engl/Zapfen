import 'package:flutter/material.dart';

enum ImgTone { beer, night, bar, sky, selfie, avatar, map, mapLight, pour }

ImgTone toneFromString(String s) => switch (s) {
      'beer' => ImgTone.beer,
      'night' => ImgTone.night,
      'bar' => ImgTone.bar,
      'sky' => ImgTone.sky,
      'selfie' => ImgTone.selfie,
      'avatar' => ImgTone.avatar,
      'map' => ImgTone.map,
      'mapLight' => ImgTone.mapLight,
      'pour' => ImgTone.pour,
      _ => ImgTone.beer,
    };

Gradient _gradientFor(ImgTone tone) => switch (tone) {
      ImgTone.beer => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFD97A), Color(0xFFC98014), Color(0xFF6A3A05)],
          stops: [0.0, 0.5, 1.0],
        ),
      ImgTone.night => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A22), Color(0xFF15151C)],
        ),
      ImgTone.bar => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3A2410), Color(0xFF2E1D0A)],
        ),
      ImgTone.sky => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5A4A2A), Color(0xFF4A3A1A)],
        ),
      ImgTone.selfie => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A3A2A), Color(0xFF3A2A1A)],
        ),
      ImgTone.avatar => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A4A2A), Color(0xFF5A3A1A)],
        ),
      ImgTone.map => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1810), Color(0xFF14120B)],
        ),
      ImgTone.mapLight => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFECE5D6), Color(0xFFE2DAC8)],
        ),
      ImgTone.pour => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6B733), Color(0xFFB87509), Color(0xFF2A1502)],
          stops: [0.0, 0.60, 1.0],
        ),
    };

class ImgPlaceholder extends StatelessWidget {
  final ImgTone tone;
  final String label;

  const ImgPlaceholder({super.key, this.tone = ImgTone.beer, this.label = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: _gradientFor(tone)),
      child: label.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Color(0x73FFFFFF),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
