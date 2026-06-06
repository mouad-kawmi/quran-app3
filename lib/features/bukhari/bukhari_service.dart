import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:quran_app/features/bukhari/bukhari_models.dart';

Map<String, dynamic> _parseJson(String jsonString) {
  return jsonDecode(jsonString) as Map<String, dynamic>;
}

class BukhariService {
  static final BukhariService _instance = BukhariService._internal();
  factory BukhariService() => _instance;
  BukhariService._internal();

  List<BukhariBook> _books = [];

  // Helper map to translate the English section names to Arabic
  static const Map<String, String> _arabicSectionNames = {
    '1': 'كتاب بَدْءِ الْوَحْيِ',
    '2': 'كتاب الْإِيمَانِ',
    '3': 'كتاب الْعِلْمِ',
    '4': 'كتاب الْوُضُوءِ',
    '5': 'كتاب الْغُسْلِ',
    '6': 'كتاب الْحَيْضِ',
    '7': 'كتاب التَّيَمُّمِ',
    '8': 'كتاب الصَّلَاةِ',
    '9': 'كتاب مَوَاقِيتِ الصَّلَاةِ',
    '10': 'كتاب الْأَذَانِ',
    '11': 'كتاب الْجُمُعَةِ',
    '12': 'كتاب صَلَاةِ الْخَوْفِ',
    '13': 'كتاب الْعِيدَيْنِ',
    '14': 'كتاب الْوِتْرِ',
    '15': 'كتاب الِاسْتِسْقَاءِ',
    '16': 'كتاب الْكُسُوفِ',
    '17': 'كتاب سُجُودِ الْقُرْآنِ',
    '18': 'كتاب تَقْصِيرِ الصَّلَاةِ',
    '19': 'كتاب التَّهَجُّدِ',
    '20': 'كتاب فَضْلِ الصَّلَاةِ فِي مَسْجِدِ مَكَّةَ وَالْمَدِينَةِ',
    '21': 'كتاب الْعَمَلِ فِي الصَّلَاةِ',
    '22': 'كتاب السَّهْوِ',
    '23': 'كتاب الْجَنَائِزِ',
    '24': 'كتاب الزَّكَاةِ',
    '25': 'كتاب الْحَجِّ',
    '26': 'كتاب الْعُمْرَةِ',
    '27': 'كتاب الْمُحْصَرِ',
    '28': 'كتاب جَزَاءِ الصَّيْدِ',
    '29': 'كتاب فَضَائِلِ الْمَدِينَةِ',
    '30': 'كتاب الصَّوْمِ',
    '31': 'كتاب صَلَاةِ التَّرَاوِيحِ',
    '32': 'كتاب فَضْلِ لَيْلَةِ الْقَدْرِ',
    '33': 'كتاب الِاعْتِكَافِ',
    '34': 'كتاب الْبُيُوعِ',
    '35': 'كتاب السَّلَمِ',
    '36': 'كتاب الشُّفْعَةِ',
    '37': 'كتاب الْإِجَارَةِ',
    '38': 'كتاب الْحَوَالَاتِ',
    '39': 'كتاب الْكَفَالَةِ',
    '40': 'كتاب الْوَكَالَةِ',
    '41': 'كتاب الْمُزَارَعَةِ',
    '42': 'كتاب الْمُسَاقَاةِ',
    '43': 'كتاب الِاسْتِقْرَاضِ وَأَدَاءِ الدُّيُونِ',
    '44': 'كتاب الْخُصُومَاتِ',
    '45': 'كتاب اللُّقَطَةِ',
    '46': 'كتاب الْمَظَالِمِ',
    '47': 'كتاب الشَّرِكَةِ',
    '48': 'كتاب الرَّهْنِ',
    '49': 'كتاب الْعِتْقِ',
    '50': 'كتاب الْمُكَاتَبِ',
    '51': 'كتاب الْهِبَةِ',
    '52': 'كتاب الشَّهَادَاتِ',
    '53': 'كتاب الصُّلْحِ',
    '54': 'كتاب الشُّرُوطِ',
    '55': 'كتاب الْوَصَايَا',
    '56': 'كتاب الْجِهَادِ وَالسِّيَرِ',
    '57': 'كتاب فَرْضِ الْخُمُسِ',
    '58': 'كتاب الْجِزْيَةِ وَالْمُوَادَعَةِ',
    '59': 'كتاب بَدْءِ الْخَلْقِ',
    '60': 'كتاب أَحَادِيثِ الْأَنْبِيَاءِ',
    '61': 'كتاب الْمَنَاقِبِ',
    '62': 'كتاب فَضَائِلِ أَصْحَابِ النَّبِيِّ',
    '63': 'كتاب مَنَاقِبِ الْأَنْصَارِ',
    '64': 'كتاب الْمَغَازِي',
    '65': 'كتاب التَّفْسِيرِ',
    '66': 'كتاب فَضَائِلِ الْقُرْآنِ',
    '67': 'كتاب النِّكَاحِ',
    '68': 'كتاب الطَّلَاقِ',
    '69': 'كتاب النَّفَقَاتِ',
    '70': 'كتاب الْأَطْعِمَةِ',
    '71': 'كتاب الْعَقِيقَةِ',
    '72': 'كتاب الذَّبَائِحِ وَالصَّيْدِ',
    '73': 'كتاب الْأَضَاحِيِّ',
    '74': 'كتاب الْأَشْرِبَةِ',
    '75': 'كتاب الْمَرْضَى',
    '76': 'كتاب الطِّبِّ',
    '77': 'كتاب اللِّبَاسِ',
    '78': 'كتاب الْأَدَبِ',
    '79': 'كتاب الِاسْتِئْذَانِ',
    '80': 'كتاب الدَّعَوَاتِ',
    '81': 'كتاب الرِّقَاقِ',
    '82': 'كتاب الْقَدَرِ',
    '83': 'كتاب الْأَيْمَانِ وَالنُّذُورِ',
    '84': 'كتاب كَفَّارَاتِ الْأَيْمَانِ',
    '85': 'كتاب الْفَرَائِضِ',
    '86': 'كتاب الْحُدُودِ',
    '87': 'كتاب الدِّيَاتِ',
    '88': 'كتاب اسْتِتَابَةِ الْمُرْتَدِّينَ',
    '89': 'كتاب الْإِكْرَاهِ',
    '90': 'كتاب الْحِيَلِ',
    '91': 'كتاب التَّعْبِيرِ',
    '92': 'كتاب الْفِتَنِ',
    '93': 'كتاب الْأَحْكَامِ',
    '94': 'كتاب التَّمَنِّي',
    '95': 'كتاب أَخْبَارِ الْآحَادِ',
    '96': 'كتاب الِاعْتِصَامِ بِالْكِتَابِ وَالسُّنَّةِ',
    '97': 'كتاب التَّوْحِيدِ',
  };

