import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quran_app/main.dart';

void main() {
  testWidgets('Quran app builds the home screen', (WidgetTester tester) async {
    await initializeDateFormatting('ar', null);

    await tester.pumpWidget(const QuranApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('نور القرآن'), findsOneWidget);
  });
}
