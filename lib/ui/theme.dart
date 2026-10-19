import 'package:flutter/material.dart';

abstract final class Palette {
  static const background = Color(0xFF0C101B);
  static const surface = Color(0xFF141B2A);
  static const raised = Color(0xFF1B2536);
  static const border = Color(0xFF293447);
  static const mint = Color(0xFF9EF1CF);
  static const coral = Color(0xFFFFAE9A);
  static const text = Color(0xFFF2F4FA);
  static const muted = Color(0xFF97A5BA);
}

ThemeData buildTheme() => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Palette.background,
  colorScheme: const ColorScheme.dark(
    primary: Palette.mint,
    onPrimary: Palette.background,
    secondary: Palette.coral,
    surface: Palette.surface,
    onSurface: Palette.text,
    outline: Palette.border,
  ),
  fontFamily: 'GridlySans',
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.8,
    ),
    headlineMedium: TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
    ),
    titleLarge: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -.5,
    ),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    bodyMedium: TextStyle(fontSize: 14, height: 1.5),
    bodySmall: TextStyle(fontSize: 12, height: 1.5, color: Palette.muted),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(
        fontFamily: 'GridlySans',
        fontWeight: FontWeight.w700,
        fontSize: 15,
      ),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: Palette.text,
      minimumSize: const Size(48, 48),
      side: const BorderSide(color: Palette.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  tooltipTheme: const TooltipThemeData(
    waitDuration: Duration(milliseconds: 350),
  ),
  dialogTheme: DialogThemeData(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
  ),
);
