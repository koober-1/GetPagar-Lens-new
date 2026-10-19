import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFFE4005A); 
  static const Color appBar = Color(0xFF3B2BFF); // close to screenshot blue/purple
  static const Color textDark = Color(0xFF111111);
  static const Color textMuted = Color(0xFF666666);
  static const Color border = Color(0xFFE5E5E5);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: base.textTheme.copyWith(
        headlineSmall: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: textDark,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          height: 1.35,
          color: textMuted,
        ),
      ),
    );
  }
}

