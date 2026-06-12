import 'package:flutter/material.dart';
import 'package:quran_app/core/app_settings.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/bukhari/bukhari_models.dart';
import 'package:quran_app/features/bukhari/bukhari_service.dart';
import 'package:quran_app/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

class BukhariSearchDelegate extends SearchDelegate {
  BukhariSearchDelegate({required String hintText})
      : super(searchFieldLabel: hintText);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(
            color: AppTheme.isDark(context)
                ? Colors.white54
                : Colors.black54),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded,
                size: 80, color: AppTheme.primaryColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.bukhariSearchEmptyText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final results = BukhariService().searchHadith(query);

    if (results.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.bukhariSearchNoResults,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final hadith = results[index];
        final book = BukhariService().getBookById(hadith.referenceBook);
        return _buildSearchCard(context, hadith, book);
      },
    );
  }

  Widget _buildSearchCard(
      BuildContext context, BukhariHadith hadith, BukhariBook? book) {
    final settings = AppSettingsScope.watch(context);
    final l10n = AppLocalizations.of(context)!;
    final fontScale = settings.fontScale;
    final bookName = book?.nameArabic ?? l10n.unknownBook;

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
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${l10n.hadithNumber(hadith.hadithNumber)} - $bookName',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.share_rounded, size: 20),
                  color: AppTheme.primaryColor,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    SharePlus.instance.share(ShareParams(
                        text:
                            '${l10n.sahihBukhari}\n$bookName\n\n${hadith.text}\n\n(${l10n.hadithNumber(hadith.hadithNumber)})'));
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
