import 'package:flutter/material.dart';
import 'package:quran_app/core/app_settings.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/quran/tajweed/tajweed_data.dart';
import 'package:quran_app/features/quran/tajweed/tajweed_rule_card.dart';
import 'package:quran_app/l10n/app_localizations.dart';

class TajweedRulesScreen extends StatefulWidget {
  const TajweedRulesScreen({super.key});

  @override
  State<TajweedRulesScreen> createState() => _TajweedRulesScreenState();
}

class _TajweedRulesScreenState extends State<TajweedRulesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late String _selectedCategory;
  bool _categoriesInitialized = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _categories {
    final cats = <String>{};
    for (var rule in TajweedData.rules) {
      cats.add(rule.category);
    }
    return cats.toList();
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.watch(context);
    final l10n = AppLocalizations.of(context)!;
    final allLabel = l10n.allCategory;

    // Init selectedCategory lazily
    if (!_categoriesInitialized) {
      _selectedCategory = allLabel;
      _categoriesInitialized = true;
    }

    // Filter rules
    final filteredRules = TajweedData.rules.where((rule) {
      final matchesSearch = _searchQuery.isEmpty ||
          rule.title.contains(_searchQuery) ||
          rule.shortDescription.contains(_searchQuery);
      final matchesCategory = _selectedCategory == allLabel || rule.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tajweedRulesTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
        body: Column(
          children: [
            _buildHeader(settings, l10n),
            _buildSearchAndFilter(l10n, allLabel),
            Expanded(
              child: filteredRules.isEmpty
                  ? _buildEmptyState(l10n)
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredRules.length,
                      itemBuilder: (context, index) {
                        return TajweedRuleCard(rule: filteredRules[index]);
                      },
                    ),
            ),
          ],
        ),
    );
  }

  Widget _buildHeader(AppSettingsController settings, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.enableTajweedMushaf,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(l10n.enableTajweedMushafDesc),
            value: settings.useTajweedColors,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) async {
              await settings.setUseTajweedColors(value);
            },
          ),
          if (settings.useTajweedColors)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 20, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.tajweedNoteColor,
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(AppLocalizations l10n, String allLabel) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: l10n.searchTajweedHint,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: AppTheme.isDark(context) ? Colors.black12 : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length + 1,
              itemBuilder: (context, index) {
                // index 0 = "All" label, rest are categories
                final category = index == 0 ? null : _categories[index - 1];
                final label = index == 0 ? allLabel : category!;
                final isSelected = _selectedCategory == label;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedCategory = label);
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            l10n.noResultsFound,
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
