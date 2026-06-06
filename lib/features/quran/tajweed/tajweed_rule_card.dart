import 'package:flutter/material.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/quran/tajweed/tajweed_rule_model.dart';
import 'package:share_plus/share_plus.dart';

class TajweedRuleCard extends StatelessWidget {
  const TajweedRuleCard({
    super.key,
    required this.rule,
  });

  final TajweedRuleModel rule;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: _buildColorIndicator(),
            title: Text(
              rule.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                rule.shortDescription,
                style: TextStyle(
                  color: AppTheme.mutedTextColor(context),
                  fontSize: 13,
                ),
              ),
            ),
            children: [
              _buildDetailedSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorIndicator() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: rule.color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: rule.color,
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: rule.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 24),
        Text(
          rule.detailedExplanation,
          style: const TextStyle(height: 1.6, fontSize: 14),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: rule.color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: rule.color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'مثال توضيحي',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                rule.exampleWord,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: rule.color,
                  fontFamily: 'Uthmani', // Or the app's default quran font
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 20),
              color: AppTheme.primaryColor,
              onPressed: () {
                SharePlus.instance.share(
                  ShareParams(
                    text: 'حكم التجويد: ${rule.title}\nالمعنى: ${rule.detailedExplanation}\nمثال: ${rule.exampleWord}',
                  ),
                );
              },
            ),
          ],
        )
      ],
    );
  }
}
