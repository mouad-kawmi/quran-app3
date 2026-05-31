import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/khatma_service.dart';
import 'package:quran_app/core/theme.dart';

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
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final progress = await KhatmaService.loadProgress();
    if (!mounted) return;

    setState(() {
      _progress = progress;
      _isLoading = false;
      if (progress.hasPlan) {
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('تغيير خطة الختمة؟'),
          content: const Text(
            'عند تغيير الخطة سيبدأ التقدم من البداية للحفاظ على تقسيم منظم.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تغيير الخطة'),
            ),
          ],
        ),
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
    final progress = _progress;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text(
            'الختمة',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading || progress == null
            ? const Center(child: CircularProgressIndicator())
            : progress.hasPlan
            ? _buildDashboard(progress)
            : _buildPlanPicker(),
      ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.flag_rounded, color: Colors.white, size: 34),
          SizedBox(height: 16),
          Text(
            'اختر مدة الختمة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'يقسم التطبيق 604 صفحة حسب المدة المختارة، ويمكنك وضع علامة على كل صفحة بعد إتمامها.',
            style: TextStyle(color: Colors.white70, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
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
          const Text(
            'كيف تعمل الختمة؟',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 12),
          _buildStepRow('1', 'اختر المدة المناسبة: 15 أو 30 أو 60 يوم.'),
          _buildStepRow('2', 'ستجد صفحات كل يوم مقسمة بوضوح.'),
          _buildStepRow(
            '3',
            'بعد إتمام الصفحة ضع عليها علامة، وسينقلك التطبيق إلى الصفحة التالية.',
          ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ختمة $days يوم',
                    style: TextStyle(
                      color: AppTheme.primaryTextColor(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    KhatmaService.pagesPerDayLabel(days),
                    style: TextStyle(color: AppTheme.mutedTextColor(context)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'اليوم 1: ${firstDay.startPage}-${firstDay.endPage} • اليوم $days: ${lastDay.startPage}-${lastDay.endPage}',
                    style: TextStyle(
                      color: AppTheme.mutedTextColor(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
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
                  'ما المطلوب الآن؟',
                  style: TextStyle(
                    color: AppTheme.primaryTextColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  nextPage == null
                      ? 'مبارك، اكتملت الختمة. يمكنك تغيير الخطة والبدء من جديد.'
                      : 'أكمل صفحات اليوم ${selectedDay.number}: من ${selectedDay.startPage} حتى ${selectedDay.endPage}. الصفحة التالية هي $nextPage.',
                  style: TextStyle(
                    color: AppTheme.mutedTextColor(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'منجزة اليوم: $completed/${selectedDay.pageCount}',
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
    final percent = (progress.ratio * 100).clamp(0, 100).toStringAsFixed(0);
    final nextPage = progress.nextPage;

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
                  'ختمة ${progress.planDays} يوم',
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
                  'المقروء',
                  '${progress.completedCount}/604',
                ),
              ),
              Expanded(
                child: _buildHeaderStat('الباقي', '${progress.remainingCount}'),
              ),
              Expanded(
                child: _buildHeaderStat(
                  'الصفحة التالية',
                  nextPage == null ? 'تمت' : '$nextPage',
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
                    ? 'الختمة مكتملة'
                    : 'علّم الصفحة $nextPage وانتقل إلى التالية',
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
                    label: Text('$days يوم'),
                    selected: days == currentDays,
                    onSelected: days == currentDays
                        ? null
                        : (_) => _confirmChangePlan(days),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'تحديث',
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
                    'اليوم ${day.number}',
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
                      'اليوم ${day.number}',
                      style: TextStyle(
                        color: AppTheme.primaryTextColor(context),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'من الصفحة ${day.startPage} حتى ${day.endPage}',
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
          'الصفحة $page',
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
          tooltip: 'فتح الصفحة',
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
    await KhatmaService.togglePage(widget.page, completed: true);
    if (!mounted) return;

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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          unawaited(_goBack());
        },
        child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(title: Text('الصفحة ${widget.page}')),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPageInfo(),
                    const SizedBox(height: 14),
                    _buildPageText(),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              IconButton.filledTonal(
                tooltip: _isCompleted ? 'إزالة العلامة' : 'علّم الصفحة',
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
                  label: Text(
                    widget.page == quran.totalPagesCount
                        ? 'تمت الصفحة الأخيرة'
                        : 'تمت الصفحة وانتقل إلى التالية',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildPageInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${widget.page}',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _pageSummary(widget.page),
              style: TextStyle(
                color: AppTheme.primaryTextColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Icon(
            _isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: _isCompleted ? AppTheme.primaryColor : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildPageText() {
    final spans = <InlineSpan>[];
    final pageData = quran.getPageData(widget.page);

    for (final section in pageData) {
      final surah = section['surah'] as int;
      final start = section['start'] as int;
      final end = section['end'] as int;

      if (start == 1) {
        spans.add(
          WidgetSpan(
            child: _SurahHeader(name: quran.getSurahNameArabic(surah)),
          ),
        );
      }

      for (var verse = start; verse <= end; verse++) {
        spans.add(
          TextSpan(
            text: quran.getVerse(surah, verse),
            style: GoogleFonts.amiri(
              color: AppTheme.primaryTextColor(context),
              fontSize: 24,
              height: 2.2,
            ),
          ),
        );
        spans.add(
          TextSpan(
            text: ' ${quran.getVerseEndSymbol(verse)} ',
            style: GoogleFonts.amiri(
              fontSize: 20,
              color: AppTheme.secondaryColor,
              height: 2.2,
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.elevatedSurfaceColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: RichText(
        textAlign: TextAlign.justify,
        text: TextSpan(
          style: TextStyle(color: AppTheme.primaryTextColor(context)),
          children: spans,
        ),
      ),
    );
  }
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        name,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
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
