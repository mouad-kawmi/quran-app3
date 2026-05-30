import 'dart:convert';

import 'package:flutter/services.dart';

class TafsirService {
  static const String _assetPath = 'assets/tafsir/ar_tafsir_muyassar.json';

  static Future<Map<String, String>>? _tafsirFuture;

  static Future<String> getVerseTafsir(int surah, int ayah) async {
    final tafsir = await _loadTafsir();
    return tafsir['$surah:$ayah'] ?? 'التفسير غير متوفر لهذه الآية.';
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
