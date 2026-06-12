import 'package:flutter/material.dart';
import 'package:quran_app/features/adhkar/adhkar_data.dart';
import 'package:quran_app/features/adhkar/adhkar_detail_screen.dart';
import 'package:quran_app/l10n/app_localizations.dart';

class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.adhkar,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: adhkarData.length,
        itemBuilder: (context, index) {
          final category = adhkarData[index];
          return _buildCategoryCard(context, category, index, l10n);
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    AdhkarModel category,
    int index,
    AppLocalizations l10n,
  ) {
    final colors = [Colors.teal, Colors.orange, Colors.blue, Colors.purple];
    final color = colors[index % colors.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdhkarDetailScreen(category: category),
            ),
          );
        },
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.wb_sunny_outlined, color: color),
        ),
        title: Text(
          category.getLocalizedTitle(context),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Text(l10n.dhikrCount(category.items.length)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      ),
    );
  }
}
