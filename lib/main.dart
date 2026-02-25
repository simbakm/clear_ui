import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/offender_portal_screen.dart';

void main() {
  runApp(const ClearApp());
}

class ClearApp extends StatelessWidget {
  const ClearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'CLEAR',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          initialRoute: '/login',
          routes: {
            '/login': (_) => const LoginScreen(),
            '/offender': (_) => const OffenderPortalScreen(),
          },
        );
      },
    );
  }
}
