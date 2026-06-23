import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/app_settings.dart';
import 'package:quran_app/core/quran_bookmark_service.dart';
import 'package:quran_app/core/reading_progress_service.dart';
import 'package:quran_app/core/tafsir_service.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/quran/ayah_share_screen.dart';
import 'package:quran_app/features/quran/qcf_mushaf_page.dart';
import 'package:quran_app/features/quran/quran_audio_player.dart';
import 'package:quran_app/features/quran/word_translation_sheet.dart';
import 'package:share_plus/share_plus.dart';

import 'package:quran_app/l10n/app_localizations.dart';
import 'package:quran_app/core/prayer_service.dart';

class QuranReaderScreen extends StatefulWidget {
  const QuranReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
    this.initialPage,
  });

  final int surahNumber;
  final int? initialAyah;
  final int? initialPage;

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  late PageController _pageController;
  late int _currentPage;
  int? _selectedSurah;
  int? _selectedAyah;
  Timer? _saveLastReadTimer;
  bool _isAudioSheetOpen = false;
  final QuranAudioController _audioController = QuranAudioController();

  @override
  void initState() {
    super.initState();
    _currentPage = _initialPage();
    _pageController = PageController(initialPage: _currentPage - 1);

    _audioController.addListener(_onAudioChanged);
    unawaited(_loadPageFontSafely(_currentPage));
    _scheduleNearbyPageFonts(_currentPage);
    unawaited(
      ReadingProgressService.saveLastRead(
        surah: widget.surahNumber,
        ayah: widget.initialAyah ?? _firstAyahInPage(_currentPage),
      ),
    );
  }

  int get _itemCount {
    if (_isTwoPageMode) return (quran.totalPagesCount / 2).ceil();
    return quran.totalPagesCount;
  }

  bool get _isTwoPageMode {
    final size = MediaQuery.of(context).size;
    return size.width > 600 && size.width > size.height;
  }

  int _initialPage() {
    final page =
        widget.initialPage ??
        quran.getPageNumber(widget.surahNumber, widget.initialAyah ?? 1);
    return page.clamp(1, quran.totalPagesCount);
  }

  @override
  void dispose() {
    _saveLastReadTimer?.cancel();
    _audioController.removeListener(_onAudioChanged);
    _audioController.dispose();
    _pageController.dispose();
    for (final controller in _oldControllers) {
      if (controller != _pageController) controller.dispose();
    }
    super.dispose();
  }

  int? _lastHighlightedSurah;
  int? _lastHighlightedAyah;

  void _onAudioChanged() {
    if (!mounted) return;

    final playingSurah = _audioController.currentPlayingSurah;
    final playingAyah = _audioController.currentPlayingVerse;

    if (playingSurah != null && playingAyah != null) {
      final targetPage = quran.getPageNumber(playingSurah, playingAyah);
      final isTwoPage = _isTwoPageMode;

      bool isTargetVisible = false;
      if (isTwoPage) {
        final currentSpreadRight = _currentPage % 2 != 0
            ? _currentPage
            : _currentPage - 1;
        final currentSpreadLeft = currentSpreadRight + 1;
        isTargetVisible =
            targetPage == currentSpreadRight || targetPage == currentSpreadLeft;
      } else {
        isTargetVisible = targetPage == _currentPage;
      }

      if (!isTargetVisible && _pageController.hasClients) {
        final targetIndex = isTwoPage ? (targetPage - 1) ~/ 2 : targetPage - 1;
        unawaited(
          _pageController.animateToPage(
            targetIndex,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          ),
        );
      }
    }

    if (_lastHighlightedSurah != playingSurah ||
        _lastHighlightedAyah != playingAyah) {
      _lastHighlightedSurah = playingSurah;
      _lastHighlightedAyah = playingAyah;
      setState(() {});
    }
  }

  void _onPageChanged(int index) {
    int page = _isTwoPageMode ? (index * 2) + 1 : index + 1;
    final position = _firstPositionInPage(page);

    _currentPage = page;

    _scheduleNearbyPageFonts(page);
    if (_isTwoPageMode && page + 1 <= quran.totalPagesCount) {
      _scheduleNearbyPageFonts(page + 1);
    }

    _queueLastReadSave(position.surah, position.ayah);
  }

  Future<void> _showAudioControls({
    required int surahNumber,
    int? startAyah,
  }) async {
    if (_isAudioSheetOpen || !mounted) return;

    _isAudioSheetOpen = true;
    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.18),
        isScrollControlled: true,
        builder: (context) {
          return QuranAudioPlayer(
            surahNumber: surahNumber,
            initialAyah: startAyah,
            controller: _audioController,
          );
        },
      );
    } finally {
      _isAudioSheetOpen = false;
    }
  }

  Future<void> _showVerseMenu(int surah, int ayah) async {
    setState(() {
      _selectedSurah = surah;
      _selectedAyah = ayah;
    });
    unawaited(ReadingProgressService.saveLastRead(surah: surah, ayah: ayah));

    final isBookmarked = await QuranBookmarkService.isBookmarked(surah, ayah);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.verseFromSurah(
                    ayah.toString(),
                    quran.getSurahNameArabic(surah),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const Icon(
                    Icons.play_circle_outline_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text(AppLocalizations.of(context)!.playFromHere),
                  onTap: () {
                    Navigator.pop(context);
                    _audioController.playVerseRequest(surah, ayah);
                    unawaited(
                      _showAudioControls(surahNumber: surah, startAyah: ayah),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    isBookmarked
                        ? Icons.bookmark_remove_rounded
                        : Icons.bookmark_add_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text(
                    isBookmarked
                        ? AppLocalizations.of(context)!.removeBookmark
                        : AppLocalizations.of(context)!.addBookmark,
                  ),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(context);
                    final added = await QuranBookmarkService.toggleBookmark(
                      surah: surah,
                      ayah: ayah,
                    );
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          added
                              ? AppLocalizations.of(context)!.bookmarkAdded
                              : AppLocalizations.of(context)!.bookmarkRemoved,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.menu_book_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text(AppLocalizations.of(context)!.easyTafsir),
                  onTap: () {
                    Navigator.pop(context);
                    _showTafsir(surah, ayah);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.translate_rounded,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text(AppLocalizations.of(context)!.translationEnglish),
                  onTap: () {
                    Navigator.pop(context);
                    WordTranslationSheet.show(
                      context,
                      surahNumber: surah,
                      ayahNumber: ayah,
                      tappedWord: '',
                      onPlayAudio: () {
                        _audioController.playVerseRequest(surah, ayah);
                        unawaited(
                          _showAudioControls(
                            surahNumber: surah,
                            startAyah: ayah,
                          ),
                        );
                      },
                      onShowTafsir: () => _showTafsir(surah, ayah),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.share_outlined,
                    color: AppTheme.primaryColor,
                  ),
                  title: Text(AppLocalizations.of(context)!.shareAyah),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AyahShareScreen(
                          surahNumber: surah,
                          ayahNumber: ayah,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTafsir(int surah, int ayah) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.tafsirOfAyah(ayah.toString()),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<String>(
            future: TafsirService.getVerseTafsir(surah, ayah),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quran.getVerse(surah, ayah),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.9,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      snapshot.data ??
                          AppLocalizations.of(context)!.tafsirNotAvailable,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(fontSize: 16, height: 1.8),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettingsMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                final settings = AppSettingsScope.watch(context);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.readingSettings,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SwitchListTile(
                      title: Text(AppLocalizations.of(context)!.useQcfFont),
                      subtitle: Text(AppLocalizations.of(context)!.qcfFontDesc),
                      activeColor: AppTheme.primaryColor,
                      value: settings.useQcfFont,
                      onChanged: (value) async {
                        await settings.setUseQcfFont(value);
                      },
                    ),
                    if (!settings.useQcfFont) ...[
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.normalFontSize(
                                settings.quranNormalFontSize.toInt().toString(),
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Slider(
                              value: settings.quranNormalFontSize,
                              min: 16,
                              max: 60,
                              activeColor: AppTheme.primaryColor,
                              onChanged: (value) async {
                                await settings.setQuranNormalFontSize(value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  bool? _wasTwoPageMode;

  final List<PageController> _oldControllers = [];

  @override
  Widget build(BuildContext context) {
    final pageColor = AppTheme.isDark(context)
        ? const Color(0xFF111914)
        : const Color(0xFFFFFDF2);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageColor,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isTwoPageMode =
                constraints.maxWidth > 600 &&
                constraints.maxWidth > constraints.maxHeight;

            if (_wasTwoPageMode != null && _wasTwoPageMode != isTwoPageMode) {
              _oldControllers.add(_pageController);
              
              final newIndex = isTwoPageMode ? (_currentPage - 1) ~/ 2 : _currentPage - 1;
              _pageController = PageController(initialPage: newIndex);
            } else if (_wasTwoPageMode == null) {
              _oldControllers.add(_pageController);

              final newIndex = isTwoPageMode ? (_currentPage - 1) ~/ 2 : _currentPage - 1;
              _pageController = PageController(initialPage: newIndex);
            }
            _wasTwoPageMode = isTwoPageMode;

            final itemCount = isTwoPageMode
                ? (quran.totalPagesCount / 2).ceil()
                : quran.totalPagesCount;

            return PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              allowImplicitScrolling: true,
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (isTwoPageMode) {
                  final rightPage = (index * 2) + 1;
                  final leftPage = rightPage + 1;

                  return Row(
                    children: [
                      Expanded(child: _buildPage(rightPage)),
                      Container(
                        width: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: leftPage <= quran.totalPagesCount
                            ? _buildPage(leftPage)
                            : const SizedBox(),
                      ),
                    ],
                  );
                } else {
                  return _buildPage(index + 1);
                }
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildPage(int pageNumber) {
    final position = _firstPositionInPage(pageNumber);
    final juz = quran.getJuzNumber(position.surah, position.ayah);

    return _QuranReaderPage(
      pageNumber: pageNumber,
      juzNumber: juz,
      pageSummary: _pageSummary(pageNumber),
      selectedSurah: _selectedSurah,
      selectedAyah: _selectedAyah,
      highlightedSurah: _audioController.currentPlayingSurah,
      highlightedAyah: _audioController.currentPlayingVerse,
      onVerseTap: _showVerseMenu,
      onSettingsTap: _showSettingsMenu,
    );
  }

  void _queueLastReadSave(int surah, int ayah) {
    _saveLastReadTimer?.cancel();
    _saveLastReadTimer = Timer(const Duration(milliseconds: 450), () {
      unawaited(ReadingProgressService.saveLastRead(surah: surah, ayah: ayah));
    });
  }

  void _scheduleNearbyPageFonts(int pageNumber) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      QcfMushafAssets.warmUpPageWindow(pageNumber, radius: 3);
    });
  }

  Future<void> _loadPageFontSafely(int pageNumber) async {
    try {
      await QcfMushafAssets.loadPageFont(pageNumber);
    } catch (_) {
      // The page widget falls back to regular Quran text if the QCF asset fails.
    }
  }
}

/// StatelessWidget — مابغاش StatefulWidget هنا لأن
/// الـ Parent (QuranReaderScreen) هو اللي يتحكم في الـ state.
/// AutomaticKeepAliveClientMixin مازال ياخدو من PageView مباشرة.
class _QuranReaderPage extends StatefulWidget {
  const _QuranReaderPage({
    required this.pageNumber,
    required this.juzNumber,
    required this.pageSummary,
    required this.selectedSurah,
    required this.selectedAyah,
    required this.highlightedSurah,
    required this.highlightedAyah,
    required this.onVerseTap,
    required this.onSettingsTap,
  });

  final int pageNumber;
  final int juzNumber;
  final String pageSummary;
  final int? selectedSurah;
  final int? selectedAyah;
  final int? highlightedSurah;
  final int? highlightedAyah;
  final MushafVerseTap onVerseTap;
  final VoidCallback onSettingsTap;

  @override
  State<_QuranReaderPage> createState() => _QuranReaderPageState();
}

/// wantKeepAlive = true ← كيحفظ الصفحة في الذاكرة وميعيدش بناءها
/// هذا هو الإصلاح الأكبر للأداء
class _QuranReaderPageState extends State<_QuranReaderPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RepaintBoundary(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
          child: QcfMushafPage(
            pageNumber: widget.pageNumber,
            juzNumber: widget.juzNumber,
            pageSummary: widget.pageSummary,
            selectedSurah: widget.selectedSurah,
            selectedAyah: widget.selectedAyah,
            highlightedSurah: widget.highlightedSurah,
            highlightedAyah: widget.highlightedAyah,
            onVerseTap: widget.onVerseTap,
            onSettingsTap: widget.onSettingsTap,
          ),
        ),
      ),
    );
  }
}

Future<T?> openQuranReader<T>(
  BuildContext context, {
  required int surahNumber,
  int? initialAyah,
  int? initialPage,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    MaterialPageRoute(
      builder: (context) => QuranReaderScreen(
        surahNumber: surahNumber,
        initialAyah: initialAyah,
        initialPage: initialPage,
      ),
    ),
  );
}

({int surah, int ayah}) _firstPositionInPage(int page) {
  final pageData = quran.getPageData(page);
  final first = pageData.first as Map;
  return (surah: first['surah'] as int, ayah: first['start'] as int);
}

int _firstAyahInPage(int page) {
  return _firstPositionInPage(page).ayah;
}

String _pageSummary(int page) {
  final pageData = quran.getPageData(page);
  final first = pageData.first as Map;
  final last = pageData.last as Map;
  final firstSurah = first['surah'] as int;
  final lastSurah = last['surah'] as int;

  if (firstSurah == lastSurah) {
    return quran.getSurahNameArabic(firstSurah);
  }

  return '${quran.getSurahNameArabic(firstSurah)} - ${quran.getSurahNameArabic(lastSurah)}';
}
