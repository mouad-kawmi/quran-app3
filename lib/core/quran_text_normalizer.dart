class QuranTextNormalizer {
  QuranTextNormalizer._();

  static final RegExp _diacritics = RegExp(
    r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]',
  );

  static String normalize(String value) {
    return value
        .replaceAll(_diacritics, '')
        .replaceAll('\u0640', '')
        .replaceAll(RegExp('[\u0625\u0623\u0622\u0671]'), '\u0627')
        .replaceAll('\u0649', '\u064a')
        .replaceAll('\u0626', '\u064a')
        .replaceAll('\u0624', '\u0648')
        .replaceAll('\u0629', '\u0647')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
