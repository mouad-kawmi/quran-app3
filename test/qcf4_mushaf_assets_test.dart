import 'package:flutter_test/flutter_test.dart';
import 'package:quran_app/features/quran/qcf_mushaf_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads QCF4 mushaf page data and fonts from bundled assets', () async {
    final page = await QcfMushafAssets.loadPage(1);

    expect(page.page, 1);
    expect(page.font, 'QCF4_Hafs_01');
    expect(page.lines, isNotEmpty);
    expect(QcfMushafAssets.isPageFontLoaded(1), isTrue);
  });
}
