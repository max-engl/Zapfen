import 'package:flutter/material.dart';
import 'dart:math';

/// Converts a hex color string (e.g., "#FF5733") to a Flutter Color
Color hexToColor(String? hexString) {
  if (hexString == null || hexString.isEmpty) {
    return const Color(0xFF6A7C8C); // Default fallback color
  }

  final buffer = StringBuffer();
  // Remove # if present
  final cleanHex = hexString.replaceFirst('#', '');

  // Ensure we have 6 hex digits
  if (cleanHex.length != 6) {
    return const Color(0xFF6A7C8C);
  }

  try {
    buffer.write('ff${cleanHex.toUpperCase()}');
    return Color(int.parse(buffer.toString(), radix: 16));
  } catch (e) {
    return const Color(0xFF6A7C8C);
  }
}

/// Determines if text should be white (light) or black (dark) based on background color
/// Using relative luminance formula
bool shouldUseWhiteText(Color backgroundColor) {
  // Calculate relative luminance using newer API
  final r = _linearize((backgroundColor.r * 255).round() / 255);
  final g = _linearize((backgroundColor.g * 255).round() / 255);
  final b = _linearize((backgroundColor.b * 255).round() / 255);

  final luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b;

  // If luminance > 0.5, use dark text; otherwise use light text
  return luminance < 0.5;
}

double _linearize(double value) {
  if (value <= 0.03928) {
    return value / 12.92;
  }
  return pow((value + 0.055) / 1.055, 2.4) as double;
}
