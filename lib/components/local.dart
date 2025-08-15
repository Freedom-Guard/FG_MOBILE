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
  final lang = await _settings.getValue('lang');
  final langCode = lang.isEmpty ? 'en' : lang;
  _dir = langCode == 'fa' ? 'rtl' : 'ltr';
  _translate = _allTranslations[langCode] ?? AllTr_en;
}

Map<String, Map<String, String>> _allTranslations = {
  'fa': AllTr_fa,
  'en': AllTr_en,
};

Map<String, String> AllTr_fa = {
  'freedom-guard': 'گارد آزادی',
  'freedom-link': 'پیوند آزادی',
  'proxy-mode': 'حالت پراکسی',
  'safe-mode': 'حالت ایمن',
  'browser': 'مرورگر',
  'notifications': 'آگاهی‌ها',
  'split-tunneling': 'تقسیم تونل',
  'guard-mode': 'حالت نگهبان',
  'manual-mode': 'حالت دستی',
  'bypass-lan': 'دور زدن لن',
  'block-ads-trackers': 'مسدود کردن تبلیغات',
  'quick-connect-sub': 'اتصال سریع',
  'manage-servers-page': 'مدیریت سرورها',
  'settings': 'تنظیمات',
  'language': 'زبان',
  'close': 'خروج',
  'change-language': '!زبان تغییر یافت',
  'speed-test-net': 'تست سرعت اینترنت',
  'start-test': 'شروع تست',
  'speed-test': 'تست سرعت',
  'add-server': 'افزودن سرور',
  'add': 'افزودن',
  'enter-server-config': 'پیکربندی سرور را وارد کنید',
  'add-server-clipboard': 'افزودن از کلیپ بورد',
  'add-server-file': 'افزودن از فایل',
  'add-server-text': 'افزودن دستی',
  'copy': 'کپی',
  'clear': 'پاک کردن',
  'logs': 'لاگ',
  'delete': 'حذف',
  'save': 'ذخیره',
  'cancel': 'لغو',
  'are-you-sure-you-want-to-delete-all-servers':
      'آیا مطمئن هستید که می‌خواهید همه سرورها را حذف کنید؟',
  'remove-all-servers': 'حذف همه کانفیگ ها',
  'choose-theme': 'انتخاب قالب',
  'servers': 'سرورها',
  'edit': 'ویرایش',
  'share': 'اشتراک‌گذاری',
  'qr-code': 'کد QR',
  'donate': 'حمایت',
  'edit-server': 'ویرایش سرور',
  'search-servers': 'جستجوی سرورها...',
  'delete-server': 'حذف سرور',
  'refresh': "تازه سازی",
  'are-you-sure-you-want-to-delete-this-server':
      'آیا از حذف این سرور مطمئن هستید؟',
  'more-options': 'گزینه‌های بیشتر',
  'refresh-subscription': 'به‌روزرسانی اشتراک',
  'encrypt-decrypt': 'رمزگذاری/رمزگشایی',
  'delete-all-servers': 'حذف همه سرورها',
  'show-system-apps': 'نمایش برنامه های سیستمی',
  'about-app': 'گارد آزادی ابزاری متن باز برای عبور از فیلترینگ اینترنت است'
};

Map<String, String> AllTr_en = {
  'freedom-guard': 'Freedom Guard',
  'freedom-link': 'Freedom Link',
  'split-tunneling': 'Split Tunneling',
  'proxy-mode': 'Proxy mode',
  'safe-mode': "Safe Mode",
  'browser': 'Browser',
  'notifications': 'Notifications',
  'guard-mode': 'Guard mode',
  'manual-mode': 'Manual mode',
  'bypass-lan': 'Bypass LAN',
  'block-ads-trackers': 'Block Ads and Trackers',
  'quick-connect-sub': 'Quick Connect',
  'manage-servers-page': 'Manage Servers',
  'settings': 'Settings',
  'language': 'Language',
  'close': 'Close',
  'change-language': 'Language changed!',
  'speed-test-net': 'Internet Speed Test',
  'start-test': 'Start Test',
  'speed-test': 'Speed Test',
  'add-server': 'Add Server',
  'add': 'Add',
  'enter-server-config': 'Enter server configuration',
  'add-server-clipboard': 'Add from Clipboard',
  'add-server-file': 'Add from file',
  'add-server-text': 'Add manually',
  'copy': 'Copy',
  'clear': 'Clear',
  'logs': 'Logs',
  'delete': 'Delete',
  'save': 'Save',
  'cancel': 'Cancel',
  'are-you-sure-you-want-to-delete-all-servers':
      'Are you sure you want to delete all servers?',
  'remove-all-servers': 'Remove all servers',
  'choose-theme': 'Choose theme',
  'servers': 'Servers',
  'edit': 'Edit',
  'share': 'Share',
  'qr-code': 'QR Code',
  'donate': 'Donate',
  'edit-server': 'Edit Server',
  'delete-server': 'Delete Server',
  'refresh': 'Refresh',
  'search-servers': 'Search servers...',
  'are-you-sure-you-want-to-delete-this-server':
      'Are you sure you want to delete this server?',
  'more-options': 'More Options',
  'refresh-subscription': 'Refresh Subscription',
  'encrypt-decrypt': 'Encrypt/Decrypt',
  'delete-all-servers': 'Delete All Servers',
  'show-system-apps': 'Show system Apps',
  'about-app':
      'Freedom Guard is an open-source tool to bypass internet censorship.'
};
