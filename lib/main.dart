import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_app/core/app_settings.dart';
import 'package:quran_app/core/prayer_notification_service.dart';
import 'package:quran_app/core/quran_database.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/navigation/app_shell.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  final settings = AppSettingsController();

  // Start loading settings without blocking runApp — app starts instantly
  // and rebuilds via AnimatedBuilder once settings are ready.
  unawaited(_prepareApp(settings));

  runApp(QuranApp(settings: settings));
}

Future<void> _prepareApp(AppSettingsController settings) async {
  try {
    await Future.wait<void>([
      initializeDateFormatting('ar', null),
      settings.load(),
    ]);
    
    // Remove splash screen cleanly only after settings and locale have loaded
    FlutterNativeSplash.remove();
    
    unawaited(_initializeAppServices());
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'quran_app',
        context: ErrorDescription('preparing app startup'),
      ),
    );
  }
}

Future<void> _initializeAppServices() async {
  try {
    // Delay heavy background initialization to let home screen render smoothly
    Future.delayed(const Duration(seconds: 3), () async {
      unawaited(QuranRepository.instance.warmUp());
      await PrayerNotificationService.initialize(refreshReminders: false);
    });
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
  const QuranApp({super.key, required this.settings});

  final AppSettingsController settings;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'Noor Al-Quran',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          locale: settings.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
          home: const AppShell(),
        );
      },
    );
  }
}
