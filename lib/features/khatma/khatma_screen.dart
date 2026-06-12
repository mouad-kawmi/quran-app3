import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/khatma_service.dart';
import 'package:quran_app/core/theme.dart';
import 'package:quran_app/features/quran/qcf_mushaf_page.dart';
import 'package:quran_app/l10n/app_localizations.dart';

class KhatmaScreen extends StatefulWidget {
  const KhatmaScreen({super.key});

  @override
  State<KhatmaScreen> createState() => _KhatmaScreenState();
}

class _KhatmaScreenState extends State<KhatmaScreen> {
  KhatmaProgress? _progress;
  bool _isLoading = true;
  int _selectedDay = 1;

  @override
  void initState() {
    super.initState();
    _loadProgress(isInit: true);
  }

  Future<void> _loadProgress({bool isInit = false}) async {
    final progress = await KhatmaService.loadProgress();
    if (!mounted) return;

    setState(() {
      _progress = progress;
      _isLoading = false;
      if (isInit && progress.hasPlan) {
        _selectedDay = progress.currentDay;
      }
    });
  }

  Future<void> _startPlan(int days) async {
    final progress = await KhatmaService.startPlan(days);
    if (!mounted) return;

    setState(() {
      _progress = progress;
      _selectedDay = 1;
    });
  }

