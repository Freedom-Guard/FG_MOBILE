import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:Freedom_Guard/ui/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyWelcomeScreen extends StatefulWidget {
  const PrivacyWelcomeScreen({super.key});

  @override
  State<PrivacyWelcomeScreen> createState() => _PrivacyWelcomeScreenState();
}

class _PrivacyWelcomeScreenState extends State<PrivacyWelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4;
  bool _acceptedPrivacy = false;
  String _language = 'fa';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('language') ?? 'fa';
    });
  }

  Future<void> _saveLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    setState(() {
      _language = lang;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 1 && !_acceptedPrivacy) {
      LogOverlay.showLog(
        _language == 'fa'
            ? 'لطفاً سیاست حریم خصوصی را بپذیرید'
            : 'Please accept the privacy policy',
        type: "error",
      );
      return;
    }
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _savePreferenceAndNavigate();
    }
  }

  Future<void> _savePreferenceAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_accepted', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _language == 'fa' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).primaryColorDark,
                Theme.of(context).primaryColor.withOpacity(0.9),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _language,
                          items: [
                            DropdownMenuItem(
                              value: 'fa',
                              child: Text('فارسی',
                                  style: TextStyle(
                                      fontFamily: 'Vazir',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.white)),
                            ),
                            DropdownMenuItem(
                              value: 'en',
                              child: Text('English',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      color: Colors.white)),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              _saveLanguage(value);
                            }
                          },
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: _language == 'fa' ? 'Vazir' : null,
                          ),
                          dropdownColor: Theme.of(context).primaryColorDark,
                          icon: Icon(Icons.language,
                              color: Colors.white, size: 24),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          LogOverlay.showLog(
                            _language == 'fa'
                                ? 'با ادامه دادن، سیاست حریم خصوصی را می‌پذیرید'
                                : 'By continuing, you accept the privacy policy',
                            type: "info",
                          );
                          _savePreferenceAndNavigate();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1.5),
                          ),
                          child: Text(
                            _language == 'fa' ? 'رد کردن' : 'Skip',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: _language == 'fa' ? 'Vazir' : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      _buildPage(
                        icon: Icons.shield_rounded,
                        title: _language == 'fa'
                            ? 'به گارد آزادی خوش آمدید'
                            : 'Welcome to Freedom Guard',
                        description: _language == 'fa'
                            ? 'حافظ آزادی شما در دنیای دیجیتال: VPN متن‌باز، سریع، نامحدود و امن'
                            : 'Your guardian of digital freedom: Open-source VPN, fast, unlimited, and secure',
                      ),
                      _buildPrivacyPage(),
                      _buildPage(
                        icon: Icons.rocket_launch_rounded,
                        title: _language == 'fa'
                            ? 'آزادی بدون مرز'
                            : 'Freedom Without Limits',
                        description: _language == 'fa'
                            ? 'پهنای باند نامحدود، سرورهای متنوع و سرعت بالا برای تجربه‌ای آزادانه'
                            : 'Unlimited bandwidth, diverse servers, and high speed for a seamless experience',
                      ),
                      _buildPage(
                        icon: Icons.star_rounded,
                        title: _language == 'fa'
                            ? 'آزاد و رایگان برای همیشه'
                            : 'Free Forever',
                        description: _language == 'fa'
                            ? 'بدون هزینه، بدون تبلیغات، بدون محدودیت – آزادی در دستان شما'
                            : 'No costs, no ads, no limits – true freedom in your hands',
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _totalPages,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: _currentPage == index
                                  ? Theme.of(context).colorScheme.secondary
                                  : Colors.white.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _nextPage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: _currentPage == 1 && !_acceptedPrivacy
                                ? Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withOpacity(0.3)
                                : Theme.of(context).colorScheme.secondary,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            _currentPage == _totalPages - 1
                                ? (_language == 'fa'
                                    ? 'شروع کنید'
                                    : 'Get Started')
                                : (_language == 'fa' ? 'بعدی' : 'Next'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: _language == 'fa' ? 'Vazir' : null,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 100,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: _language == 'fa' ? 'Vazir' : null,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontFamily: _language == 'fa' ? 'Vazir' : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPage() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_rounded,
              size: 100,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 24),
            Text(
              _language == 'fa'
                  ? 'حریم خصوصی، اولویت ماست'
                  : 'Privacy is Our Priority',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: _language == 'fa' ? 'Vazir' : null,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _language == 'fa'
                  ? 'داده‌های شما را ردیابی یا ذخیره نمی‌کنیم. آزادی با امنیت کامل.'
                  : 'We don’t track or store your data. True freedom with complete security.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                fontFamily: _language == 'fa' ? 'Vazir' : null,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 1.0,
                    child: Checkbox(
                      value: _acceptedPrivacy,
                      onChanged: (value) {
                        setState(() {
                          _acceptedPrivacy = value ?? false;
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.secondary,
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          _language == 'fa' ? 'من ' : 'I accept the ',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontFamily: _language == 'fa' ? 'Vazir' : null,
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final Uri url = Uri.parse(
                                'https://freedom-guard.github.io/privacy-terms.html');
                            try {
                              await launchUrl(url,
                                  mode: LaunchMode.externalApplication);
                            } catch (e) {
                              if (mounted) {
                                LogOverlay.showLog(
                                  _language == 'fa'
                                      ? 'خطا در باز کردن سیاست حریم خصوصی'
                                      : 'Error opening privacy policy',
                                  type: "error",
                                );
                              }
                            }
                          },
                          child: Text(
                            _language == 'fa'
                                ? 'سیاست حریم خصوصی'
                                : 'Privacy Policy',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                              fontFamily: _language == 'fa' ? 'Vazir' : null,
                            ),
                          ),
                        ),
                        Text(
                          _language == 'fa'
                              ? ' گارد آزادی را می‌پذیرم'
                              : ' of Freedom Guard',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontFamily: _language == 'fa' ? 'Vazir' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
