import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/core/tafsir_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads offline Tafsir Muyassar for all ayahs', () async {
    expect(await TafsirService.totalEntries, 6236);

    final tafsir = await TafsirService.getVerseTafsir(1, 1);
    expect(tafsir, contains('سورة الفاتحة'));
  });
}
