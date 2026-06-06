import 'package:flutter/material.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/bukhari/bukhari_models.dart';
import 'package:quran_app/features/bukhari/bukhari_service.dart';
import 'package:quran_app/features/bukhari/bukhari_hadiths_screen.dart';
import 'package:quran_app/features/bukhari/bukhari_search_delegate.dart';

class BukhariBooksScreen extends StatefulWidget {
  const BukhariBooksScreen({super.key});

  @override
  State<BukhariBooksScreen> createState() => _BukhariBooksScreenState();
}

class _BukhariBooksScreenState extends State<BukhariBooksScreen> {
  List<BukhariBook> _books = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final books = await BukhariService().loadBukhari();
      if (mounted) {
        setState(() {
          _books = books;
          _isLoading = false;
          if (books.isEmpty) {
            _error = "لم يتم العثور على أي كتب في قاعدة البيانات. تأكد من تحميل الملف.";
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'صحيح البخاري',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: BukhariSearchDelegate(),
                );
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
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
                        'الأحاديث: ${book.hadiths.length}',
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
              ),
      ),
    );
  }
}
