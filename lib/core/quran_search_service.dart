import 'package:quran_app/core/quran_database.dart';
import 'package:quran_app/core/quran_text_normalizer.dart';

class QuranSearchResult {
  const QuranSearchResult({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.verse,
  });

  final int surah;
  final int ayah;
  final int page;
  final String verse;
}

class QuranSearchService {
  static Future<List<QuranSearchResult>> search(String query) async {
    final ayahs = await QuranRepository.instance.searchAyahs(query);
    return ayahs
        .map(
          (ayah) => QuranSearchResult(
            surah: ayah.surah,
            ayah: ayah.ayah,
            page: ayah.page,
            verse: ayah.text,
          ),
        )
        .toList(growable: false);
  }

  static String normalize(String value) {
    return QuranTextNormalizer.normalize(value);
  }
}
