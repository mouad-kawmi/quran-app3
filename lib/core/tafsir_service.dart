import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:quran_app/core/quran_database.dart';

class TafsirService {
  static const String _assetPath = 'assets/tafsir/ar_tafsir_muyassar.json';
  static const String _fallbackMessage =
      '\u0627\u0644\u062a\u0641\u0633\u064a\u0631 \u063a\u064a\u0631 \u0645\u062a\u0648\u0641\u0631 \u0644\u0647\u0630\u0647 \u0627\u0644\u0622\u064a\u0629.';

  static Future<Map<String, String>>? _tafsirFuture;

  static Future<String> getVerseTafsir(int surah, int ayah) async {
    final cached = await QuranRepository.instance.getCachedTafsir(
      surah: surah,
      ayah: ayah,
    );
    if (cached != null) {
      return cached;
    }

    final tafsir = await _loadTafsir();
    final text = tafsir['$surah:$ayah'];
    if (text == null) {
      return _fallbackMessage;
    }

    await QuranRepository.instance.cacheTafsir(
      surah: surah,
      ayah: ayah,
      tafsir: text,
    );
    return text;
  }

  static Future<int> get totalEntries async => (await _loadTafsir()).length;

  static Future<Map<String, String>> _loadTafsir() {
    return _tafsirFuture ??= _readTafsirAsset();
  }

  static Future<Map<String, String>> _readTafsirAsset() async {
    final rawJson = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final ayahs = decoded['ayahs'] as Map<String, dynamic>;

    return ayahs.map((key, value) => MapEntry(key, value.toString()));
  }
}
