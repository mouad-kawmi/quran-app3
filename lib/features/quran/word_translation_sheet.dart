import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/core/verse_translation_service.dart';

/// Bottom sheet that shows word-by-word context when a word is tapped.
/// Shows the full Arabic verse with the tapped word highlighted, plus
/// English translation (loaded offline-first from SQLite).
class WordTranslationSheet extends StatefulWidget {
  const WordTranslationSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.tappedWord,
    required this.onPlayAudio,
    required this.onShowTafsir,
  });

  final int surahNumber;
  final int ayahNumber;
  final String tappedWord;
  final VoidCallback onPlayAudio;
  final VoidCallback onShowTafsir;

  static Future<void> show(
    BuildContext context, {
    required int surahNumber,
    required int ayahNumber,
    required String tappedWord,
    required VoidCallback onPlayAudio,
    required VoidCallback onShowTafsir,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppTheme.isDark(context)
          ? AppTheme.darkSurfaceColor
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => WordTranslationSheet(
        surahNumber: surahNumber,
        ayahNumber: ayahNumber,
        tappedWord: tappedWord,
        onPlayAudio: onPlayAudio,
        onShowTafsir: onShowTafsir,
      ),
    );
  }

  @override
  State<WordTranslationSheet> createState() => _WordTranslationSheetState();
}

class _WordTranslationSheetState extends State<WordTranslationSheet> {
  String? _translation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final t = await VerseTranslationService.getTranslation(
      widget.surahNumber,
      widget.ayahNumber,
    );
    if (mounted) setState(() { _translation = t; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final verseText = quran.getVerse(widget.surahNumber, widget.ayahNumber);
    final surahName = quran.getSurahNameArabic(widget.surahNumber);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 20,
          right: 20,
          top: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '$surahName : ${widget.ayahNumber}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                // Highlighted word chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCFB53B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFCFB53B).withOpacity(0.5)),
                  ),
                  child: Text(
                    widget.tappedWord,
                    style: const TextStyle(
                      color: Color(0xFFCFB53B),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Arabic verse with highlight
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark
                    ? AppTheme.darkElevatedSurfaceColor
                    : const Color(0xFFF5F5F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _buildHighlightedVerse(verseText, dark),
            ),

            const SizedBox(height: 16),

            // Translation
            Row(
              children: [
                const Icon(Icons.translate_rounded,
                    size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 6),
                Text(
                  'الترجمة (Saheeh International)',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      _translation ?? '',
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.7,
                        color: dark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.volume_up_rounded,
                    label: 'تشغيل',
                    color: AppTheme.primaryColor,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onPlayAudio();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.menu_book_rounded,
                    label: 'التفسير',
                    color: const Color(0xFF00695C),
                    onTap: () {
                      Navigator.pop(context);
                      widget.onShowTafsir();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedVerse(String verseText, bool dark) {
    final words = verseText.split(' ');
    final spans = <InlineSpan>[];

    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      final isHighlighted = w == widget.tappedWord ||
          w.contains(widget.tappedWord) ||
          widget.tappedWord.contains(w);

      spans.add(
        TextSpan(
          text: i < words.length - 1 ? '$w ' : w,
          style: TextStyle(
            fontSize: 22,
            height: 2.0,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            color: isHighlighted
                ? const Color(0xFFCFB53B)
                : (dark ? Colors.white : Colors.black87),
            backgroundColor: isHighlighted
                ? const Color(0xFFCFB53B).withOpacity(0.12)
                : null,
          ),
        ),
      );
    }

    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
      text: TextSpan(children: spans),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
