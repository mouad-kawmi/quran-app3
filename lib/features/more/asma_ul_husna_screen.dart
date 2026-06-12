import 'package:flutter/material.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/more/asma_ul_husna_data.dart';
import 'package:quran_app/l10n/app_localizations.dart';

class AsmaUlHusnaScreen extends StatefulWidget {
  const AsmaUlHusnaScreen({super.key});

  @override
  State<AsmaUlHusnaScreen> createState() => _AsmaUlHusnaScreenState();
}

class _AsmaUlHusnaScreenState extends State<AsmaUlHusnaScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  // Strip Arabic diacritics (tashkeel) for accent-insensitive search
  static String _stripTashkeel(String s) {
    return s.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<AsmaUlHusnaModel> get _filtered {
    if (_query.isEmpty) return AsmaUlHusnaData.names;
    final q = _stripTashkeel(_query.trim());
    return AsmaUlHusnaData.names.where((n) =>
      _stripTashkeel(n.name).contains(q) ||
      _stripTashkeel(n.meaning).contains(q),
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppTheme.isDark(context);
    final filtered = _filtered;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(dark),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchDelegate(
                child: _buildSearchBar(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _NameCard(name: filtered[i]),
                  childCount: filtered.length,
                ),
              ),
            ),
          ],
        ),
    );
  }

  SliverAppBar _buildAppBar(bool dark) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      stretch: true,
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          AppLocalizations.of(context)!.asmaUlHusna,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF004D40), Color(0xFF00796B)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Geometric ornament
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFCFB53B).withOpacity(0.25),
                    width: 40,
                  ),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFCFB53B).withOpacity(0.2),
                    width: 24,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.asmaUlHusnaAyah,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFCFB53B).withOpacity(0.9),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context)!.asmaUlHusnaAyahRef,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.searchNameHint,
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppTheme.isDark(context)
              ? AppTheme.darkElevatedSurfaceColor
              : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  const _NameCard({required this.name});
  final AsmaUlHusnaModel name;

  static const _gold = Color(0xFFCFB53B);
  static final _cardColors = [
    const Color(0xFF004D40),
    const Color(0xFF00695C),
    const Color(0xFF00796B),
    const Color(0xFF00897B),
  ];

  Color get _bgColor => _cardColors[(name.id - 1) % _cardColors.length];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgColor, _bgColor.withOpacity(0.75)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold.withOpacity(0.35), width: 1),
          boxShadow: [
            BoxShadow(
              color: _bgColor.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Number badge
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _gold.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: _gold.withOpacity(0.5)),
                ),
                child: Center(
                  child: Text(
                    '${name.id}',
                    locale: const Locale('en'),
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    name.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    width: 40,
                    color: _gold.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    name.meaning,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scroll) => SingleChildScrollView(
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Name hero
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_bgColor, _bgColor.withOpacity(0.7)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _gold.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        name.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name.meaning,
                        style: TextStyle(
                          color: _gold,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                Align(
                  alignment: Directionality.of(context) == TextDirection.rtl
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Text(
                    l10n.meaningAndSignificance,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    name.description,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.8,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Dhikr tip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _gold.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          color: _gold, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.asmaUlHusnaDhikrTip,
                          style: TextStyle(
                            color: AppTheme.isDark(context)
                                ? Colors.white70
                                : Colors.black87,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ),
    );
  }
}

class _SearchDelegate extends SliverPersistentHeaderDelegate {
  const _SearchDelegate({required this.child});
  final Widget child;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  double get maxExtent => 68;
  @override
  double get minExtent => 68;
  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate old) => true;
}
