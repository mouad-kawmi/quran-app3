import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/quran/quran_reader_screen.dart';

class QuranIndexScreen extends StatelessWidget {
  const QuranIndexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text(
              'فهرس القرآن',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'الأجزاء'),
                Tab(text: 'الأحزاب'),
                Tab(text: 'الصفحات'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _buildJuzList(context),
              _buildHizbList(context),
              _buildPageList(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJuzList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: quran.totalJuzCount,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final juz = index + 1;
        final data = quran.getSurahAndVersesFromJuz(juz);
        final startSurah = data.keys.first;
        final startAyah = data[startSurah]!.first;
        final page = quran.getPageNumber(startSurah, startAyah);

        return _buildIndexTile(
          context,
          icon: Icons.auto_stories_rounded,
          title: 'الجزء $juz',
          subtitle:
              'يبدأ من سورة ${quran.getSurahNameArabic(startSurah)} • الآية $startAyah • الصفحة $page',
          page: page,
          surah: startSurah,
          ayah: startAyah,
        );
      },
    );
  }

  Widget _buildHizbList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: 60,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final hizb = index + 1;
        final page = ((hizb - 1) * quran.totalPagesCount ~/ 60) + 1;
        final position = _firstPositionInPage(page);

        return _buildIndexTile(
          context,
          icon: Icons.layers_rounded,
          title: 'الحزب $hizb',
          subtitle:
              'من الصفحة $page • سورة ${quran.getSurahNameArabic(position.surah)}',
          page: page,
          surah: position.surah,
          ayah: position.ayah,
        );
      },
    );
  }

  Widget _buildPageList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: quran.totalPagesCount,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final page = index + 1;
        final position = _firstPositionInPage(page);
        final summary = _pageSummary(page);

        return _buildIndexTile(
          context,
          icon: Icons.article_rounded,
          title: 'الصفحة $page',
          subtitle: summary,
          page: page,
          surah: position.surah,
          ayah: position.ayah,
        );
      },
    );
  }

  Widget _buildIndexTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required int page,
    required int surah,
    required int ayah,
  }) {
    return InkWell(
      onTap: () {
        openQuranReader(
          context,
          surahNumber: surah,
          initialAyah: ayah,
          initialPage: page,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.elevatedSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.softBorderColor(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppTheme.primaryTextColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.mutedTextColor(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          ],
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

String _pageSummary(int page) {
  final pageData = quran.getPageData(page);
  final first = pageData.first as Map;
  final last = pageData.last as Map;
  final firstSurah = first['surah'] as int;
  final lastSurah = last['surah'] as int;

  if (firstSurah == lastSurah) {
    return 'سورة ${quran.getSurahNameArabic(firstSurah)}';
  }

  return 'من ${quran.getSurahNameArabic(firstSurah)} إلى ${quran.getSurahNameArabic(lastSurah)}';
}
