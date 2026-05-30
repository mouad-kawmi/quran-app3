import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/quran_bookmark_service.dart';
import 'package:quran_app/core/reading_progress_service.dart';
import 'package:quran_app/core/tafsir_service.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/quran/quran_audio_player.dart';
import 'package:share_plus/share_plus.dart';

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
  late final PageController _pageController;
  late int _currentPage;
  late int _audioSurah;
  int? _selectedSurah;
  int? _selectedAyah;
  final QuranAudioController _audioController = QuranAudioController();

  @override
  void initState() {
    super.initState();
    _currentPage = _initialPage();
    _audioSurah = widget.surahNumber;
    _selectedSurah = widget.initialAyah == null ? null : widget.surahNumber;
    _selectedAyah = widget.initialAyah;
    _pageController = PageController(initialPage: _currentPage - 1);

    _audioController.addListener(_onAudioChanged);
    unawaited(
      ReadingProgressService.saveLastRead(
        surah: widget.surahNumber,
        ayah: widget.initialAyah ?? _firstAyahInPage(_currentPage),
      ),
    );
  }

  int _initialPage() {
    final page =
        widget.initialPage ??
        quran.getPageNumber(widget.surahNumber, widget.initialAyah ?? 1);
    return page.clamp(1, quran.totalPagesCount);
  }

  @override
  void dispose() {
    _audioController.removeListener(_onAudioChanged);
    _audioController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onAudioChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onPageChanged(int index) {
    final page = index + 1;
    final position = _firstPositionInPage(page);

    setState(() {
      _currentPage = page;
      _audioSurah = position.surah;
    });

    unawaited(
      ReadingProgressService.saveLastRead(
        surah: position.surah,
        ayah: position.ayah,
      ),
    );
  }

  Future<void> _showVerseMenu(int surah, int ayah) async {
    setState(() {
      _selectedSurah = surah;
      _selectedAyah = ayah;
    });
    unawaited(ReadingProgressService.saveLastRead(surah: surah, ayah: ayah));

    final isBookmarked = await QuranBookmarkService.isBookmarked(surah, ayah);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الآية $ayah من سورة ${quran.getSurahNameArabic(surah)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: const Icon(
                      Icons.play_circle_outline,
                      color: AppTheme.primaryColor,
                    ),
                    title: const Text('تشغيل من هذه الآية'),
                    onTap: () {
                      Navigator.pop(context);
                      _audioController.playVerseRequest(surah, ayah);
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
                      isBookmarked ? 'حذف من العلامات' : 'حفظ علامة هنا',
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
                                ? 'تم حفظ العلامة.'
                                : 'تحيدات العلامة من هذا الموضع.',
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
                    title: const Text('التفسير الميسر'),
                    onTap: () {
                      Navigator.pop(context);
                      _showTafsir(surah, ayah);
                    },
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.share_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    title: const Text('مشاركة الآية'),
                    onTap: () {
                      Navigator.pop(context);
                      SharePlus.instance.share(
                        ShareParams(
                          text: '${quran.getVerse(surah, ayah)} [$surah:$ayah]',
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTafsir(int surah, int ayah) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text('تفسير الآية $ayah'),
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
                        style: GoogleFonts.amiri(
                          fontSize: 22,
                          height: 1.9,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        snapshot.data ?? 'التفسير غير متوفر لهذه الآية.',
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
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryColor,
          title: Text('الصفحة $_currentPage'),
          centerTitle: true,
        ),
        body: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemCount: quran.totalPagesCount,
          itemBuilder: (context, index) {
            return _buildPage(index + 1);
          },
        ),
        bottomNavigationBar: QuranAudioPlayer(
          surahNumber: _audioSurah,
          controller: _audioController,
        ),
      ),
    );
  }

  Widget _buildPage(int pageNumber) {
    final position = _firstPositionInPage(pageNumber);
    final juz = quran.getJuzNumber(position.surah, position.ayah);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: AppTheme.elevatedSurfaceColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.softBorderColor(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(AppTheme.isDark(context) ? 0.2 : 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'جزء $juz',
                      style: TextStyle(
                        color: AppTheme.mutedTextColor(context),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _pageSummary(pageNumber),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'صفحة $pageNumber',
                      style: TextStyle(
                        color: AppTheme.mutedTextColor(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                _buildPageText(pageNumber),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageText(int pageNumber) {
    final spans = <InlineSpan>[];
    final pageData = quran.getPageData(pageNumber);

    for (final section in pageData) {
      final data = section as Map;
      final surah = data['surah'] as int;
      final start = data['start'] as int;
      final end = data['end'] as int;

      if (start == 1) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: _SurahHeader(name: quran.getSurahNameArabic(surah)),
          ),
        );
      }

      for (var verse = start; verse <= end; verse++) {
        final isHighlighted =
            _audioController.currentPlayingSurah == surah &&
            _audioController.currentPlayingVerse == verse;
        final isSelected = _selectedSurah == surah && _selectedAyah == verse;

        spans.add(
          TextSpan(
            text:
                '${quran.getVerse(surah, verse)} ${quran.getVerseEndSymbol(verse)} ',
            style: GoogleFonts.amiri(
              fontSize: 23,
              height: 2.15,
              backgroundColor: isHighlighted || isSelected
                  ? AppTheme.primaryColor.withOpacity(0.14)
                  : null,
              color: isHighlighted || isSelected
                  ? AppTheme.primaryColor
                  : AppTheme.primaryTextColor(context),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () => _showVerseMenu(surah, verse),
          ),
        );
      }
    }

    return RichText(
      textAlign: TextAlign.justify,
      text: TextSpan(
        children: spans,
        style: TextStyle(color: AppTheme.primaryTextColor(context)),
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
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
