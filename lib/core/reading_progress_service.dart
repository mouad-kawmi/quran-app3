import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

class QuranLastRead {
  const QuranLastRead({
    required this.surah,
    required this.ayah,
    required this.updatedAt,
  });

  final int surah;
  final int ayah;
  final DateTime? updatedAt;
}

class ReadingProgressService {
  static const _lastReadSurahKey = 'quran_last_read_surah';
  static const _lastReadAyahKey = 'quran_last_read_ayah';
  static const _lastReadUpdatedAtKey = 'quran_last_read_updated_at';

  static Future<QuranLastRead?> loadLastRead() async {
    final prefs = await SharedPreferences.getInstance();
    final surah = prefs.getInt(_lastReadSurahKey);
    final ayah = prefs.getInt(_lastReadAyahKey);

    if (surah == null || ayah == null || !_isValidPosition(surah, ayah)) {
      return null;
    }

    final updatedAtValue = prefs.getString(_lastReadUpdatedAtKey);
    return QuranLastRead(
      surah: surah,
      ayah: ayah,
      updatedAt: updatedAtValue == null
          ? null
          : DateTime.tryParse(updatedAtValue),
    );
  }

  static Future<void> saveLastRead({
    required int surah,
    required int ayah,
  }) async {
    if (!_isValidPosition(surah, ayah)) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastReadSurahKey, surah);
    await prefs.setInt(_lastReadAyahKey, ayah);
    await prefs.setString(
      _lastReadUpdatedAtKey,
      DateTime.now().toIso8601String(),
    );
  }

  static bool _isValidPosition(int surah, int ayah) {
    return surah >= 1 &&
        surah <= quran.totalSurahCount &&
        ayah >= 1 &&
        ayah <= quran.getVerseCount(surah);
  }
}
