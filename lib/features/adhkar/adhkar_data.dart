import 'package:flutter/widgets.dart';

class AdhkarModel {
  final String title;
  final List<DhikrItem> items;

  AdhkarModel({required this.title, required this.items});

  String getLocalizedTitle(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'en') {
      switch (title) {
        case 'أذكار الصباح': return 'Morning Adhkar';
        case 'أذكار المساء': return 'Evening Adhkar';
        case 'أذكار بعد الصلاة': return 'Post-Prayer Adhkar';
        case 'أذكار النوم': return 'Sleep Adhkar';
        case 'أذكار الاستيقاظ': return 'Waking Up Adhkar';
        case 'أذكار البيت والمسجد': return 'Home & Mosque Adhkar';
        case 'أذكار شاملة': return 'General Adhkar';
      }
    } else if (locale == 'fr') {
      switch (title) {
        case 'أذكار الصباح': return 'Adhkar du Matin';
        case 'أذكار المساء': return 'Adhkar du Soir';
        case 'أذكار بعد الصلاة': return 'Adhkar après la Prière';
        case 'أذكار النوم': return 'Adhkar du Sommeil';
        case 'أذكار الاستيقاظ': return 'Adhkar du Réveil';
        case 'أذكار البيت والمسجد': return 'Adhkar Maison & Mosquée';
        case 'أذكار شاملة': return 'Adhkar Généraux';
      }
    }
    return title;
  }
}

class DhikrItem {
  final String text;
  final int count;
  final String? reference;
  int currentCount;

  DhikrItem({
    required this.text,
    required this.count,
    this.reference,
    this.currentCount = 0,
  });

  String? getLocalizedReference(BuildContext context) {
    if (reference == null) return null;
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'en') {
      switch (reference) {
        case 'رواه مسلم': return 'Narrated by Muslim';
        case 'رواه الترمذي': return 'Narrated by At-Tirmidhi';
        case 'سيد الاستغفار': return 'Chief of Istighfar';
      }
    } else if (locale == 'fr') {
      switch (reference) {
        case 'رواه مسلم': return 'Rapporté par Mouslim';
        case 'رواه الترمذي': return 'Rapporté par At-Tirmidhi';
        case 'سيد الاستغفار': return 'Le maître de l\'Istighfar';
      }
    }
    return reference;
  }
}

