import 'package:flutter/material.dart';

class AppTheme {
  // Colores Primarios - Paleta Profesional
  static const Color _primaryColor = Color(
    0xFF1F4788,
  ); // Azul profesional oscuro
  static const Color _primaryVariant = Color(
    0xFF2E5C9F,
  ); // Azul profesional medio
  static const Color _secondaryColor = Color(0xFFE8531B); // Naranja profesional
  static const Color _secondaryVariant = Color(0xFFFF7043); // Naranja claro

  // Colores Neutros
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkSurface = Color(0xFF1E1E1E);
  static const Color _lightBackground = Color(0xFFFAFAFA);
  static const Color _lightSurface = Color(0xFFFFFFFF);

  // Colores de Texto
  static const Color _darkText = Color(0xFF1F1F1F);
  static const Color _lightText = Color(0xFFEBEBEB);
  static const Color _hintText = Color(0xFF999999);

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
      bodySmall: TextStyle(fontSize: 12, color: _hintText),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFDDDDDD), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
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
      bodySmall: TextStyle(fontSize: 12, color: Color(0xFF999999)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2A2A),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF444444), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF444444), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _primaryVariant, width: 2),
      ),
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
