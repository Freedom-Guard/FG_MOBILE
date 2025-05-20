import 'package:Freedom_Guard/components/settings.dart';

final Settings _settings = Settings();
Map<String, String> _translate = AllTr_en;

String tr(String key) {
  return _translate[key] ?? key;
}

Future<void> initTranslations() async {
  final lang = await _settings.getValue("lang");
  final langCode = lang.isEmpty ? "en" : lang;
  _translate = _allTranslations[langCode] ?? AllTr_en;
}

Map<String, Map<String, String>> _allTranslations = {
  "fa": AllTr_fa,
  "en": AllTr_en,
};

Map<String, String> AllTr_fa = {
  'manage-servers-page': "مدیریت سرورها",
  'settings': 'تنظیمات',
  'language': 'زبان',
  'change-language': '!زبان تغییر یافت',
  'speed-test-net': "تست سرعت اینترنت",
  'start-test': 'شروع تست',
  'speed-test':'تست سرعت',
  'about-app': 'گارد آزادی ابزاری متن باز برای عبور از فیلترینگ اینترنت است'
};

Map<String, String> AllTr_en = {
  'manage-servers-page': "Manage Servers",
  'settings': 'Settings',
  'language': "Language",
  'change-language': 'Language changed!',
  'speed-test-net': 'Internet Speed Test',
  'start-test': 'Start Test',
  'speed-test': 'Speed Test',
  'about-app':
      'Freedom Guard is an open-source tool to bypass internet censorship.'
};
