import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' show min, max;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/app_settings.dart';
import 'package:quran_app/core/tajweed_colorizer.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/quran/word_translation_sheet.dart';

typedef MushafVerseTap = void Function(int surah, int ayah);

class QcfMushafPage extends StatefulWidget {
  const QcfMushafPage({
    super.key,
    required this.pageNumber,
    this.juzNumber,
    this.pageSummary,
    this.selectedSurah,
    this.selectedAyah,
    this.highlightedSurah,
    this.highlightedAyah,
    this.onVerseTap,
    this.onSettingsTap,
    this.bottomPadding = 18,
  });

  final int pageNumber;
  final int? juzNumber;
  final String? pageSummary;
  final int? selectedSurah;
  final int? selectedAyah;
  final int? highlightedSurah;
  final int? highlightedAyah;
  final MushafVerseTap? onVerseTap;
  final VoidCallback? onSettingsTap;
  final double bottomPadding;

  @override
  State<QcfMushafPage> createState() => _QcfMushafPageState();
}

class _QcfMushafPageState extends State<QcfMushafPage> {
  Qcf4PageData? _pageData;

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  @override
  void didUpdateWidget(covariant QcfMushafPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageNumber != widget.pageNumber) {
      _pageData = null;
      _loadPageData();
    }
  }

  void _loadPageData() {
    final pageNumber = widget.pageNumber;
    unawaited(
      QcfMushafAssets.loadPage(pageNumber)
          .then((data) {
            if (mounted && widget.pageNumber == pageNumber) {
              setState(() => _pageData = data);
            }
          })
          .catchError((_) {
            // Fallback: _pageData yab9a null w _FallbackPageText katwerra
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final pageColor = dark ? const Color(0xFF111914) : const Color(0xFFFFFDF2);
    final borderColor =
        dark ? const Color(0xFF31483E) : const Color(0xFFE2D3A8);

    final settings = AppSettingsScope.watch(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: pageColor,
      ),
      child: Column(
        children: [
          _MushafPageTopBar(
            pageNumber: widget.pageNumber,
            juzNumber: widget.juzNumber,
            pageSummary: widget.pageSummary,
            onSettingsTap: widget.onSettingsTap,
          ),
          Expanded(
            child: (!settings.useQcfFont || _pageData == null)
                ? _FallbackPageText(
                    pageNumber: widget.pageNumber,
                    fontSize: settings.quranNormalFontSize,
                    onVerseTap: widget.onVerseTap,
                    selectedSurah: widget.selectedSurah,
                    selectedAyah: widget.selectedAyah,
                    highlightedSurah: widget.highlightedSurah,
                    highlightedAyah: widget.highlightedAyah,
                  )
                : RepaintBoundary(
                    child: _buildPageBody(_pageData!),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageBody(Qcf4PageData pageData) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const kNaturalWidth = 370.0;
        // Average line height at scale 1.0: 27px font × 1.3 lineHeight
        const kBaseLineHeight = 35.1;

        final numLines = max(1, pageData.lines.length);
        final kNaturalHeight = numLines * kBaseLineHeight;

        final scaleByWidth = constraints.maxWidth / kNaturalWidth;
        final scaleByHeight = constraints.maxHeight / kNaturalHeight;
        // Use the limiting dimension so we never overflow vertically
        final scaleFactor = min(scaleByWidth, scaleByHeight).clamp(0.8, 3.0);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            10,
            _topPaddingForPage(pageData.page),
            10,
            widget.bottomPadding,
          ),
          child: _Qcf4PageLines(
            pageData: pageData,
            scaleFactor: scaleFactor,
            selectedSurah: widget.selectedSurah,
            selectedAyah: widget.selectedAyah,
            highlightedSurah: widget.highlightedSurah,
            highlightedAyah: widget.highlightedAyah,
            onVerseTap: widget.onVerseTap,
          ),
        );
      },
    );
  }
}

/// Cache manager dyal QCF4 assets b LRU eviction.
/// Hadi khatira bach memory ma t3omerch b 604 pages.
class QcfMushafAssets {
  static const String pagesPath = 'quran-qcf4-main/pages';
  static const String fontsPath = 'quran-qcf4-main/fonts';
  static const String bismillahFamily = 'QCF4_QBSML';
  static const Duration _preloadPause = Duration(milliseconds: 35);
  static const int _maxCachedPages = 20; // Max pages f memory

  static final Map<int, Future<Qcf4PageData>> _loadingPages = {};
  static final Map<int, Qcf4PageData> _pageDataCache = {};
  static final Queue<int> _lruQueue = Queue<int>();
  static final Set<int> _readyPages = {};
  static final Map<String, Future<void>> _loadedFonts = {};
  static final Set<String> _readyFonts = {};
  static final List<int> _preloadQueue = <int>[];
  static final Set<int> _queuedPages = {};

  static bool _isPreloadWorkerRunning = false;

  static bool isPageFontLoaded(int pageNumber) =>
      _readyPages.contains(pageNumber);

  static void startAppFontWarmUp({int firstPage = 1}) {
    warmUpPageWindow(firstPage, radius: 5);
  }

  static void warmUpPageWindow(int pageNumber, {int radius = 5}) {
    final page = pageNumber.clamp(1, quran.totalPagesCount);
    _queuePagePreload(_orderedNearbyPages(page, radius: radius));
  }

  static Future<void> loadPageFont(int pageNumber) => loadPage(pageNumber);

  static Future<Qcf4PageData> loadPage(int pageNumber) {
    RangeError.checkValueInInterval(pageNumber, 1, quran.totalPagesCount);

    // 1. Check memory cache (LRU)
    final cached = _pageDataCache[pageNumber];
    if (cached != null) {
      _promoteLru(pageNumber);
      return Future.value(cached);
    }

    // 2. Check if already loading
    final existing = _loadingPages[pageNumber];
    if (existing != null) return existing;

    // 3. Load new page
    final future = _loadPageWithFonts(pageNumber);
    _loadingPages[pageNumber] = future;
    return future;
  }

  static Future<Qcf4PageData> _loadPageWithFonts(int pageNumber) async {
    try {
      final pageData = await _loadPageData(pageNumber);
      await Future.wait<void>(
        pageData.fontFamilies.map(loadFontFamily),
        eagerError: true,
      );
      _readyPages.add(pageNumber);
      _addToCache(pageNumber, pageData);
      return pageData;
    } catch (_) {
      _loadingPages.remove(pageNumber);
      rethrow;
    }
  }

  static Future<Qcf4PageData> _loadPageData(int pageNumber) async {
    final rawJson = await rootBundle.loadString(pageAssetForPage(pageNumber));
    return compute(_parsePageJson, rawJson);
  }

  static Qcf4PageData _parsePageJson(String rawJson) {
    final json = jsonDecode(rawJson) as Map<String, dynamic>;
    return Qcf4PageData.fromJson(json);
  }

  static Future<void> loadFontFamily(String family) {
    if (_readyFonts.contains(family)) {
      return Future<void>.value();
    }

    return _loadedFonts.putIfAbsent(family, () async {
      final loader = FontLoader(family)
        ..addFont(rootBundle.load(fontAssetForFamily(family)));
      await loader.load();
      _readyFonts.add(family);
    });
  }

  static String pageAssetForPage(int pageNumber) {
    return '$pagesPath/${pageNumber.toString().padLeft(3, '0')}.json';
  }

  static String fontAssetForFamily(String family) {
    if (family == bismillahFamily) {
      return '$fontsPath/$family.ttf';
    }
    return '$fontsPath/${family}_W.ttf';
  }

  static Iterable<int> _orderedNearbyPages(
    int center, {
    required int radius,
  }) sync* {
    final maxDistance = radius.clamp(0, quran.totalPagesCount);
    for (var distance = 1; distance <= maxDistance; distance++) {
      final nextPage = center + distance;
      final previousPage = center - distance;

      if (nextPage <= quran.totalPagesCount) yield nextPage;
      if (previousPage >= 1) yield previousPage;
    }
  }

  static void _queuePagePreload(Iterable<int> pages) {
    _preloadQueue.clear();
    _queuedPages.clear();

    for (final page in pages) {
      if (_readyPages.contains(page) || _loadingPages.containsKey(page)) {
        continue;
      }
      if (_queuedPages.add(page)) {
        _preloadQueue.add(page);
      }
    }
    _startPreloadWorker();
  }

  static void _startPreloadWorker() {
    if (_isPreloadWorkerRunning) return;
    _isPreloadWorkerRunning = true;
    unawaited(_runPreloadQueue());
  }

  static Future<void> _runPreloadQueue() async {
    while (_preloadQueue.isNotEmpty) {
      final page = _preloadQueue.removeAt(0);
      _queuedPages.remove(page);

      try {
        await loadPage(page);
      } catch (_) {
        // Silently ignore preload failures
      }
      await Future<void>.delayed(_preloadPause);
    }

    _isPreloadWorkerRunning = false;
    if (_preloadQueue.isNotEmpty) _startPreloadWorker();
  }

  // LRU Cache helpers
  static void _promoteLru(int page) {
    _lruQueue.remove(page);
    _lruQueue.addFirst(page);
  }

  static void _addToCache(int page, Qcf4PageData data) {
    if (_pageDataCache.containsKey(page)) {
      _promoteLru(page);
      return;
    }

    // Evict oldest if full
    while (_pageDataCache.length >= _maxCachedPages && _lruQueue.isNotEmpty) {
      final oldest = _lruQueue.removeLast();
      _pageDataCache.remove(oldest);
      _loadingPages.remove(oldest); // Allow future reload if needed
      _readyPages.remove(oldest);
    }

    _pageDataCache[page] = data;
    _lruQueue.addFirst(page);
  }

  /// Nqass l'memory ila l'user bda yscrolli b3id (optional)
  static void clearCache() {
    _pageDataCache.clear();
    _lruQueue.clear();
    _loadingPages.clear();
    _readyPages.clear();
    _preloadQueue.clear();
    _queuedPages.clear();
  }
}

class Qcf4PageData {
  const Qcf4PageData({
    required this.page,
    required this.font,
    required this.lines,
  });

  final int page;
  final String font;
  final List<Qcf4LineData> lines;

  Set<String> get fontFamilies {
    final families = <String>{font, QcfMushafAssets.bismillahFamily};
    for (final line in lines) {
      for (final word in line.words) {
        if (word.font.isNotEmpty) families.add(word.font);
      }
    }
    return families;
  }

  factory Qcf4PageData.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List<dynamic>? ?? const [];
    return Qcf4PageData(
      page: json['page'] as int,
      font: json['font'] as String,
      lines: rawLines
          .map((line) => Qcf4LineData.fromJson(line as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class Qcf4LineData {
  const Qcf4LineData({required this.line, required this.words});

  final int line;
  final List<Qcf4WordData> words;

  factory Qcf4LineData.fromJson(Map<String, dynamic> json) {
    final rawWords = json['words'] as List<dynamic>? ?? const [];
    return Qcf4LineData(
      line: json['line'] as int,
      words: rawWords
          .map((word) => Qcf4WordData.fromJson(word as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class Qcf4WordData {
  const Qcf4WordData({
    required this.char,
    required this.font,
    required this.type,
    required this.verseKey,
  });

  final String char;
  final String font;
  final String type;
  final String? verseKey;

  ({int surah, int ayah})? get versePosition {
    final key = verseKey;
    if (key == null) return null;

    final parts = key.split(':');
    if (parts.length != 2) return null;

    final surah = int.tryParse(parts[0]);
    final ayah = int.tryParse(parts[1]);
    if (surah == null || ayah == null) return null;

    return (surah: surah, ayah: ayah);
  }

  factory Qcf4WordData.fromJson(Map<String, dynamic> json) {
    return Qcf4WordData(
      char: json['char'] as String? ?? '',
      font: json['font'] as String? ?? '',
      type: json['type'] as String? ?? 'word',
      verseKey: json['verse_key'] as String?,
    );
  }
}

class _Qcf4PageLines extends StatelessWidget {
  const _Qcf4PageLines({
    required this.pageData,
    required this.scaleFactor,
    required this.selectedSurah,
    required this.selectedAyah,
    required this.highlightedSurah,
    required this.highlightedAyah,
    required this.onVerseTap,
  });

  final Qcf4PageData pageData;
  final double scaleFactor;
  final int? selectedSurah;
  final int? selectedAyah;
  final int? highlightedSurah;
  final int? highlightedAyah;
  final MushafVerseTap? onVerseTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final lines = pageData.lines
        .map(
          (line) => _Qcf4Line(
            pageNumber: pageData.page,
            line: line,
            isDark: isDark,
            scaleFactor: scaleFactor,
            selectedSurah: selectedSurah,
            selectedAyah: selectedAyah,
            highlightedSurah: highlightedSurah,
            highlightedAyah: highlightedAyah,
            onVerseTap: onVerseTap,
          ),
        )
        .toList(growable: false);

    return Column(
      mainAxisAlignment: _lineAlignmentForPage(pageData),
      children: lines,
    );
  }
}

class _Qcf4Line extends StatelessWidget {
  const _Qcf4Line({
    required this.pageNumber,
    required this.line,
    required this.isDark,
    required this.scaleFactor,
    required this.selectedSurah,
    required this.selectedAyah,
    required this.highlightedSurah,
    required this.highlightedAyah,
    required this.onVerseTap,
  });

  final int pageNumber;
  final Qcf4LineData line;
  final bool isDark;
  final double scaleFactor;
  final int? selectedSurah;
  final int? selectedAyah;
  final int? highlightedSurah;
  final int? highlightedAyah;
  final MushafVerseTap? onVerseTap;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    for (final word in line.words.reversed) {
      final position = word.versePosition;
      final isSelected = position != null &&
          selectedSurah == position.surah &&
          selectedAyah == position.ayah;
      final isHighlighted = position != null &&
          highlightedSurah == position.surah &&
          highlightedAyah == position.ayah;
      final isActive = isSelected || isHighlighted;
      final isDecoration =
          word.type == 'surah_header' || word.type == 'bismillah';

      TapGestureRecognizer? recognizer;
      if (position != null && onVerseTap != null) {
        recognizer = TapGestureRecognizer()
          ..onTap = () => onVerseTap?.call(position.surah, position.ayah);
      }

      spans.add(
        TextSpan(
          text: word.char,
          style: TextStyle(
            color: _wordColorFast(word, isDark: isDark, isActive: isActive),
            backgroundColor: isActive
                ? AppTheme.primaryColor.withValues(alpha: 0.14)
                : null,
            fontFamily: word.font,
            fontSize: _fontSizeForWord(pageNumber: pageNumber, word: word) * scaleFactor,
            height: isDecoration ? 1.1 : 1.3,
            letterSpacing: 0,
            wordSpacing: 0,
          ),
          recognizer: recognizer,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: RichText(
          textDirection: TextDirection.rtl,
          text: TextSpan(children: spans),
        ),
      ),
    );
  }
}

class _MushafPageTopBar extends StatelessWidget {
  const _MushafPageTopBar({
    required this.pageNumber,
    required this.juzNumber,
    required this.pageSummary,
    this.onSettingsTap,
  });

  final int pageNumber;
  final int? juzNumber;
  final String? pageSummary;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = AppTheme.isDark(context)
        ? const Color(0xFF31483E)
        : const Color(0xFFE2D3A8);

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Row(
              children: [
                if (onSettingsTap != null)
                  Expanded(
                    child: IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 20),
                      color: AppTheme.primaryColor,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onSettingsTap,
                    ),
                  ),
                Expanded(
                  flex: 3,
                  child: Text(
                    juzNumber == null ? '' : '\u062c\u0632\u0621 $juzNumber',
                    style: _topBarStyle(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              pageSummary ?? '',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: _topBarStyle(context).copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 72,
            child: Text(
              '\u0635\u0641\u062d\u0629 $pageNumber',
              textAlign: TextAlign.end,
              style: _topBarStyle(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _FallbackPageText extends StatelessWidget {
  const _FallbackPageText({
    required this.pageNumber, 
    required this.fontSize,
    this.onVerseTap,
    this.selectedSurah,
    this.selectedAyah,
    this.highlightedSurah,
    this.highlightedAyah,
  });

  final int pageNumber;
  final double fontSize;
  final MushafVerseTap? onVerseTap;
  final int? selectedSurah;
  final int? selectedAyah;
  final int? highlightedSurah;
  final int? highlightedAyah;

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.watch(context);
    final spans = <InlineSpan>[];
    final pageData = quran.getPageData(pageNumber);

    for (final rawSection in pageData) {
      final section = rawSection as Map;
      final surah = section['surah'] as int;
      final start = section['start'] as int;
      final end = section['end'] as int;

      if (start == 1) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _FallbackSurahHeader(surah: surah),
          ),
        );
      }

      for (var ayah = start; ayah <= end; ayah++) {
        final isSelected = selectedSurah == surah && selectedAyah == ayah;
        final isHighlighted = highlightedSurah == surah && highlightedAyah == ayah;
        final isActive = isSelected || isHighlighted;
        final isColorized = settings.useTajweedColors;

        final rawAyahText = '${quran.getVerse(surah, ayah)} ${quran.getVerseEndSymbol(ayah)} ';

        final baseStyle = TextStyle(
          color: isActive
              ? AppTheme.primaryColor
              : AppTheme.isDark(context)
                  ? const Color(0xFFEDE7D0)
                  : _mushafInkColor,
          backgroundColor: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.14)
              : null,
          fontSize: fontSize,
          height: 2.2,
        );

        final recognizer = TapGestureRecognizer()..onTap = () {
          onVerseTap?.call(surah, ayah);
        };

        spans.add(
          TextSpan(
            children: isColorized 
                ? TajweedColorizer.colorize(rawAyahText, baseStyle, recognizer: recognizer)
                : [TextSpan(text: rawAyahText, style: baseStyle, recognizer: recognizer)],
            recognizer: recognizer,
          ),
        );
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: RichText(
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.justify,
        locale: const Locale('ar'),
        text: TextSpan(children: spans),
      ),
    );
  }
}

class _FallbackSurahHeader extends StatelessWidget {
  const _FallbackSurahHeader({required this.surah});

  final int surah;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        quran.getSurahNameArabic(surah),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

TextStyle _topBarStyle(BuildContext context) {
  return TextStyle(
    color: AppTheme.mutedTextColor(context),
    fontSize: 12,
    height: 1,
  );
}

const Color _mushafInkColor = Color(0xFF1B160D);


MainAxisAlignment _lineAlignmentForPage(Qcf4PageData pageData) {
  if (pageData.page == 1) return MainAxisAlignment.center;
  if (pageData.lines.length >= 12) return MainAxisAlignment.spaceBetween;
  return MainAxisAlignment.start;
}

/// Ù†Ø³Ø®Ø© Ø£Ø³Ø±Ø¹ Ù…Ù† _wordColor â€” Ø¨Ø¯ÙˆÙ† context
Color _wordColorFast(
  Qcf4WordData word, {
  required bool isDark,
  required bool isActive,
}) {
  if (isActive) return AppTheme.primaryColor;
  if (word.type == 'surah_header' || word.type == 'end') {
    return AppTheme.primaryColor;
  }
  return isDark ? const Color(0xFFEDE7D0) : _mushafInkColor;
}



double _topPaddingForPage(int pageNumber) {
  if (pageNumber == 1 || pageNumber == 2) return 28;
  return 12;
}

double _fontSizeForWord({
  required int pageNumber,
  required Qcf4WordData word,
}) {
  if (word.type == 'surah_header') return 34;
  if (word.type == 'bismillah') return 32;
  if (pageNumber == 1 || pageNumber == 2) return 31;
  return 27;
}

