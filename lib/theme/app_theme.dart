import 'package:flutter/material.dart';

class AppTheme {
  // Colores Primarios - Paleta Profesional
  static const Color _primaryColor = Color(0xFF1E5BD6); // Azul principal
  static const Color _primaryVariant = Color(0xFF1747A6); // Azul profundo
  static const Color _secondaryColor = Color(0xFF00B3A4); // Teal profesional
  static const Color _secondaryVariant = Color(0xFF33C5BA); // Teal claro

  // Colores Neutros
  static const Color _darkBackground = Color(0xFF0B0F14);
  static const Color _darkSurface = Color(0xFF151A22);
  static const Color _lightBackground = Color(0xFFF6F8FB);
  static const Color _lightSurface = Color(0xFFFFFFFF);

  // Colores de Texto
  static const Color _darkText = Color(0xFF1B2430);
  static const Color _lightText = Color(0xFFE8EDF2);
  static const Color _hintTextLight = Color(0xFF5E6B7A);
  static const Color _hintTextDark = Color(0xFFA7B2C2);

  // Colores auxiliares
  static const Color _outlineLight = Color(0xFFD0D7E2);
  static const Color _outlineDark = Color(0xFF2C3440);
  static const Color _surfaceVariantLight = Color(0xFFEEF2F7);
  static const Color _surfaceVariantDark = Color(0xFF1C222B);

  // Colores de Acento
  static const Color _accentGreen = Color(0xFF4CAF50); // Verde de éxito
  static const Color _accentRed = Color(0xFFE53935); // Rojo de error
  static const Color _accentAmber = Color(
    0xFFFFA500,
  ); // Amarillo para estrellas

  // TEMA CLARO
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: _primaryColor,
      onPrimary: Colors.white,
      primaryContainer: _primaryVariant,
      onPrimaryContainer: Colors.white,
      secondary: _secondaryColor,
      onSecondary: Colors.white,
      secondaryContainer: _secondaryVariant,
      onSecondaryContainer: Colors.white,
      surface: _lightSurface,
      onSurface: _darkText,
      background: _lightBackground,
      onBackground: _darkText,
      surfaceVariant: _surfaceVariantLight,
      onSurfaceVariant: _hintTextLight,
      outline: _outlineLight,
      error: _accentRed,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: _lightBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
    ),
    cardTheme: const CardThemeData(
      color: _lightSurface,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _darkText,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _darkText,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _darkText,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: _darkText),
      bodyMedium: TextStyle(fontSize: 14, color: _darkText),
      bodySmall: TextStyle(fontSize: 12, color: _hintTextLight),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceVariantLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _outlineLight, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _outlineLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      hintStyle: const TextStyle(color: _hintTextLight),
      labelStyle: const TextStyle(color: _hintTextLight),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: _primaryColor,
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
    ),
  );

  // TEMA OSCURO
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: _primaryVariant,
      onPrimary: Colors.white,
      primaryContainer: _primaryColor,
      onPrimaryContainer: Colors.white,
      secondary: _secondaryVariant,
      onSecondary: Colors.white,
      secondaryContainer: _secondaryColor,
      onSecondaryContainer: Colors.white,
      surface: _darkSurface,
      onSurface: _lightText,
      background: _darkBackground,
      onBackground: _lightText,
      surfaceVariant: _surfaceVariantDark,
      onSurfaceVariant: _hintTextDark,
      outline: _outlineDark,
      error: _accentRed,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: _darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryVariant,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 4,
      ),
    ),
    cardTheme: const CardThemeData(
      color: _darkSurface,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _lightText,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _lightText,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: _lightText,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: _lightText),
      bodyMedium: TextStyle(fontSize: 14, color: _lightText),
      bodySmall: TextStyle(fontSize: 12, color: _hintTextDark),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _surfaceVariantDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _outlineDark, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _outlineDark, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryVariant, width: 2),
      ),
      hintStyle: const TextStyle(color: _hintTextDark),
      labelStyle: const TextStyle(color: _hintTextDark),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: _primaryVariant,
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      elevation: 6,
    ),
  );

  // Constantes de colores reutilizables
  static const Color primaryColor = _primaryColor;
  static const Color secondaryColor = _secondaryColor;
  static const Color accentAmber = _accentAmber;
  static const Color accentGreen = _accentGreen;
  static const Color accentRed = _accentRed;
}
