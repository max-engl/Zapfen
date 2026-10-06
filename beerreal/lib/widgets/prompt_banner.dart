import 'package:flutter/material.dart';
import '../theme.dart';

class PromptBanner extends StatelessWidget {
  final int minsLeft;
  final VoidCallback onCapture;
  final bool posted;

  const PromptBanner({
    super.key,
    required this.minsLeft,
    required this.onCapture,
    required this.posted,
  });

  @override
  Widget build(BuildContext context) {
    final t = PintThemeProvider.of(context);
    return posted ? _poured(t) : _active(t);
  }

  Widget _poured(PintTheme t) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.goldFaint,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.goldBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: t.goldSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.sports_bar_outlined, color: t.goldText, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Du hast heute bewertet.',
                      style: TextStyle(
                          color: t.text, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Nächster Prompt kommt morgen, zufällige Zeit.',
                      style: TextStyle(color: t.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _active(PintTheme t) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
        decoration: BoxDecoration(
          color: t.goldFaint,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: t.goldBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bolt, size: 10, color: t.goldText),
                      const SizedBox(width: 6),
                      Text(
                        'ZEIT ZUM BEWERTEN',
                        style: TextStyle(
                          color: t.goldText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Zeig deinen Freunden,\nwas in deinem Glas ist.',
                    style: TextStyle(
                      color: t.text,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$minsLeft Min übrig · Später posten, es wird trotzdem angezeigt.',
                    style: TextStyle(color: t.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            GestureDetector(
              onTap: onCapture,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(shape: BoxShape.circle, color: t.gold),
                child: Icon(Icons.camera_alt_outlined, color: t.goldInk, size: 26),
              ),
            ),
          ],
        ),
      );
}
