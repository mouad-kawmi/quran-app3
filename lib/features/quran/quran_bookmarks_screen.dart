import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/quran_bookmark_service.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/quran/quran_reader_screen.dart';

class QuranBookmarksScreen extends StatefulWidget {
  const QuranBookmarksScreen({super.key});

  @override
  State<QuranBookmarksScreen> createState() => _QuranBookmarksScreenState();
}

class _QuranBookmarksScreenState extends State<QuranBookmarksScreen> {
  List<QuranBookmark> _bookmarks = const [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await QuranBookmarkService.loadBookmarks();
    if (!mounted) return;

    setState(() {
      _bookmarks = bookmarks;
      _isLoading = false;
    });
  }

  Future<void> _removeBookmark(QuranBookmark bookmark) async {
    await QuranBookmarkService.removeBookmark(bookmark.surah, bookmark.ayah);
    await _loadBookmarks();
  }

  void _openBookmark(QuranBookmark bookmark) {
    openQuranReader(
      context,
      surahNumber: bookmark.surah,
      initialAyah: bookmark.ayah,
      initialPage: bookmark.page,
    ).then((_) => _loadBookmarks());
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'علامات القرآن',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _bookmarks.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: _loadBookmarks,
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _bookmarks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildBookmarkCard(_bookmarks[index]);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 56,
              color: AppTheme.primaryColor.withOpacity(0.4),
            ),
            const SizedBox(height: 14),
            const Text(
              'لا توجد علامات محفوظة بعد',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'ضغط على أي آية فالقارئ وزيدها للعلامات.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.mutedTextColor(context),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkCard(QuranBookmark bookmark) {
    return Dismissible(
      key: ValueKey(bookmark.key),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.red),
      ),
      onDismissed: (_) => _removeBookmark(bookmark),
      child: InkWell(
        onTap: () => _openBookmark(bookmark),
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
                  color: AppTheme.secondaryColor.withOpacity(0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bookmark_rounded,
                  color: AppTheme.secondaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سورة ${quran.getSurahNameArabic(bookmark.surah)}',
                      style: TextStyle(
                        color: AppTheme.primaryTextColor(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الآية ${bookmark.ayah} • الصفحة ${bookmark.page}',
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
      ),
    );
  }
}
