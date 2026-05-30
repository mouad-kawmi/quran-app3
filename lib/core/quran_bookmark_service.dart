import 'dart:convert';

import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

class QuranBookmark {
  const QuranBookmark({
    required this.surah,
    required this.ayah,
    required this.page,
    required this.createdAt,
  });

  final int surah;
  final int ayah;
  final int page;
  final DateTime createdAt;

  String get key => '$surah:$ayah';

  Map<String, dynamic> toJson() {
    return {
      'surah': surah,
      'ayah': ayah,
      'page': page,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static QuranBookmark? fromJson(Map<String, dynamic> json) {
    final surah = json['surah'] as int?;
    final ayah = json['ayah'] as int?;
    final page = json['page'] as int?;
    final createdAtValue = json['createdAt'] as String?;
    final createdAt = createdAtValue == null
        ? null
        : DateTime.tryParse(createdAtValue);

    if (surah == null ||
        ayah == null ||
        page == null ||
        createdAt == null ||
        !_isValidPosition(surah, ayah)) {
      return null;
    }

    return QuranBookmark(
      surah: surah,
      ayah: ayah,
      page: page,
      createdAt: createdAt,
    );
  }

  static bool _isValidPosition(int surah, int ayah) {
    return surah >= 1 &&
        surah <= quran.totalSurahCount &&
        ayah >= 1 &&
        ayah <= quran.getVerseCount(surah);
  }
}

class QuranBookmarkService {
  static const _bookmarksKey = 'quran_bookmarks';

  static Future<List<QuranBookmark>> loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedBookmarks = prefs.getStringList(_bookmarksKey) ?? const [];

    final bookmarks =
        encodedBookmarks
            .map(_decodeBookmark)
            .whereType<QuranBookmark>()
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return bookmarks;
  }

  static Future<bool> isBookmarked(int surah, int ayah) async {
    final key = '$surah:$ayah';
    final bookmarks = await loadBookmarks();
    return bookmarks.any((bookmark) => bookmark.key == key);
  }

  static Future<void> addBookmark({
    required int surah,
    required int ayah,
  }) async {
    final bookmarks = await loadBookmarks();
    final key = '$surah:$ayah';
    final filtered = bookmarks
        .where((bookmark) => bookmark.key != key)
        .toList(growable: true);

    filtered.insert(
      0,
      QuranBookmark(
        surah: surah,
        ayah: ayah,
        page: quran.getPageNumber(surah, ayah),
        createdAt: DateTime.now(),
      ),
    );

    await _saveBookmarks(filtered);
  }

  static Future<void> removeBookmark(int surah, int ayah) async {
    final key = '$surah:$ayah';
    final bookmarks = await loadBookmarks();
    await _saveBookmarks(
      bookmarks.where((bookmark) => bookmark.key != key).toList(),
    );
  }

  static Future<bool> toggleBookmark({
    required int surah,
    required int ayah,
  }) async {
    final bookmarked = await isBookmarked(surah, ayah);
    if (bookmarked) {
      await removeBookmark(surah, ayah);
      return false;
    }

    await addBookmark(surah: surah, ayah: ayah);
    return true;
  }

  static QuranBookmark? _decodeBookmark(String encoded) {
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return QuranBookmark.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveBookmarks(List<QuranBookmark> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _bookmarksKey,
      bookmarks.map((bookmark) => jsonEncode(bookmark.toJson())).toList(),
    );
  }
}