  Future<void> _confirmChangePlan(int days) async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final title = locale == 'en' ? 'Change Khatma Plan?'
        : locale == 'fr' ? 'Changer le plan de Khatma ?'
        : 'تغيير خطة الختمة؟';
    final content = locale == 'en'
        ? 'Changing the plan will reset progress from the beginning to keep reading organized.'
        : locale == 'fr'
        ? 'Changer le plan réinitialisera la progression depuis le début pour rester organisé.'
        : 'عند تغيير الخطة سيبدأ التقدم من البداية للحفاظ على تقسيم منظم.';
    final cancelLabel = locale == 'en' ? 'Cancel' : locale == 'fr' ? 'Annuler' : 'إلغاء';
    final confirmLabel = locale == 'en' ? 'Change Plan' : locale == 'fr' ? 'Changer le plan' : 'تغيير الخطة';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _startPlan(days);
    }
  }

  Future<void> _togglePage(int page, bool completed) async {
    final progress = await KhatmaService.togglePage(page, completed: completed);
    if (!mounted) return;

    setState(() {
      _progress = progress;
      if (progress.hasPlan) {
        _selectedDay = progress.currentDay;
      }
    });
  }

  Future<void> _markNextPage() async {
    final progress = await KhatmaService.markNextPageCompleted();
    if (!mounted) return;

    setState(() {
      _progress = progress;
      if (progress.hasPlan) {
        _selectedDay = progress.currentDay;
      }
    });
  }

  Future<void> _openPage(int page) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => KhatmaPageScreen(page: page)),
    );
    await _loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = _progress;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.khatma,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading || progress == null
          ? const Center(child: CircularProgressIndicator())
          : progress.hasPlan
          ? _buildDashboard(progress)
          : _buildPlanPicker(),
    );
  }

  Widget _buildPlanPicker() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildIntroCard(),
        const SizedBox(height: 14),
        _buildHowItWorksCard(),
        const SizedBox(height: 20),
        for (final days in KhatmaService.availablePlans) ...[
          _buildPlanCard(days),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildIntroCard() {
    final locale = Localizations.localeOf(context).languageCode;
    final title = locale == 'en' ? 'Choose Khatma Duration'
        : locale == 'fr' ? 'Choisir la durée de la Khatma'
        : 'اختر مدة الختمة';
    final desc = locale == 'en'
        ? 'The app divides 604 pages according to your chosen duration. Mark each page after completing it.'
        : locale == 'fr'
        ? 'L\'application divise 604 pages selon la durée choisie. Marquez chaque page après l\'avoir complétée.'
        : 'يقسم التطبيق 604 صفحة حسب المدة المختارة، ويمكنك وضع علامة على كل صفحة بعد إتمامها.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag_rounded, color: Colors.white, size: 34),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(color: Colors.white70, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    final locale = Localizations.localeOf(context).languageCode;
    final title = locale == 'en' ? 'How does Khatma work?'
        : locale == 'fr' ? 'Comment fonctionne la Khatma ?'
        : 'كيف تعمل الختمة؟';
    final steps = locale == 'en'
        ? [
            'Choose a duration: 15, 30, or 60 days.',
            'You will find each day\'s pages clearly divided.',
            'After completing a page, mark it and the app will move you to the next one.',
          ]
        : locale == 'fr'
        ? [
            'Choisissez une durée : 15, 30 ou 60 jours.',
            'Vous trouverez les pages de chaque jour clairement divisées.',
            'Après avoir complété une page, marquez-la et l\'application vous passera à la suivante.',
          ]
        : [
            'اختر المدة المناسبة: 15 أو 30 أو 60 يوم.',
            'ستجد صفحات كل يوم مقسمة بوضوح.',
            'بعد إتمام الصفحة ضع عليها علامة، وسينقلك التطبيق إلى الصفحة التالية.',
          ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.softBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            _buildStepRow('${i + 1}', steps[i]),
        ],
      ),
    );
  }

  Widget _buildStepRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.mutedTextColor(context),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(int days) {
    final dayRanges = KhatmaService.buildDays(days);
    final firstDay = dayRanges.first;
    final lastDay = dayRanges.last;

    return InkWell(
      onTap: () => _startPlan(days),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.elevatedSurfaceColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.softBorderColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: AppTheme.isDark(context) ? 0.16 : 0.04,
              ),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$days',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Builder(builder: (context) {
                final locale = Localizations.localeOf(context).languageCode;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    locale == 'en' ? '$days-Day Khatma'
                        : locale == 'fr' ? 'Khatma de $days jours'
                        : 'ختمة $days يوم',
                    style: TextStyle(
                      color: AppTheme.primaryTextColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    KhatmaService.pagesPerDayLabel(days, locale),
                    style: TextStyle(color: AppTheme.mutedTextColor(context)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    locale == 'en'
                        ? 'Day 1: ${firstDay.startPage}-${firstDay.endPage} • Day $days: ${lastDay.startPage}-${lastDay.endPage}'
                        : locale == 'fr'
                        ? 'Jour 1: ${firstDay.startPage}-${firstDay.endPage} • Jour $days: ${lastDay.startPage}-${lastDay.endPage}'
                        : 'اليوم 1: ${firstDay.startPage}-${firstDay.endPage} • اليوم $days: ${lastDay.startPage}-${lastDay.endPage}',
                    style: TextStyle(
                      color: AppTheme.mutedTextColor(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              );
              }),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(KhatmaProgress progress) {
    final days = progress.planDays!;
    final dayRanges = KhatmaService.buildDays(days);
    final selectedDay = dayRanges[_selectedDay - 1];

    return RefreshIndicator(
      onRefresh: _loadProgress,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildProgressHeader(progress),
          const SizedBox(height: 14),
          _buildTodayGuide(selectedDay, progress),
          const SizedBox(height: 18),
          _buildPlanActions(days),
          const SizedBox(height: 18),
          _buildDaySelector(dayRanges, progress),
          const SizedBox(height: 18),
          _buildSelectedDay(selectedDay, progress),
        ],
      ),
    );
  }

  Widget _buildTodayGuide(KhatmaDay selectedDay, KhatmaProgress progress) {
    final nextPage = progress.nextPage;
    final completed = progress.completedInDay(selectedDay);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.secondaryColor.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_rounded,
              color: AppTheme.secondaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localStr(context, 'ما المطلوب الآن؟', 'What to do now?', 'Que faire maintenant ?'),
                  style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  () {
                    final locale = Localizations.localeOf(context).languageCode;
                    if (nextPage == null) {
                      return locale == 'en'
                          ? 'Congratulations, Khatma completed! You can change the plan and start over.'
                          : locale == 'fr'
                          ? 'Félicitations, Khatma terminée ! Vous pouvez changer le plan et recommencer.'
                          : 'مبارك، اكتملت الختمة. يمكنك تغيير الخطة والبدء من جديد.';
                    }
                    return locale == 'en'
                        ? 'Complete Day ${selectedDay.number} pages: ${selectedDay.startPage} to ${selectedDay.endPage}. Next page: $nextPage.'
                        : locale == 'fr'
                        ? 'Terminez les pages du Jour ${selectedDay.number} : ${selectedDay.startPage} à ${selectedDay.endPage}. Page suivante : $nextPage.'
                        : 'أكمل صفحات اليوم ${selectedDay.number}: من ${selectedDay.startPage} حتى ${selectedDay.endPage}. الصفحة التالية هي $nextPage.';
                  }(),
                  style: TextStyle(
                    color: AppTheme.mutedTextColor(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _localStr(context,
                    'منجزة اليوم: $completed/${selectedDay.pageCount}',
                    'Done today: $completed/${selectedDay.pageCount}',
                    'Faites aujourd\'hui : $completed/${selectedDay.pageCount}',
                  ),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(KhatmaProgress progress) {
    final locale = Localizations.localeOf(context).languageCode;
    final percent = (progress.ratio * 100).clamp(0, 100).toStringAsFixed(0);
    final nextPage = progress.nextPage;
    final planTitle = locale == 'en' ? '${progress.planDays}-Day Khatma'
        : locale == 'fr' ? 'Khatma de ${progress.planDays} jours'
        : 'ختمة ${progress.planDays} يوم';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_stories_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  planTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  color: AppTheme.secondaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress.ratio.clamp(0, 1),
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.secondaryColor,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildHeaderStat(
                  _localStr(context, 'المقروء', 'Read', 'Lu'),
                  '${progress.completedCount}/604',
                ),
              ),
              Expanded(
                child: _buildHeaderStat(
                  _localStr(context, 'الباقي', 'Remaining', 'Restant'),
                  '${progress.remainingCount}',
                ),
              ),
              Expanded(
                child: _buildHeaderStat(
                  _localStr(context, 'الصفحة التالية', 'Next Page', 'Page suivante'),
                  nextPage == null
                      ? _localStr(context, 'تمت', 'Done', 'Terminée')
                      : '$nextPage',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: nextPage == null ? null : _markNextPage,
              icon: const Icon(Icons.check_circle_rounded),
              label: Text(
                nextPage == null
                    ? _localStr(context, 'الختمة مكتملة', 'Khatma Completed', 'Khatma terminée')
                    : _localStr(
                        context,
                        'علّم الصفحة $nextPage وانتقل إلى التالية',
                        'Mark page $nextPage and go to next',
                        'Marquer la page $nextPage et passer à la suivante',
                      ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                disabledBackgroundColor: Colors.white24,
                disabledForegroundColor: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanActions(int currentDays) {
    final locale = Localizations.localeOf(context).languageCode;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final days in KhatmaService.availablePlans)
                  ChoiceChip(
                    label: Text(locale == 'en' ? '$days days' : locale == 'fr' ? '$days jours' : '$days يوم'),
                    selected: days == currentDays,
                    onSelected: days == currentDays
                        ? null
                        : (_) => _confirmChangePlan(days),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: _localStr(context, 'تحديث', 'Refresh', 'Actualiser'),
            onPressed: _loadProgress,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector(List<KhatmaDay> days, KhatmaProgress progress) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, separatorIndex) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          final completed = progress.completedInDay(day);
          final selected = day.number == _selectedDay;

          return InkWell(
            onTap: () => setState(() => _selectedDay = day.number),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 118,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.elevatedSurfaceColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withValues(alpha: 0.08),
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _localStr(context, 'اليوم ${day.number}', 'Day ${day.number}', 'Jour ${day.number}'),
                    style: TextStyle(
                      color: AppTheme.primaryTextColor(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.startPage}-${day.endPage}',
                    style: TextStyle(
                      color: AppTheme.mutedTextColor(context),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: completed / day.pageCount,
                      minHeight: 6,
                      backgroundColor: AppTheme.subtleSurfaceColor(context),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        selected
                            ? AppTheme.primaryColor
                            : AppTheme.secondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDay(KhatmaDay day, KhatmaProgress progress) {
    final completed = progress.completedInDay(day);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _localStr(context, 'اليوم ${day.number}', 'Day ${day.number}', 'Jour ${day.number}'),
                      style: TextStyle(
                        color: AppTheme.primaryTextColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _localStr(context,
                        'من الصفحة ${day.startPage} حتى ${day.endPage}',
                        'Pages ${day.startPage}–${day.endPage}',
                        'Pages ${day.startPage}–${day.endPage}',
                      ),
                      style: TextStyle(
                        color: AppTheme.mutedTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$completed/${day.pageCount}',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (final page in day.pages) _buildPageRow(page, progress),
        ],
      ),
    );
  }

  Widget _buildPageRow(int page, KhatmaProgress progress) {
    final completed = progress.isPageCompleted(page);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: completed
            ? AppTheme.primaryColor.withValues(alpha: 0.06)
            : AppTheme.subtleSurfaceColor(context),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Checkbox(
          value: completed,
          activeColor: AppTheme.primaryColor,
          onChanged: (value) => _togglePage(page, value ?? false),
        ),
        title: Text(
          _localStr(context, 'الصفحة $page', 'Page $page', 'Page $page'),
          style: TextStyle(
            color: AppTheme.primaryTextColor(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          _pageSummary(page),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.mutedTextColor(context),
            fontSize: 12,
          ),
        ),
        trailing: IconButton(
          tooltip: _localStr(context, 'فتح الصفحة', 'Open page', 'Ouvrir la page'),
          onPressed: () => _openPage(page),
          icon: const Icon(Icons.menu_book_rounded),
        ),
        onTap: () => _openPage(page),
      ),
    );
  }
}

class KhatmaPageScreen extends StatefulWidget {
  const KhatmaPageScreen({
    super.key,
    required this.page,
    this.returnToKhatmaHomeOnBack = false,
  });

  final int page;
  final bool returnToKhatmaHomeOnBack;

  @override
  State<KhatmaPageScreen> createState() => _KhatmaPageScreenState();
}

class _KhatmaPageScreenState extends State<KhatmaPageScreen> {
  bool _isCompleted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    QcfMushafAssets.warmUpPageWindow(widget.page, radius: 2);
  }

  Future<void> _loadStatus() async {
    final progress = await KhatmaService.loadProgress();
    if (!mounted) return;

    setState(() {
      _isCompleted = progress.isPageCompleted(widget.page);
      _isLoading = false;
    });
  }

  Future<void> _completeAndGoNext() async {
    final progress = await KhatmaService.togglePage(widget.page, completed: true);
    if (!mounted) return;

    if (progress.hasPlan) {
      final currentDay = KhatmaService.dayForPage(widget.page, progress.planDays!);
      if (widget.page == currentDay.endPage) {
        if (mounted) {
          final locale = Localizations.localeOf(context).languageCode;
          final msg = locale == 'en'
              ? '🎉 Day ${currentDay.number} completed!'
              : locale == 'fr'
              ? '🎉 Jour ${currentDay.number} terminé !'
              : 'تقبل الله! أنهيت وِرد اليوم ${currentDay.number} بنجاح.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        await _goBack();
        return;
      }
    }

    final nextPage = widget.page < quran.totalPagesCount
        ? widget.page + 1
        : null;
    if (nextPage == null) {
      await _goBack();
      return;
    }

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => KhatmaPageScreen(
          page: nextPage,
          returnToKhatmaHomeOnBack: widget.returnToKhatmaHomeOnBack,
        ),
      ),
    );
  }

  Future<void> _goBack() async {
    if (!widget.returnToKhatmaHomeOnBack) {
      Navigator.pop(context);
      return;
    }

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const KhatmaScreen()),
    );
  }

  Future<void> _toggleCompleted() async {
    final progress = await KhatmaService.togglePage(
      widget.page,
      completed: !_isCompleted,
    );
    if (!mounted) return;

    setState(() {
      _isCompleted = progress.isPageCompleted(widget.page);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final pageLabel = locale == 'en' ? 'Page ${widget.page}'
        : locale == 'fr' ? 'Page ${widget.page}'
        : 'الصفحة ${widget.page}';
    final markTooltip = _isCompleted
        ? (locale == 'en' ? 'Unmark page' : locale == 'fr' ? 'Retirer la marque' : 'إزالة العلامة')
        : (locale == 'en' ? 'Mark page' : locale == 'fr' ? 'Marquer la page' : 'علّم الصفحة');
    final btnLabel = widget.page == quran.totalPagesCount
        ? (locale == 'en' ? 'Last page completed' : locale == 'fr' ? 'Dernière page terminée' : 'تمت الصفحة الأخيرة')
        : (locale == 'en' ? 'Done — go to next page' : locale == 'fr' ? 'Terminé — passer à la suivante' : 'تمت الصفحة وانتقل إلى التالية');
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        unawaited(_goBack());
      },
      child: Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: Text(pageLabel)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
              child: QcfMushafPage(
                pageNumber: widget.page,
                juzNumber: _juzForPage(widget.page),
                pageSummary: _pageSummary(widget.page),
              ),
            ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: markTooltip,
              onPressed: _toggleCompleted,
              icon: Icon(
                _isCompleted
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _completeAndGoNext,
                icon: const Icon(Icons.check_rounded),
                label: Text(btnLabel),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

}

int _juzForPage(int page) {
  final pageData = quran.getPageData(page);
  final first = pageData.first as Map;
  return quran.getJuzNumber(first['surah'] as int, first['start'] as int);
}

String _pageSummary(int page) {
  final pageData = quran.getPageData(page);
  final firstSurah = pageData.first['surah'] as int;
  final lastSurah = pageData.last['surah'] as int;
  final firstName = quran.getSurahNameArabic(firstSurah);
  final lastName = quran.getSurahNameArabic(lastSurah);

  if (firstSurah == lastSurah) return firstName;
  return '$firstName - $lastName';
}

String _localStr(BuildContext context, String ar, String en, String fr) {
  final lang = Localizations.localeOf(context).languageCode;
  if (lang == 'en') return en;
  if (lang == 'fr') return fr;
  return ar;
}
