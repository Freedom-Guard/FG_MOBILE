import 'package:Freedom_Guard/components/settings.dart';

final Settings _settings = Settings();
Map<String, String> _translate = AllTr_en;
String _dir = 'ltr';
String tr(String key) {
  return _translate[key] ?? key;
}

String getDir() {
  return _dir;
}

Future<void> initTranslations() async {
  final lang = await _settings.getValue("lang");
  final langCode = lang.isEmpty ? "en" : lang;
  _dir = langCode == "fa" ? "rtl" : "ltr";
  _translate = _allTranslations[langCode] ?? AllTr_en;
}

Map<String, Map<String, String>> _allTranslations = {
  "fa": AllTr_fa,
  "en": AllTr_en,
};

Map<String, String> AllTr_fa = {
  'freedom-guard': "گارد آزادی",
  'freedom-link': "پیوند آزادی",
  'guard-mode': "حالت نگهبان",
  'bypass-lan': "دور زدن لن",
  'block-ads-trackers': "مسدود کردن تبلیغات",
  'quick-connect-sub': 'اتصال سریع (Sub)',
  'manage-servers-page': "مدیریت سرورها",
  'settings': 'تنظیمات',
  'language': 'زبان',
  'close': 'خروج',
  'change-language': '!زبان تغییر یافت',
  'speed-test-net': "تست سرعت اینترنت",
  'start-test': 'شروع تست',
  'speed-test': "تست سرعت",
  'add-server': "افزودن سرور",
  'add-server-clipboard': "افزودن از کلیپ بورد",
  'add-server-file': "افزودن از فایل",
  'add-server-text': "افزودن دستی",
  'copy': "کپی",
  'clear': 'پاک کردن',
  'logs': 'لاگ',
  'choose-theme': "انتخاب قالب",
  'show-system-apps': 'نمایش برنامه های سیستمی',
  'about-app': 'گارد آزادی ابزاری متن باز برای عبور از فیلترینگ اینترنت است'
};

Map<String, String> AllTr_en = {
  'freedom-guard': "Freedom Guard",
  'freedom-link': "Freedom Link",
  'guard-mode': "Guard Mode",
  'bypass-lan': "Bypass LAN",
  'block-ads-trackers': "Block Ads and Trackers",
  'quick-connect-sub': 'Quick Connect (Sub)',
  'manage-servers-page': "Manage Servers",
  'settings': 'Settings',
  'language': "Language",
  'close': 'Close',
  'change-language': 'Language changed!',
  'speed-test-net': 'Internet Speed Test',
  'start-test': 'Start Test',
  'speed-test': "Speed Test",
  'add-server': "Add Server",
  'add-server-clipboard': "Add from Clipboard",
  'add-server-file': "Add from file",
  'add-server-text': "Add manually",
  'copy': "Copy",
  'clear': 'Clear',
  'logs': 'Logs',
  'choose-theme': "Choose theme",
  'show-system-apps': 'Show system Apps',
  'about-app':
      'Freedom Guard is an open-source tool to bypass internet censorship.'
};
