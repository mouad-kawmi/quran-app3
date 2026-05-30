import 'package:flutter_test/flutter_test.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quran_app/core/khatma_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  for (final days in KhatmaService.availablePlans) {
    test('khatma plan $days days covers every Quran page once', () {
      final planDays = KhatmaService.buildDays(days);
      final pages = planDays.expand((day) => day.pages).toList();

      expect(planDays, hasLength(days));
      expect(pages, hasLength(quran.totalPagesCount));
      expect(pages.first, 1);
      expect(pages.last, quran.totalPagesCount);
      expect(pages.toSet(), hasLength(quran.totalPagesCount));
    });
  }

  test('60 day plan gives organized 10-11 page ranges', () {
    final planDays = KhatmaService.buildDays(60);
    final pageCounts = planDays.map((day) => day.pageCount).toSet();

    expect(pageCounts, {10, 11});
    expect(planDays.first.startPage, 1);
    expect(planDays.first.endPage, 10);
    expect(planDays.last.endPage, quran.totalPagesCount);
  });

  test('progress is saved locally and returns next unread page', () async {
    var progress = await KhatmaService.startPlan(30);
    expect(progress.planDays, 30);
    expect(progress.nextPage, 1);

    progress = await KhatmaService.togglePage(1, completed: true);
    expect(progress.isPageCompleted(1), isTrue);
    expect(progress.nextPage, 2);

    final loaded = await KhatmaService.loadProgress();
    expect(loaded.planDays, 30);
    expect(loaded.isPageCompleted(1), isTrue);
    expect(loaded.nextPage, 2);
  });
}
