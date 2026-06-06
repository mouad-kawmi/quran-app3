import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/quran_database_platform.dart';
import 'package:quran_app/core/quran_text_normalizer.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

class Ayah {
  const Ayah({
    required this.id,
    required this.surah,
    required this.ayah,
    required this.page,
    required this.juz,
    required this.hizb,
    required this.text,
  });

  final int id;
  final int surah;
  final int ayah;
  final int page;
  final int juz;
  final int hizb;
  final String text;

  static Ayah fromMap(Map<String, Object?> map) {
    return Ayah(
      id: map['id'] as int,
      surah: map['surah'] as int,
      ayah: map['ayah'] as int,
      page: map['page'] as int,
      juz: map['juz'] as int,
      hizb: map['hizb'] as int,
      text: map['text_uthmani'] as String,
    );
  }
}

class SurahInfo {
  const SurahInfo({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.ayahsCount,
    required this.revelationType,
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final int ayahsCount;
  final String revelationType;

  static SurahInfo fromMap(Map<String, Object?> map) {
    return SurahInfo(
      id: map['id'] as int,
      nameAr: map['name_ar'] as String,
      nameEn: map['name_en'] as String,
      ayahsCount: map['ayahs_count'] as int,
      revelationType: map['revelation_type'] as String,
    );
  }
}

class QuranBookmarkRecord {
  const QuranBookmarkRecord({
    required this.ayah,
    required this.createdAt,
  });

  final Ayah ayah;
  final DateTime createdAt;

  static QuranBookmarkRecord fromMap(Map<String, Object?> map) {
    return QuranBookmarkRecord(
      ayah: Ayah.fromMap(map),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class QuranDatabase {
  QuranDatabase._();

  static final QuranDatabase instance = QuranDatabase._();

  static const String _databaseName = 'quran_app.sqlite';
  static const String _seedVersionKey = 'quran_seed_version';
  static const String _seedVersion = '1';

  static bool _databaseFactoryConfigured = false;

  sqflite.Database? _database;

  Future<sqflite.Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    _configureDatabaseFactoryOnce();
    final databasePath = await sqflite.getDatabasesPath();
    final database = await sqflite.openDatabase(
      '$databasePath/$_databaseName',
      version: 1,
      onCreate: _createSchema,
      onOpen: _seedIfNeeded,
    );
    _database = database;
    return database;
  }

  Future<void> warmUp() async {
    await database;
  }

  static void _configureDatabaseFactoryOnce() {
    if (_databaseFactoryConfigured) {
      return;
    }

    _databaseFactoryConfigured = true;
    configureQuranDatabaseFactory();
  }

  static Future<void> _createSchema(
    sqflite.Database db,
    int version,
  ) async {
    await db.execute('''
CREATE TABLE ayahs (
  id INTEGER PRIMARY KEY,
  surah INTEGER NOT NULL,
  ayah INTEGER NOT NULL,
  page INTEGER NOT NULL,
  juz INTEGER NOT NULL,
  hizb INTEGER NOT NULL,
  text_uthmani TEXT NOT NULL,
  text_normalized TEXT NOT NULL,
  UNIQUE(surah, ayah)
);
''');

    await db.execute('''
CREATE TABLE surahs (
  id INTEGER PRIMARY KEY,
  name_ar TEXT NOT NULL,
  name_en TEXT NOT NULL,
  ayahs_count INTEGER NOT NULL,
  revelation_type TEXT NOT NULL
);
''');

    await db.execute('''
CREATE TABLE tafsir (
  ayah_id INTEGER PRIMARY KEY,
  tafsir TEXT NOT NULL,
  FOREIGN KEY(ayah_id) REFERENCES ayahs(id) ON DELETE CASCADE
);
''');

    await db.execute('''
CREATE TABLE bookmarks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ayah_id INTEGER NOT NULL UNIQUE,
  created_at TEXT NOT NULL,
  FOREIGN KEY(ayah_id) REFERENCES ayahs(id) ON DELETE CASCADE
);
''');

    await db.execute('''
CREATE TABLE meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);
''');

    await db.execute('''
CREATE TABLE translations (
  ayah_id INTEGER PRIMARY KEY,
  translation_en TEXT NOT NULL,
  FOREIGN KEY(ayah_id) REFERENCES ayahs(id) ON DELETE CASCADE
);
''');

    await db.execute('CREATE INDEX ayahs_page_idx ON ayahs(page, id);');
    await db.execute('CREATE INDEX ayahs_juz_idx ON ayahs(juz, id);');
    await db.execute('CREATE INDEX ayahs_hizb_idx ON ayahs(hizb, id);');
    await db.execute('CREATE INDEX ayahs_surah_idx ON ayahs(surah, ayah);');
    await db.execute(
      'CREATE INDEX ayahs_text_normalized_idx ON ayahs(text_normalized);',
    );
  }

  static Future<void> _seedIfNeeded(sqflite.Database db) async {
    final rows = await db.query(
      'meta',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: const [_seedVersionKey],
      limit: 1,
    );
    if (rows.isNotEmpty && rows.first['value'] == _seedVersion) {
      return;
    }

    await db.transaction((transaction) async {
      await transaction.delete('bookmarks');
      await transaction.delete('tafsir');
      await transaction.delete('ayahs');
      await transaction.delete('surahs');

      final batch = transaction.batch();

      for (var surah = 1; surah <= quran.totalSurahCount; surah++) {
        batch.insert(
          'surahs',
          {
            'id': surah,
            'name_ar': quran.getSurahNameArabic(surah),
            'name_en': quran.getSurahNameEnglish(surah),
            'ayahs_count': quran.getVerseCount(surah),
            'revelation_type': quran.getPlaceOfRevelation(surah),
          },
          conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
        );
      }

      final pageLookup = _buildPageLookup();
      final juzLookup = _buildJuzLookup();
      var ayahId = 1;
      for (var surah = 1; surah <= quran.totalSurahCount; surah++) {
        final verseCount = quran.getVerseCount(surah);
        for (var ayah = 1; ayah <= verseCount; ayah++) {
          final lookupKey = _positionKey(surah, ayah);
          final page = pageLookup[lookupKey] ?? quran.getPageNumber(surah, ayah);
          final juz = juzLookup[lookupKey] ?? quran.getJuzNumber(surah, ayah);
          final text = quran.getVerse(surah, ayah);
          batch.insert(
            'ayahs',
            {
              'id': ayahId,
              'surah': surah,
              'ayah': ayah,
              'page': page,
              'juz': juz,
              'hizb': _estimatedHizbNumber(juz, page),
              'text_uthmani': text,
              'text_normalized': QuranTextNormalizer.normalize(text),
            },
            conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
          );
          ayahId++;
        }
      }

      batch.insert(
        'meta',
        {'key': _seedVersionKey, 'value': _seedVersion},
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
      );
      await batch.commit(noResult: true);
    });
  }

  static final Map<int, ({int startPage, int midpointPage})> _juzPageWindows =
      _buildJuzPageWindows();

  static Map<int, int> _buildPageLookup() {
    final pages = <int, int>{};
    for (var page = 1; page <= quran.totalPagesCount; page++) {
      final pageData = quran.getPageData(page);
      for (final rawSection in pageData) {
        final section = rawSection as Map;
        final surah = section['surah'] as int;
        final start = section['start'] as int;
        final end = section['end'] as int;
        for (var ayah = start; ayah <= end; ayah++) {
          pages[_positionKey(surah, ayah)] = page;
        }
      }
    }
    return pages;
  }

  static Map<int, int> _buildJuzLookup() {
    final juzLookup = <int, int>{};
    for (var juz = 1; juz <= quran.totalJuzCount; juz++) {
      final data = quran.getSurahAndVersesFromJuz(juz);
      for (final entry in data.entries) {
        final surah = entry.key;
        final start = entry.value.first;
        final end = entry.value.last;
        for (var ayah = start; ayah <= end; ayah++) {
          juzLookup[_positionKey(surah, ayah)] = juz;
        }
      }
    }
    return juzLookup;
  }

  static int _positionKey(int surah, int ayah) {
    return (surah * 1000) + ayah;
  }

  static Map<int, ({int startPage, int midpointPage})> _buildJuzPageWindows() {
    final windows = <int, ({int startPage, int midpointPage})>{};
    for (var juz = 1; juz <= quran.totalJuzCount; juz++) {
      final data = quran.getSurahAndVersesFromJuz(juz);
      final startSurah = data.keys.first;
      final endSurah = data.keys.last;
      final startAyah = data[startSurah]!.first;
      final endAyah = data[endSurah]!.last;
      final startPage = quran.getPageNumber(startSurah, startAyah);
      final endPage = quran.getPageNumber(endSurah, endAyah);
      final midpointPage = startPage + ((endPage - startPage) ~/ 2);
      windows[juz] = (startPage: startPage, midpointPage: midpointPage);
    }
    return windows;
  }

  static int _estimatedHizbNumber(int juz, int page) {
    final window = _juzPageWindows[juz];
    final hizbOffset = window != null && page > window.midpointPage ? 1 : 0;
    return (((juz - 1) * 2) + 1 + hizbOffset).clamp(1, 60).toInt();
  }
}

class QuranRepository {
  QuranRepository(this._database);

  static final QuranRepository instance = QuranRepository(QuranDatabase.instance);

  final QuranDatabase _database;

  Future<void> warmUp() {
    return _database.warmUp();
  }

  Future<List<SurahInfo>> getSurahs() async {
    final db = await _database.database;
    final rows = await db.query('surahs', orderBy: 'id ASC');
    return rows.map(SurahInfo.fromMap).toList(growable: false);
  }

  Future<Ayah?> getAyah({
    required int surah,
    required int ayah,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'ayahs',
      where: 'surah = ? AND ayah = ?',
      whereArgs: [surah, ayah],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return Ayah.fromMap(rows.first);
  }

  Future<List<Ayah>> getAyahsByPage(int page) {
    return _getAyahsByColumn(column: 'page', value: page);
  }

  Future<List<Ayah>> getAyahsBySurah(int surah) {
    return _getAyahsByColumn(column: 'surah', value: surah);
  }

  Future<List<Ayah>> getAyahsByJuz(int juz) {
    return _getAyahsByColumn(column: 'juz', value: juz);
  }

  Future<List<Ayah>> getAyahsByHizb(int hizb) {
    return _getAyahsByColumn(column: 'hizb', value: hizb);
  }

  Future<List<Ayah>> _getAyahsByColumn({
    required String column,
    required int value,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'ayahs',
      where: '$column = ?',
      whereArgs: [value],
      orderBy: 'id ASC',
    );
    return rows.map(Ayah.fromMap).toList(growable: false);
  }

  Future<List<Ayah>> searchAyahs(String query, {int limit = 200}) async {
    final normalizedQuery = QuranTextNormalizer.normalize(query);
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    final db = await _database.database;
    final rows = await db.query(
      'ayahs',
      where: 'text_normalized LIKE ?',
      whereArgs: ['%$normalizedQuery%'],
      orderBy: 'id ASC',
      limit: limit,
    );
    return rows.map(Ayah.fromMap).toList(growable: false);
  }

  Future<List<QuranBookmarkRecord>> loadBookmarks() async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
SELECT ayahs.*, bookmarks.created_at
FROM bookmarks
INNER JOIN ayahs ON ayahs.id = bookmarks.ayah_id
ORDER BY bookmarks.created_at DESC;
''');
    return rows.map(QuranBookmarkRecord.fromMap).toList(growable: false);
  }

  Future<bool> isBookmarked({
    required int surah,
    required int ayah,
  }) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
SELECT bookmarks.id
FROM bookmarks
INNER JOIN ayahs ON ayahs.id = bookmarks.ayah_id
WHERE ayahs.surah = ? AND ayahs.ayah = ?
LIMIT 1;
''',
      [surah, ayah],
    );
    return rows.isNotEmpty;
  }

  Future<void> addBookmark({
    required int surah,
    required int ayah,
    DateTime? createdAt,
  }) async {
    final verse = await getAyah(surah: surah, ayah: ayah);
    if (verse == null) {
      return;
    }

    final db = await _database.database;
    await db.insert(
      'bookmarks',
      {
        'ayah_id': verse.id,
        'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
      },
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<void> removeBookmark({
    required int surah,
    required int ayah,
  }) async {
    final db = await _database.database;
    await db.rawDelete(
      '''
DELETE FROM bookmarks
WHERE ayah_id IN (
  SELECT id FROM ayahs WHERE surah = ? AND ayah = ?
);
''',
      [surah, ayah],
    );
  }

  Future<String?> getCachedTafsir({
    required int surah,
    required int ayah,
  }) async {
    final verse = await getAyah(surah: surah, ayah: ayah);
    if (verse == null) {
      return null;
    }

    final db = await _database.database;
    final rows = await db.query(
      'tafsir',
      columns: const ['tafsir'],
      where: 'ayah_id = ?',
      whereArgs: [verse.id],
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return rows.first['tafsir'] as String;
  }

  Future<void> cacheTafsir({
    required int surah,
    required int ayah,
    required String tafsir,
  }) async {
    final verse = await getAyah(surah: surah, ayah: ayah);
    if (verse == null) {
      return;
    }

    final db = await _database.database;
    await db.insert(
      'tafsir',
      {'ayah_id': verse.id, 'tafsir': tafsir},
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }

  Future<String?> getCachedTranslation({
    required int surah,
    required int ayah,
  }) async {
    final verse = await getAyah(surah: surah, ayah: ayah);
    if (verse == null) return null;
    final db = await _database.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS translations (
        ayah_id INTEGER PRIMARY KEY,
        translation_en TEXT NOT NULL,
        FOREIGN KEY(ayah_id) REFERENCES ayahs(id) ON DELETE CASCADE
      );
    ''');
    final rows = await db.query(
      'translations',
      columns: const ['translation_en'],
      where: 'ayah_id = ?',
      whereArgs: [verse.id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['translation_en'] as String;
  }

  Future<void> cacheTranslation({
    required int surah,
    required int ayah,
    required String translation,
  }) async {
    final verse = await getAyah(surah: surah, ayah: ayah);
    if (verse == null) return;
    final db = await _database.database;
    await db.insert(
      'translations',
      {'ayah_id': verse.id, 'translation_en': translation},
      conflictAlgorithm: sqflite.ConflictAlgorithm.replace,
    );
  }
}
