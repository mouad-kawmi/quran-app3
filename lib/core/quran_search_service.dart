import 'package:quran/quran.dart' as quran;

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
  static List<QuranSearchResult> search(String query) {
    final normalizedQuery = normalize(query);
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final results = <QuranSearchResult>[];

    for (var surah = 1; surah <= quran.totalSurahCount; surah++) {
      for (var ayah = 1; ayah <= quran.getVerseCount(surah); ayah++) {
        final verse = quran.getVerse(surah, ayah);
        if (normalize(verse).contains(normalizedQuery)) {
          results.add(
            QuranSearchResult(
              surah: surah,
              ayah: ayah,
              page: quran.getPageNumber(surah, ayah),
              verse: verse,
            ),
          );
        }
      }
    }

    return results;
  }

  static String normalize(String value) {
    return value
        .replaceAll(
          RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'),
          '',
        )
        .replaceAll('\u0640', '')
        .replaceAll(RegExp('[إأآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ئ', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
