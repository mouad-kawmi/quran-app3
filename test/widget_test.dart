import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_app/core/app_settings.dart';
import 'package:quran_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Quran app builds the home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('ar', null);
    final settings = AppSettingsController();
    await settings.load();

    await tester.pumpWidget(QuranApp(settings: settings));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('نور القرآن'), findsOneWidget);
  });
}