  /// Load books and hadiths from local JSON
  Future<List<BukhariBook>> loadBukhari() async {
    if (_books.isNotEmpty) {
      return _books;
    }

      final jsonString =
          await rootBundle.loadString('assets/bukhari/ara-bukhari.json');
      final Map<String, dynamic> data = await compute(_parseJson, jsonString);

      final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
      final sections = metadata['sections'] as Map<String, dynamic>? ?? {};
      final sectionDetails =
          metadata['section_details'] as Map<String, dynamic>? ?? {};
      final hadithsData = data['hadiths'] as List<dynamic>? ?? [];

      // Group hadiths by book
      Map<String, List<BukhariHadith>> hadithsByBook = {};
      for (var item in hadithsData) {
        final hadith = BukhariHadith.fromJson(item as Map<String, dynamic>);
        final bookId = hadith.referenceBook;
        if (!hadithsByBook.containsKey(bookId)) {
          hadithsByBook[bookId] = [];
        }
        hadithsByBook[bookId]!.add(hadith);
      }

      List<BukhariBook> books = [];

      // Iterate through books 1 to 97
      for (int i = 1; i <= 97; i++) {
        String idStr = i.toString();
        // Check if book exists in details
        if (sectionDetails.containsKey(idStr)) {
          final detail = sectionDetails[idStr] as Map<String, dynamic>;
          final firstHadith = (detail['hadithnumber_first'] is num) ? (detail['hadithnumber_first'] as num).toInt() : 0;
          final lastHadith = (detail['hadithnumber_last'] is num) ? (detail['hadithnumber_last'] as num).toInt() : 0;
          final nameEng = sections[idStr] ?? 'Book $i';
          final nameAr = _arabicSectionNames[idStr] ?? 'كتاب رقم $i';
          final bookHadiths = hadithsByBook[idStr] ?? [];

          // Only add book if it has hadiths
          if (bookHadiths.isNotEmpty) {
             books.add(BukhariBook(
              id: idStr,
              nameEnglish: nameEng.toString(),
              nameArabic: nameAr,
              firstHadith: firstHadith,
              lastHadith: lastHadith,
              hadiths: bookHadiths,
            ));
          }
        }
      }

      _books = books;
      return _books;
  }

  /// Search hadiths by text
  /// Search hadiths by text or number
  List<BukhariHadith> searchHadith(String query) {
    if (query.isEmpty || _books.isEmpty) return [];
    
    final parsedNumber = int.tryParse(query.trim());
    final isNumber = parsedNumber != null;
    final q = _normalizeArabic(query);
    
    List<BukhariHadith> results = [];
    for (var book in _books) {
      for (var hadith in book.hadiths) {
        if (isNumber) {
          if (hadith.hadithNumber == parsedNumber) {
            results.add(hadith);
          }
        } else {
          final normalizedText = _normalizeArabic(hadith.text);
          if (normalizedText.contains(q)) {
            results.add(hadith);
          }
        }
      }
    }
    return results;
  }

  String _normalizeArabic(String text) {
    // Remove Tashkeel
    var str = text.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    // Normalize Alif
    str = str.replaceAll(RegExp(r'[إأآا]'), 'ا');
    // Normalize forms of Yaa
    str = str.replaceAll('ى', 'ي');
    // Normalize Taa Marbuta
    str = str.replaceAll('ة', 'ه');
    return str.toLowerCase();
  }

  /// Get book by ID
  BukhariBook? getBookById(String id) {
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }
}
