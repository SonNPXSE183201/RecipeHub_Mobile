import 'package:flutter/material.dart';

/// NomadKit Design System Tokens - Calibrated 100% to Figma Design
class NomadKit {
  static const sand = Color(0xFFC49A6C); // Figma primary sand/caramel
  static const sandDark = Color(0xFFA07040); // Figma overline brown
  static const sandLight = Color(0xFFFAF6F0); // Figma quick action card bg
  static const ocean = Color(0xFF0891B2); // Figma link & info cyan
  static const oceanLight = Color(0xFFF0F9FF);
  static const forest = Color(0xFF166534); // Figma approved green
  static const forestLight = Color(0xFFDCFCE7);
  static const warning = Color(0xFFCA8A04); // Figma draft gold/orange
  static const warningLight = Color(0xFFFEF9C3);
  static const ink = Color(0xFF292524); // Figma headline text
  static const secondary = Color(0xFF78716C); // Figma body text
  static const canvas = Color(0xFFFFFDF7); // Warm paper background
  static const surface = Colors.white;
  static const border = Color(0xFFE7E0D5);
  static const error = Color(0xFFDC2626);

  // Shared mobile typography: practice/AI reuse these rather than screen constants.
  static const title = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    color: ink,
  );
  static const subtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: ink,
  );
  static const body = TextStyle(fontSize: 14, height: 1.4, color: ink);
  static const caption = TextStyle(
    fontSize: 12,
    height: 1.35,
    color: secondary,
  );
  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: ink,
  );
  static const section = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    color: sandDark,
    letterSpacing: .6,
  );
  static const timer = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w900,
    color: ink,
    fontFamily: 'monospace',
  );
  static const timerCompact = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: ink,
    fontFamily: 'monospace',
  );
}
