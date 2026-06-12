import 'package:flutter/material.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/bukhari/bukhari_hadiths_screen.dart';
import 'package:quran_app/features/bukhari/bukhari_models.dart';
import 'package:quran_app/features/bukhari/bukhari_service.dart';
import 'package:quran_app/features/bukhari/bukhari_search_delegate.dart';
import 'package:quran_app/l10n/app_localizations.dart';

class BukhariBooksScreen extends StatefulWidget {
  const BukhariBooksScreen({super.key});

  @override
  State<BukhariBooksScreen> createState() => _BukhariBooksScreenState();
}

class _BukhariBooksScreenState extends State<BukhariBooksScreen> {
  List<BukhariBook> _books = [];
  bool _isLoading = true;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final downloaded = await BukhariService().isDownloaded();
    if (mounted) {
      setState(() {
        _isDownloaded = downloaded;
        _isLoading = !downloaded;
      });
      if (downloaded) {
        _loadData();
      }
    }
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _error = null;
    });
    try {
      await BukhariService().downloadBukhariData((progress) {
        if (mounted) {
          setState(() {
            _downloadProgress = progress;
          });
        }
      });
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = true;
          _isLoading = true;
        });
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.bukhariDeleteTitle),
        content: Text(l10n.bukhariDeleteContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await BukhariService().deleteBukhariData();
      if (mounted) {
        setState(() {
          _isDownloaded = false;
          _books.clear();
        });
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final books = await BukhariService().loadBukhari();
      if (mounted) {
        setState(() {
          _books = books;
          _isLoading = false;
          if (books.isEmpty && mounted) {
            _error = AppLocalizations.of(context)!.bukhariNoBooksError;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.sahihBukhari,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
          centerTitle: true,
          actions: [
            if (_isDownloaded && !_isDownloading)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _confirmDelete,
              ),
            if (_isDownloaded && !_isDownloading)
              IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: BukhariSearchDelegate(hintText: l10n.bukhariSearchHint),
                  );
                },
              ),
          ],
        ),
        body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    if (_isDownloading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_download_rounded, size: 80, color: AppTheme.primaryColor.withOpacity(0.5)),
              const SizedBox(height: 24),
              Text(
                l10n.bukhariDownloading,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.bukhariDownloadWait,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                color: AppTheme.primaryColor,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              Text('${(_downloadProgress * 100).toStringAsFixed(1)}%'),
            ],
          ),
        ),
      );
    }

    if (!_isDownloaded) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_rounded, size: 80, color: AppTheme.primaryColor),
              const SizedBox(height: 24),
              Text(
                l10n.sahihBukhari,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.bukhariDescription,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 16),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _startDownload,
                icon: const Icon(Icons.download_rounded),
                label: Text(l10n.bukhariDownloadBtn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _error = null;
                  });
                  _checkStatus();
                },
                child: Text(l10n.retry),
              )
            ],
          ),
        ),
      );
    }

    return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _books.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final book = _books[index];
                  return Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BukhariHadithsScreen(book: book),
                          ),
                        );
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          book.id,
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        book.nameArabic,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        l10n.bukhariHadiths(book.hadiths.length),
                        style: TextStyle(
                          color: AppTheme.mutedTextColor(context),
                          fontSize: 13,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 16),
                    ),
                  );
                },
              );
  }
}
