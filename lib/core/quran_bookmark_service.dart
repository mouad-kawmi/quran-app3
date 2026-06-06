import 'dart:convert';

import 'package:quran_app/core/quran_database.dart';
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

    if (surah == null || ayah == null || page == null || createdAt == null) {
      return null;
    }

    return QuranBookmark(
      surah: surah,
      ayah: ayah,
      page: page,
      createdAt: createdAt,
    );
  }

  static QuranBookmark fromRecord(QuranBookmarkRecord record) {
    final ayah = record.ayah;
    return QuranBookmark(
      surah: ayah.surah,
      ayah: ayah.ayah,
      page: ayah.page,
      createdAt: record.createdAt,
    );
  }
}

class QuranBookmarkService {
  static const _bookmarksKey = 'quran_bookmarks';
  static const _bookmarksMigratedKey = 'quran_bookmarks_sqlite_migrated';

  static Future<List<QuranBookmark>> loadBookmarks() async {
    await _migrateLegacyBookmarks();
    final bookmarks = await QuranRepository.instance.loadBookmarks();
    return bookmarks.map(QuranBookmark.fromRecord).toList(growable: false);
  }

  static Future<bool> isBookmarked(int surah, int ayah) async {
    await _migrateLegacyBookmarks();
    return QuranRepository.instance.isBookmarked(surah: surah, ayah: ayah);
  }

  static Future<void> addBookmark({
    required int surah,
    required int ayah,
  }) async {
    await _migrateLegacyBookmarks();
    await QuranRepository.instance.addBookmark(surah: surah, ayah: ayah);
  }

  static Future<void> removeBookmark(int surah, int ayah) async {
    await _migrateLegacyBookmarks();
    await QuranRepository.instance.removeBookmark(surah: surah, ayah: ayah);
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

  static Future<void> _migrateLegacyBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_bookmarksMigratedKey) ?? false) {
      return;
    }

    final encodedBookmarks = prefs.getStringList(_bookmarksKey) ?? const [];
    for (final encoded in encodedBookmarks) {
      final bookmark = _decodeBookmark(encoded);
      if (bookmark == null) {
        continue;
      }
      await QuranRepository.instance.addBookmark(
        surah: bookmark.surah,
        ayah: bookmark.ayah,
        createdAt: bookmark.createdAt,
      );
    }

    await prefs.setBool(_bookmarksMigratedKey, true);
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
}
