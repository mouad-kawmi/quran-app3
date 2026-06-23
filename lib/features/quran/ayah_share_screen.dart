import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:quran_app/l10n/app_localizations.dart';

class AyahShareScreen extends StatefulWidget {
  const AyahShareScreen({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
  });

  final int surahNumber;
  final int ayahNumber;

  @override
  State<AyahShareScreen> createState() => _AyahShareScreenState();
}

class _AyahShareScreenState extends State<AyahShareScreen> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _shareImage() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // Capture with high resolution
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/ayah_${widget.surahNumber}_${widget.ayahNumber}.png').create();
      await file.writeAsBytes(pngBytes);

      // ignore: deprecated_member_use
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'تلاوة مباركة من سورة ${quran.getSurahNameArabic(widget.surahNumber)}.\nتطبيق نور القرآن.',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء محاولة المشاركة.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _shareText() {
    SharePlus.instance.share(
      ShareParams(
        text: '${quran.getVerse(widget.surahNumber, widget.ayahNumber)}\n[${quran.getSurahNameArabic(widget.surahNumber)}: ${widget.ayahNumber}]',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.shareAyah, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _buildShareCard(),
                ),
              ),
            ),
          ),
          _buildActionButtons(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildShareCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF14201A), // Deep dark green/islamic color
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFCFB53B).withOpacity(0.7), // Arabic gold
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Background ornament subtle layer
          Positioned(
            top: -40,
            right: -40,
            child: Icon(
              Icons.mosque_rounded,
              size: 200,
              color: const Color(0xFFCFB53B).withOpacity(0.04),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Icon(
              Icons.book_rounded,
              size: 150,
              color: const Color(0xFFCFB53B).withOpacity(0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header (Bismillah or just decoration)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCFB53B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFCFB53B).withOpacity(0.5)),
                  ),
                  child: Text(
                    'سورة ${quran.getSurahNameArabic(widget.surahNumber)}',
                    style: const TextStyle(
                      color: Color(0xFFCFB53B),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Ayah Text
                Text(
                  '${quran.getVerse(widget.surahNumber, widget.ayahNumber)} ${quran.getVerseEndSymbol(widget.ayahNumber)}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    color: const Color(0xFFF9F6EB), // Off-white/cream
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    height: 2.2,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.mosque_rounded, color: Color(0xFFCFB53B), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'نور القرآن',
                      style: TextStyle(
                        color: const Color(0xFFCFB53B).withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _shareText,
              icon: const Icon(Icons.text_fields_rounded),
              label: const Text('كنص'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : _shareImage,
              icon: _isExporting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.image_rounded),
              label: Text(_isExporting ? 'جاري التحضير...' : 'مشاركة كصورة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