final List<AdhkarModel> adhkarData = [
  AdhkarModel(
    title: 'أذكار الصباح',
    items: [
      DhikrItem(
        text:
            'أصبحنا وأصبح الملك لله، والحمد لله، لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
        count: 1,
        reference: 'رواه مسلم',
      ),
      DhikrItem(
        text: 'اللهم بك أصبحنا، وبك أمسينا، وبك نحيا، وبك نموت، وإليك النشور.',
        count: 1,
        reference: 'رواه الترمذي',
      ),
      DhikrItem(
        text:
            'اللهم أنت ربي لا إله إلا أنت، خلقتني وأنا عبدك، وأنا على عهدك ووعدك ما استطعت، أعوذ بك من شر ما صنعت، أبوء لك بنعمتك علي، وأبوء بذنبي، فاغفر لي فإنه لا يغفر الذنوب إلا أنت.',
        count: 1,
        reference: 'سيد الاستغفار',
      ),
      DhikrItem(
        text:
            'رضيت بالله رباً، وبالإسلام ديناً، وبمحمد صلى الله عليه وسلم نبياً.',
        count: 3,
      ),
      DhikrItem(
        text:
            'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم.',
        count: 3,
      ),
      DhikrItem(text: 'أعوذ بكلمات الله التامات من شر ما خلق.', count: 3),
      DhikrItem(
        text: 'اللهم إني أسألك العفو والعافية في الدنيا والآخرة.',
        count: 1,
      ),
      DhikrItem(
        text:
            'اللهم إني أعوذ بك من الهم والحزن، والعجز والكسل، والبخل والجبن، وضلع الدين وغلبة الرجال.',
        count: 1,
      ),
      DhikrItem(
        text: 'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم.',
        count: 7,
      ),
      DhikrItem(text: 'سبحان الله وبحمده.', count: 100),
      DhikrItem(
        text:
            'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
        count: 100,
      ),
      DhikrItem(text: 'أستغفر الله وأتوب إليه.', count: 100),
    ],
  ),
  AdhkarModel(
    title: 'أذكار المساء',
    items: [
      DhikrItem(
        text:
            'أمسينا وأمسى الملك لله، والحمد لله، لا إله إلا الله وحده لا شريك له.',
        count: 1,
      ),
      DhikrItem(
        text: 'اللهم بك أمسينا، وبك أصبحنا، وبك نحيا، وبك نموت، وإليك المصير.',
        count: 1,
      ),
      DhikrItem(
        text:
            'اللهم أنت ربي لا إله إلا أنت، خلقتني وأنا عبدك، وأنا على عهدك ووعدك ما استطعت، أعوذ بك من شر ما صنعت، أبوء لك بنعمتك علي، وأبوء بذنبي، فاغفر لي فإنه لا يغفر الذنوب إلا أنت.',
        count: 1,
      ),
      DhikrItem(
        text:
            'رضيت بالله رباً، وبالإسلام ديناً، وبمحمد صلى الله عليه وسلم نبياً.',
        count: 3,
      ),
      DhikrItem(
        text:
            'بسم الله الذي لا يضر مع اسمه شيء في الأرض ولا في السماء وهو السميع العليم.',
        count: 3,
      ),
      DhikrItem(text: 'أعوذ بكلمات الله التامات من شر ما خلق.', count: 3),
      DhikrItem(
        text: 'حسبي الله لا إله إلا هو عليه توكلت وهو رب العرش العظيم.',
        count: 7,
      ),
      DhikrItem(text: 'سبحان الله وبحمده.', count: 100),
      DhikrItem(
        text:
            'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
        count: 100,
      ),
      DhikrItem(text: 'اللهم صل وسلم على نبينا محمد.', count: 10),
    ],
  ),
  AdhkarModel(
    title: 'أذكار بعد الصلاة',
    items: [
      DhikrItem(text: 'أستغفر الله.', count: 3),
      DhikrItem(
        text: 'اللهم أنت السلام ومنك السلام، تباركت يا ذا الجلال والإكرام.',
        count: 1,
      ),
      DhikrItem(
        text:
            'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
        count: 1,
      ),
      DhikrItem(
        text:
            'اللهم لا مانع لما أعطيت، ولا معطي لما منعت، ولا ينفع ذا الجد منك الجد.',
        count: 1,
      ),
      DhikrItem(text: 'سبحان الله.', count: 33),
      DhikrItem(text: 'الحمد لله.', count: 33),
      DhikrItem(text: 'الله أكبر.', count: 33),
      DhikrItem(
        text:
            'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
        count: 1,
      ),
      DhikrItem(text: 'اللهم أعني على ذكرك وشكرك وحسن عبادتك.', count: 1),
    ],
  ),
  AdhkarModel(
    title: 'أذكار النوم',
    items: [
      DhikrItem(text: 'باسمك اللهم أموت وأحيا.', count: 1),
      DhikrItem(text: 'اللهم قني عذابك يوم تبعث عبادك.', count: 3),
      DhikrItem(text: 'سبحان الله.', count: 33),
      DhikrItem(text: 'الحمد لله.', count: 33),
      DhikrItem(text: 'الله أكبر.', count: 34),
      DhikrItem(
        text:
            'اللهم أسلمت نفسي إليك، وفوضت أمري إليك، وألجأت ظهري إليك، رغبة ورهبة إليك.',
        count: 1,
      ),
      DhikrItem(text: 'آية الكرسي.', count: 1),
      DhikrItem(text: 'المعوذات: الإخلاص والفلق والناس.', count: 3),
    ],
  ),
  AdhkarModel(
    title: 'أذكار الاستيقاظ',
    items: [
      DhikrItem(
        text: 'الحمد لله الذي أحيانا بعد ما أماتنا وإليه النشور.',
        count: 1,
      ),
      DhikrItem(
        text: 'الحمد لله الذي عافاني في جسدي، ورد علي روحي، وأذن لي بذكره.',
        count: 1,
      ),
      DhikrItem(
        text:
            'لا إله إلا الله وحده لا شريك له، له الملك وله الحمد وهو على كل شيء قدير.',
        count: 1,
      ),
      DhikrItem(
        text: 'سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر.',
        count: 1,
      ),
    ],
  ),
  AdhkarModel(
    title: 'أذكار البيت والمسجد',
    items: [
      DhikrItem(
        text: 'بسم الله توكلت على الله، ولا حول ولا قوة إلا بالله.',
        count: 1,
      ),
      DhikrItem(
        text:
            'اللهم إني أعوذ بك أن أضل أو أضل، أو أزل أو أزل، أو أظلم أو أظلم، أو أجهل أو يجهل علي.',
        count: 1,
      ),
      DhikrItem(text: 'اللهم افتح لي أبواب رحمتك.', count: 1),
      DhikrItem(text: 'اللهم إني أسألك من فضلك.', count: 1),
      DhikrItem(text: 'بسم الله، والصلاة والسلام على رسول الله.', count: 1),
      DhikrItem(text: 'رب اغفر لي ذنبي وافتح لي أبواب فضلك.', count: 1),
    ],
  ),
  AdhkarModel(
    title: 'أذكار شاملة',
    items: [
      DhikrItem(text: 'سبحان الله وبحمده، سبحان الله العظيم.', count: 100),
      DhikrItem(text: 'لا حول ولا قوة إلا بالله.', count: 100),
      DhikrItem(text: 'اللهم صل وسلم على نبينا محمد.', count: 100),
      DhikrItem(text: 'أستغفر الله العظيم وأتوب إليه.', count: 100),
      DhikrItem(text: 'اللهم إنك عفو تحب العفو فاعف عني.', count: 7),
      DhikrItem(
        text: 'ربنا آتنا في الدنيا حسنة وفي الآخرة حسنة وقنا عذاب النار.',
        count: 7,
      ),
      DhikrItem(
        text: 'يا حي يا قيوم برحمتك أستغيث، أصلح لي شأني كله.',
        count: 3,
      ),
      DhikrItem(
        text: 'اللهم إني أسألك علماً نافعاً، ورزقاً طيباً، وعملاً متقبلاً.',
        count: 1,
      ),
      DhikrItem(text: 'اللهم مصرف القلوب صرف قلوبنا على طاعتك.', count: 1),
      DhikrItem(text: 'رب اغفر لي وتب علي إنك أنت التواب الرحيم.', count: 100),
    ],
  ),
];
