import 'package:flutter/material.dart';

/// NomadKit Design System Tokens - Calibrated 100% to Figma Design
class NomadKit {
  static const sand = Color(0xFF734129);
  static const sandDark = Color(0xFF734129);
  static const sandLight = Color(0xFFF6E6D3);
  static const ocean = Color(0xFF0891B2); // Figma link & info cyan
  static const oceanLight = Color(0xFFF0F9FF);
  static const forest = Color(0xFF1F4D32);
  static const forestLight = Color(0xFFE0F2E5);
  static const warning = Color(0xFFCA8A04); // Figma draft gold/orange
  static const warningLight = Color(0xFFFEF9C3);
  static const ink = Color(0xFF30231B);
  static const secondary = Color(0xFF695A50);
  static const canvas = Color(0xFFFDFAF5);
  static const surface = Colors.white;
  static const border = Color(0xFFDED8D1);
  static const lineSoft = Color(0xFFF2EDE7);
  static const error = Color(0xFF9F2D2D);

  // Shared mobile typography: practice/AI reuse these rather than screen constants.
  static const title = TextStyle(
    fontSize: 21,
    height: 30 / 21,
    fontWeight: FontWeight.w700,
    color: ink,
  );
  static const subtitle = TextStyle(
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w600,
    color: ink,
  );
  static const body = TextStyle(fontSize: 15, height: 24 / 15, color: ink);
  static const caption = TextStyle(
    fontSize: 12,
    height: 18 / 12,
    color: secondary,
  );
  static const label = TextStyle(
    fontSize: 13,
    height: 21 / 13,
    fontWeight: FontWeight.w500,
    color: ink,
  );
  static const section = TextStyle(
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w600,
    color: ink,
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
