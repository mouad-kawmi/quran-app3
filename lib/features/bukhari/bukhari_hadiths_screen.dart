import 'package:flutter/material.dart';
import 'package:quran_app/core/app_settings.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/bukhari/bukhari_models.dart';
import 'package:quran_app/features/bukhari/bukhari_search_delegate.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class BukhariHadithsScreen extends StatelessWidget {
  final BukhariBook book;

  const BukhariHadithsScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.watch(context);
    final fontScale = settings.fontScale;

    return Scaffold(
      appBar: AppBar(
          title: Text(
            book.nameArabic,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: BukhariSearchDelegate(hintText: AppLocalizations.of(context)!.bukhariSearchHint),
                );
              },
            ),
          ],
        ),
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: book.hadiths.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final hadith = book.hadiths[index];
            return _buildHadithCard(context, hadith, fontScale);
          },
        ),
    );
  }

  Widget _buildHadithCard(
      BuildContext context, BukhariHadith hadith, double fontScale) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.hadithNumber(hadith.hadithNumber),
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 20),
                  color: AppTheme.primaryColor,
                  onPressed: () {
                    SharePlus.instance.share(ShareParams(
                        text:
                            '${AppLocalizations.of(context)!.sahihBukhari}\n${book.nameArabic}\n\n${hadith.text}\n\n(${AppLocalizations.of(context)!.hadithNumber(hadith.hadithNumber)})'));
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hadith.text,
              style: TextStyle(
                fontSize: 18 * fontScale,
                height: 1.8,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}
