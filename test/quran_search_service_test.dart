import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/quran_search_service.dart';

void main() {
  test('search finds Arabic Quran text without diacritics', () async {
    final results = await QuranSearchService.search('الله');

    expect(results, isNotEmpty);
    expect(results.first.surah, 1);
    expect(results.first.ayah, 1);
  });

  test('normalizes common Arabic spelling variants', () {
    expect(
      QuranSearchService.normalize('ٱللَّهُ'),
      QuranSearchService.normalize('الله'),
    );
  });
}
