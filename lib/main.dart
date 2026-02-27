import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/offender_portal_screen.dart';

void main() {
  usePathUrlStrategy();
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
          onGenerateRoute: (settings) {
            final uri = Uri.parse(settings.name ?? '/');
            final path = uri.path.toLowerCase().trim();

            if (path.startsWith('/offender')) {
              final idParam = uri.queryParameters['id'];
              final incidentId = int.tryParse(idParam ?? '');
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => OffenderPortalScreen(incidentId: incidentId),
              );
            }

            if (path == '/admin' || path == '/' || path == '/login') {
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const LoginScreen(),
              );
            }

            // Fallback for everything else
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => const LoginScreen(),
            );
          },
        );
      },
    );
  }
}
