import 'package:flutter/material.dart';
import 'package:profe_unasam/screens/home_screen.dart';
import 'package:profe_unasam/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Califica a tu Profe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        onThemeToggle: (isDark) {
          setState(() {
            _isDarkMode = isDark;
          });
        },
        isDarkMode: _isDarkMode,
      ),
    );
  }
}
