import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';

class KhatmaDay {
  const KhatmaDay({
    required this.number,
    required this.startPage,
    required this.endPage,
  });

  final int number;
  final int startPage;
  final int endPage;

  int get pageCount => endPage - startPage + 1;

  List<int> get pages =>
      List<int>.generate(pageCount, (index) => startPage + index);

  bool containsPage(int page) => page >= startPage && page <= endPage;
}

class KhatmaProgress {
  const KhatmaProgress({
    required this.planDays,
    required this.completedPages,
    this.startedAt,
  });

  final int? planDays;
  final Set<int> completedPages;
  final DateTime? startedAt;

  bool get hasPlan => planDays != null;

  int get completedCount => completedPages.length;

  int get remainingCount => quran.totalPagesCount - completedCount;

  double get ratio => completedCount / quran.totalPagesCount;

  bool get isComplete => completedCount >= quran.totalPagesCount;

  int? get nextPage {
    for (var page = 1; page <= quran.totalPagesCount; page++) {
      if (!completedPages.contains(page)) return page;
    }
    return null;
  }

  int get currentDay {
    final days = planDays;
    final page = nextPage;
    if (days == null || page == null) return planDays ?? 1;
    return KhatmaService.dayNumberForPage(page, days);
  }

  bool isPageCompleted(int page) => completedPages.contains(page);

  int completedInDay(KhatmaDay day) {
    return day.pages.where(completedPages.contains).length;
  }
}

class KhatmaService {
  static const availablePlans = [15, 30, 60];

  static const _planDaysKey = 'khatma_plan_days';
  static const _completedPagesKey = 'khatma_completed_pages';
  static const _startedAtKey = 'khatma_started_at';

  static List<KhatmaDay> buildDays(int totalDays) {
    _validatePlan(totalDays);

    return [
      for (var day = 1; day <= totalDays; day++)
        KhatmaDay(
          number: day,
          startPage: ((day - 1) * quran.totalPagesCount ~/ totalDays) + 1,
          endPage: day * quran.totalPagesCount ~/ totalDays,
        ),
    ];
  }

  static int dayNumberForPage(int page, int totalDays) {
    _validatePage(page);
    _validatePlan(totalDays);

    for (final day in buildDays(totalDays)) {
      if (day.containsPage(page)) return day.number;
    }

    return totalDays;
  }

  static KhatmaDay dayForPage(int page, int totalDays) {
    return buildDays(totalDays).firstWhere((day) => day.containsPage(page));
  }

  static String pagesPerDayLabel(int totalDays) {
    final counts = buildDays(totalDays).map((day) => day.pageCount).toSet();
    final sortedCounts = counts.toList()..sort();
    if (sortedCounts.length == 1) {
      return '${sortedCounts.first} صفحة في اليوم';
    }
    return '${sortedCounts.first}-${sortedCounts.last} صفحة في اليوم';
  }

  static Future<KhatmaProgress> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final planDays = prefs.getInt(_planDaysKey);
    final startedAtValue = prefs.getString(_startedAtKey);
    final completedPages =
        prefs
            .getStringList(_completedPagesKey)
            ?.map(int.tryParse)
            .whereType<int>()
            .where((page) => page >= 1 && page <= quran.totalPagesCount)
            .toSet() ??
        <int>{};

    return KhatmaProgress(
      planDays: availablePlans.contains(planDays) ? planDays : null,
      completedPages: completedPages,
      startedAt: startedAtValue == null
          ? null
          : DateTime.tryParse(startedAtValue),
    );
  }

  static Future<KhatmaProgress> startPlan(int days) async {
    _validatePlan(days);

    final progress = KhatmaProgress(
      planDays: days,
      completedPages: <int>{},
      startedAt: DateTime.now(),
    );
    await _saveProgress(progress);
    return progress;
  }

  static Future<KhatmaProgress> togglePage(int page, {bool? completed}) async {
    _validatePage(page);

    final current = await loadProgress();
    final pages = {...current.completedPages};
    final shouldComplete = completed ?? !pages.contains(page);

    if (shouldComplete) {
      pages.add(page);
    } else {
      pages.remove(page);
    }

    final progress = KhatmaProgress(
      planDays: current.planDays,
      completedPages: pages,
      startedAt: current.startedAt,
    );
    await _saveProgress(progress);
    return progress;
  }

  static Future<KhatmaProgress> markNextPageCompleted() async {
    final current = await loadProgress();
    final page = current.nextPage;
    if (page == null) return current;
    return togglePage(page, completed: true);
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_planDaysKey);
    await prefs.remove(_completedPagesKey);
    await prefs.remove(_startedAtKey);
  }

  static Future<void> _saveProgress(KhatmaProgress progress) async {
    final prefs = await SharedPreferences.getInstance();

    final planDays = progress.planDays;
    if (planDays == null) {
      await prefs.remove(_planDaysKey);
    } else {
      await prefs.setInt(_planDaysKey, planDays);
    }

    final pages = progress.completedPages.toList()..sort();
    await prefs.setStringList(
      _completedPagesKey,
      pages.map((page) => page.toString()).toList(),
    );

    final startedAt = progress.startedAt;
    if (startedAt == null) {
      await prefs.remove(_startedAtKey);
    } else {
      await prefs.setString(_startedAtKey, startedAt.toIso8601String());
    }
  }

  static void _validatePlan(int days) {
    if (!availablePlans.contains(days)) {
      throw ArgumentError.value(days, 'days', 'Plan must be 15, 30, or 60');
    }
  }

  static void _validatePage(int page) {
    if (page < 1 || page > quran.totalPagesCount) {
      throw ArgumentError.value(page, 'page', 'Page must be between 1 and 604');
    }
  }
}
