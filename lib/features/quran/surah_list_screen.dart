import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/quran/downloaded_audio_screen.dart';
import 'package:quran_app/features/quran/quran_bookmarks_screen.dart';
import 'package:quran_app/features/quran/quran_index_screen.dart';
import 'package:quran_app/features/quran/quran_reader_screen.dart';
import 'package:quran_app/features/quran/quran_search_screen.dart';
import 'package:quran_app/l10n/app_localizations.dart';

class SurahListScreen extends StatelessWidget {
  const SurahListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.quranSurahs,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: l10n.downloadedAudioTooltip,
            icon: const Icon(Icons.library_music_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DownloadedAudioScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: l10n.indexTooltip,
            icon: const Icon(Icons.view_list_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuranIndexScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: l10n.bookmarksTooltip,
            icon: const Icon(Icons.bookmark_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuranBookmarksScreen(),
                ),
              );
            },
          ),
          IconButton(
            tooltip: l10n.searchTooltip,
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuranSearchScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 114,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final surahNumber = index + 1;
          return _buildSurahCard(context, surahNumber, l10n, isAr);
        },
      ),
    );
  }

  Widget _buildSurahCard(BuildContext context, int surahNumber, AppLocalizations l10n, bool isAr) {
    return InkWell(
      onTap: () {
        openQuranReader(context, surahNumber: surahNumber);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.elevatedSurfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.softBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: AppTheme.isDark(context) ? 0.14 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                surahNumber.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quran.getSurahNameArabic(surahNumber),
                    style: TextStyle(
                      color: AppTheme.primaryTextColor(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${quran.getPlaceOfRevelation(surahNumber)} • ${l10n.ayahCount(quran.getVerseCount(surahNumber))}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.mutedTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            if (!isAr)
              Text(
                quran.getSurahName(surahNumber),
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
