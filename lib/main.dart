import 'package:flutter/material.dart';
import 'package:profe_unasam/screens/home_screen.dart';
import 'package:profe_unasam/screens/login_screen.dart';
import 'package:profe_unasam/services/data_service.dart';
import 'package:profe_unasam/theme/app_theme.dart';
import 'package:profe_unasam/utils/route_observer.dart';

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
  final _dataService = DataService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocIn',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      navigatorObservers: [routeObserver],
      routes: {
        '/login': (context) => LoginScreen(
          onLogin: () {
            setState(() {});
          },
        ),
        '/home': (context) => HomeScreen(
          onThemeToggle: (isDark) {
            setState(() {
              _isDarkMode = isDark;
            });
          },
          isDarkMode: _isDarkMode,
        ),
      },
      home: _dataService.isLoggedIn
          ? HomeScreen(
              onThemeToggle: (isDark) {
                setState(() {
                  _isDarkMode = isDark;
                });
              },
              isDarkMode: _isDarkMode,
            )
          : LoginScreen(
              onLogin: () {
                setState(() {});
              },
            ),
    );
  }
}
