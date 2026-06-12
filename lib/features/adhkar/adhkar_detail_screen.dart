import 'package:flutter/material.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/adhkar/adhkar_data.dart';
import 'package:quran_app/l10n/app_localizations.dart';

class AdhkarDetailScreen extends StatefulWidget {
  final AdhkarModel category;
  const AdhkarDetailScreen({super.key, required this.category});

  @override
  State<AdhkarDetailScreen> createState() => _AdhkarDetailScreenState();
}

class _AdhkarDetailScreenState extends State<AdhkarDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.getLocalizedTitle(context)),
        actions: [
          IconButton(
            tooltip: l10n.resetAll,
            onPressed: _resetAll,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: widget.category.items.length,
        itemBuilder: (context, index) {
          final item = widget.category.items[index];
          return _buildDhikrCard(item, l10n);
        },
      ),
    );
  }

  Widget _buildDhikrCard(DhikrItem item, AppLocalizations l10n) {
    final bool isDone = item.currentCount >= item.count;

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      color: isDone
          ? Colors.green.withValues(alpha: AppTheme.isDark(context) ? 0.16 : 0.05)
          : AppTheme.elevatedSurfaceColor(context),
      child: InkWell(
        onTap: () => _advanceOrReset(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                item.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              if (item.reference != null)
                Text(
                  item.getLocalizedReference(context) ?? item.reference!,
                  style: TextStyle(
                    color: AppTheme.mutedTextColor(context),
                    fontSize: 12,
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isDone ? l10n.tapToRepeat : l10n.repetitions(item.count),
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: item.currentCount / item.count,
                          strokeWidth: 6,
                          backgroundColor: AppTheme.subtleSurfaceColor(context),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDone ? Colors.green : AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      Text(
                        '${item.currentCount}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (item.currentCount > 0) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => _resetItem(item),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(l10n.resetItem),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _advanceOrReset(DhikrItem item) {
    setState(() {
      if (item.currentCount >= item.count) {
        item.currentCount = 0;
      } else {
        item.currentCount++;
      }
    });
  }

  void _resetItem(DhikrItem item) {
    setState(() => item.currentCount = 0);
  }

  void _resetAll() {
    setState(() {
      for (final item in widget.category.items) {
        item.currentCount = 0;
      }
    });
  }
}
