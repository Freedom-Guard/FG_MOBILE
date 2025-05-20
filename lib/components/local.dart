import 'package:Freedom_Guard/components/settings.dart';

Map<String, String> translate = {};
Settings settings = new Settings();
String tr(String key) {
  return translate[key] ?? key;
}
void initLocal(String langCode) {
  translate = _allTranslations[langCode] ?? AllTr_en;
}

Future<String> getLang() async {
  return (await settings.getValue("lang") == ""
      ? "en"
      : await settings.getValue("lang"));
}

Future<void> loadLang_Wi() async {
  String lang = await getLang();
  initLocal(lang);
}

Map<String, Map<String, String>> _allTranslations = {
  "fa": AllTr_fa,
  "en": AllTr_en,
};

Map<String, String> AllTr_fa = {
  'manage-servers-page': "مدیریت سرورها",
  'settings': 'تنظیمات',
  'language': 'زبان',
  'about-app': 'گارد آزادی ابزاری متن باز برای عبور از فیلترینگ اینترنت است'
};
Map<String, String> AllTr_en = {
  'manage-servers-page': "Manage Servers",
  'settings': 'Settings',
  'language': "Language",
  'about-app':
      'Freedom Guard is an open-source tool to bypass internet censorship.'
};
