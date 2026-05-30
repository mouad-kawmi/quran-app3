import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_app/core/app_settings.dart';
import 'package:quran_app/core/prayer_notification_service.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/splash/app_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  final settings = AppSettingsController();
  await settings.load();

  // Start background services in parallel with the splash screen.
  // Errors are caught so they never crash the app.
  final startup = _initializeAppServices();

  runApp(QuranApp(settings: settings, startup: startup));
}

Future<void> _initializeAppServices() async {
  try {
    await PrayerNotificationService.initialize();
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'quran_app',
        context: ErrorDescription('initializing background app services'),
      ),
    );
  }
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key, required this.settings, required this.startup});

  final AppSettingsController settings;
  final Future<void> startup;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'نور القرآن',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return AppSettingsScope(
              settings: settings,
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(settings.fontScale),
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          home: AppSplashScreen(startup: startup),
        );
      },
    );
  }
}
