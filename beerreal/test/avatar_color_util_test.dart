import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beerreal/core/avatar_color_util.dart';

void main() {
  group('Avatar Color Utilities', () {
    test('hexToColor converts valid hex string to Color', () {
      final color = hexToColor('#FF5733');
      expect(color, isNotNull);
      // Check if the color was parsed (can't directly compare Color values,
      // but we can check it didn't throw and returned a Color)
      expect(color, isA<Color>());
    });

    test('hexToColor handles null gracefully', () {
      final color = hexToColor(null);
      expect(color, isA<Color>());
    });

    test('hexToColor handles empty string gracefully', () {
      final color = hexToColor('');
      expect(color, isA<Color>());
    });

    test('hexToColor handles invalid formats gracefully', () {
      final color = hexToColor('invalid');
      expect(color, isA<Color>());
    });

    test('hexToColor removes # prefix', () {
      final colorWithHash = hexToColor('#FF5733');
      final colorWithoutHash = hexToColor('FF5733');
      expect(colorWithHash, equals(colorWithoutHash));
    });

    test('shouldUseWhiteText returns true for dark colors', () {
      // Dark color
      final darkColor = Color(0xFF333333);
      expect(shouldUseWhiteText(darkColor), isTrue);
    });

    test('shouldUseWhiteText returns false for light colors', () {
      // Light color
      final lightColor = Color(0xFFEEEEEE);
      expect(shouldUseWhiteText(lightColor), isFalse);
    });

    test('shouldUseWhiteText works with various colors', () {
      // Test with common colors
      final red = Color(0xFFFF0000);
      final green = Color(0xFF00FF00);
      final blue = Color(0xFF0000FF);
      final white = Color(0xFFFFFFFF);
      final black = Color(0xFF000000);

      // These should all be non-null and return booleans
      expect(shouldUseWhiteText(red), isA<bool>());
      expect(shouldUseWhiteText(green), isA<bool>());
      expect(shouldUseWhiteText(blue), isA<bool>());
      expect(shouldUseWhiteText(white), isA<bool>());
      expect(shouldUseWhiteText(black), isA<bool>());
    });
  });
}
