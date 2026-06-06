class BukhariHadith {
  final int hadithNumber;
  final int arabicNumber;
  final String text;
  final String referenceBook;
  final String referenceHadith;

  BukhariHadith({
    required this.hadithNumber,
    required this.arabicNumber,
    required this.text,
    required this.referenceBook,
    required this.referenceHadith,
  });

  factory BukhariHadith.fromJson(Map<String, dynamic> json) {
    return BukhariHadith(
      hadithNumber: (json['hadithnumber'] is num) ? (json['hadithnumber'] as num).toInt() : 0,
      arabicNumber: (json['arabicnumber'] is num) ? (json['arabicnumber'] as num).toInt() : 0,
      text: json['text'] ?? '',
      referenceBook: json['reference']?['book']?.toString() ?? '',
      referenceHadith: json['reference']?['hadith']?.toString() ?? '',
    );
  }
}

class BukhariBook {
  final String id;
  final String nameEnglish;
  final String nameArabic;
  final int firstHadith;
  final int lastHadith;
  final List<BukhariHadith> hadiths;

  BukhariBook({
    required this.id,
    required this.nameEnglish,
    required this.nameArabic,
    required this.firstHadith,
    required this.lastHadith,
    required this.hadiths,
  });
}
