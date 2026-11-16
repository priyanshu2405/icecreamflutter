import 'package:flutter/material.dart';

/// Brand colours from the Lick It design file.
class C {
  static const pink = Color(0xFFE8287A);
  static const deep = Color(0xFFD4176B);
  static const blush = Color(0xFFFDE6EF);
  static const cream = Color(0xFFFFF8F3);
  static const ink = Color(0xFF1E1418);
  static const waffle = Color(0xFFC9852F);
  static const yellow = Color(0xFFFFD54A);
  static const line = Color(0xFFF2D3E0);
  static const grey = Color(0xFF6F6267);
  static const green = Color(0xFF1F8A4C);
  static const map = Color(0xFFEFEBE7);
  static const park = Color(0xFFD9EED6);
  static const blue = Color(0xFF2F80ED);
}

/// Headline font (Fredoka).
TextStyle fred(
  double size, {
  Color color = C.ink,
  FontWeight weight = FontWeight.w700,
  double? height,
  double? spacing,
}) => TextStyle(
  fontFamily: 'Fredoka',
  fontSize: size,
  color: color,
  fontWeight: weight,
  height: height,
  letterSpacing: spacing,
);

/// Body font (DM Sans).
TextStyle dm(
  double size, {
  Color color = C.ink,
  FontWeight weight = FontWeight.w400,
  double? height,
  double? spacing,
  TextDecoration? decoration,
}) => TextStyle(
  fontFamily: 'DMSans',
  fontSize: size,
  color: color,
  fontWeight: weight,
  height: height,
  letterSpacing: spacing,
  decoration: decoration,
  decorationColor: color,
);

/// Script font (Pacifico).
TextStyle script(double size, {Color color = C.pink, List<Shadow>? shadows}) =>
    TextStyle(
      fontFamily: 'Pacifico',
      fontSize: size,
      color: color,
      height: 1.3,
      shadows: shadows,
    );

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'DMSans',
    scaffoldBackgroundColor: C.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: C.pink,
      primary: C.pink,
      surface: C.cream,
    ),
    splashColor: C.pink.withValues(alpha: 0.08),
    highlightColor: Colors.transparent,
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: C.ink,
      contentTextStyle: dm(14, color: Colors.white, weight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: C.pink,
      selectionHandleColor: C.pink,
    ),
  );
}
