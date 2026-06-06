import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/quran_search_service.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/quran/quran_reader_screen.dart';

class QuranSearchScreen extends StatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  State<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends State<QuranSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<QuranSearchResult> _results = const [];
  String _query = '';
  bool _isSearching = false;
  int _searchSerial = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onQueryChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      final query = _searchController.text.trim();
      unawaited(_runSearch(query));
    });
  }

  Future<void> _runSearch(String query) async {
    final serial = ++_searchSerial;
    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _query = query;
        _results = const [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _query = query;
      _results = const [];
      _isSearching = true;
    });

    List<QuranSearchResult> results;
    try {
      results = await QuranSearchService.search(query);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'quran_app',
          context: ErrorDescription('searching Quran SQLite database'),
        ),
      );
      results = const [];
    }

    if (!mounted || serial != _searchSerial) return;
    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  void _openResult(QuranSearchResult result) {
    openQuranReader(
      context,
      surahNumber: result.surah,
      initialAyah: result.ayah,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: const Text('البحث في القرآن'), centerTitle: true),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'اكتب كلمة للبحث...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: _searchController.clear,
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: AppTheme.elevatedSurfaceColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _query.isEmpty ? 'النتائج' : '${_results.length} نتيجة',
                  style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_query.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_rounded,
        title: 'ابحث عن أي كلمة',
        subtitle: 'البحث يعمل دون إنترنت ويشمل آيات القرآن كاملة.',
      );
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return _buildEmptyState(
        icon: Icons.manage_search_rounded,
        title: 'عذراً، لم نجد نتائج',
        subtitle: 'حاول بكلمة أخرى أو اكتبها دون تشكيل.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildResultCard(_results[index]),
    );
  }

  Widget _buildResultCard(QuranSearchResult result) {
    return InkWell(
      onTap: () => _openResult(result),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.elevatedSurfaceColor(context),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppTheme.isDark(context) ? 0.14 : 0.04,
              ),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${quran.getSurahNameArabic(result.surah)} • ${result.ayah}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'ص ${result.page}',
                  style: TextStyle(
                    color: AppTheme.mutedTextColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              result.verse,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.amiri(
                fontSize: 20,
                height: 1.8,
                color: AppTheme.primaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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
}
