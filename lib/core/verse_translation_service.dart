import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:quran_app/core/quran_database.dart';

/// Fetches English verse translations from alquran.cloud,
/// caches them in SQLite for offline use on subsequent loads.
class VerseTranslationService {
  static const _edition = 'en.sahih'; // Saheeh International
  static const _baseUrl = 'https://api.alquran.cloud/v1';

  // In-memory cache for the current session
  static final Map<String, String> _sessionCache = {};

  /// Returns the English translation for [surah]:[ayah].
  /// Order of lookup: memory cache → SQLite → API (requires internet once).
  static Future<String> getTranslation(int surah, int ayah) async {
    final key = '$surah:$ayah';

    // 1. Memory cache
    final mem = _sessionCache[key];
    if (mem != null) return mem;

    // 2. SQLite cache
    final cached = await QuranRepository.instance.getCachedTranslation(
      surah: surah,
      ayah: ayah,
    );
    if (cached != null) {
      _sessionCache[key] = cached;
      return cached;
    }

    // 3. Fetch from API
    try {
      final text = await _fetchFromApi(surah, ayah);
      _sessionCache[key] = text;
      await QuranRepository.instance.cacheTranslation(
        surah: surah,
        ayah: ayah,
        translation: text,
      );
      return text;
    } catch (_) {
      return 'التـرجمة غير متوفرة — تحقق من الاتصال بالإنترنت للتحميل لأول مرة.';
    }
  }

  static Future<String> _fetchFromApi(int surah, int ayah) async {
    final uri = Uri.parse('$_baseUrl/ayah/$surah:$ayah/$_edition');
    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw Exception('API error ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final data = json['data'] as Map<String, dynamic>;
    return data['text'] as String;
  }

  /// Pre-fetches and caches an entire surah (efficient for first-load of a page).
  static Future<void> prefetchSurah(int surah, int ayahCount) async {
    try {
      final uri = Uri.parse('$_baseUrl/surah/$surah/$_edition');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      final ayahs = data['ayahs'] as List<dynamic>;

      for (final a in ayahs) {
        final map = a as Map<String, dynamic>;
        final ayah = map['numberInSurah'] as int;
        final text = map['text'] as String;
        final key = '$surah:$ayah';
        _sessionCache[key] = text;
        await QuranRepository.instance.cacheTranslation(
          surah: surah,
          ayah: ayah,
          translation: text,
        );
      }
    } catch (_) {
      // Silent fail — offline mode
    }
  }
}
