import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyWelcomeScreen extends StatefulWidget {
  const PrivacyWelcomeScreen({Key? key}) : super(key: key);

  @override
  State<PrivacyWelcomeScreen> createState() => _PrivacyWelcomeScreenState();
}

class _PrivacyWelcomeScreenState extends State<PrivacyWelcomeScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  final int _totalPages = 4;
  bool _acceptedPrivacy = false;
  bool _showScrollHint = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  String _language = 'fa';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController, curve: Curves.easeInOutCubic),
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && _showScrollHint) {
        setState(() {
          _showScrollHint = false;
        });
      }
    });
    _animationController.forward();
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
    _animationController.dispose();
    _pageController.dispose();
    _scrollController.dispose();
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
        curve: Curves.easeInOutCubic,
      );
    } else {
      _savePreferenceAndNavigate();
    }
  }

  void _savePreferenceAndNavigate() async {
    if (_acceptedPrivacy) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('privacy_accepted', true);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainScreen()),
        );
      }
    } else {
      LogOverlay.showLog(
        _language == 'fa'
            ? 'لطفاً سیاست حریم خصوصی را بپذیرید'
            : 'Please accept the privacy policy',
        type: "error",
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
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Theme.of(context).primaryColorDark.withOpacity(0.95),
                Theme.of(context).primaryColor.withOpacity(0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton<String>(
                        value: _language,
                        items: [
                          DropdownMenuItem(
                              value: 'fa',
                              child: Text('فارسی',
                                  style: TextStyle(fontFamily: 'Vazir'))),
                          DropdownMenuItem(value: 'en', child: Text('English')),
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
                        dropdownColor:
                            Theme.of(context).primaryColorDark.withOpacity(0.9),
                        icon: Icon(Icons.language,
                            color: Colors.white.withOpacity(0.8)),
                        underline: Container(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      TextButton(
                        onPressed: _savePreferenceAndNavigate,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          textStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: _language == 'fa' ? 'Vazir' : null,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                            side: BorderSide(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                        ),
                        child: Text(_language == 'fa' ? 'رد کردن' : 'Skip'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: PageView(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (int page) {
                        setState(() {
                          _currentPage = page;
                          _showScrollHint = page == 1;
                        });
                        _animationController.reset();
                        _animationController.forward();
                      },
                      children: [
                        _buildWelcomePage(),
                        _buildPrivacyPage(),
                        _buildNoLimitsPage(),
                        _buildFreeToUsePage(),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32.0, vertical: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _totalPages,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: _currentPage == index ? 30 : 12,
                            height: 12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: LinearGradient(
                                colors: _currentPage == index
                                    ? [
                                        Theme.of(context).colorScheme.secondary,
                                        Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withOpacity(0.7),
                                      ]
                                    : [
                                        Colors.white.withOpacity(0.3),
                                        Colors.white.withOpacity(0.2),
                                      ],
                              ),
                              boxShadow: [
                                if (_currentPage == index)
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withOpacity(0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _currentPage == 1 && !_acceptedPrivacy
                              ? null
                              : _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 8,
                            shadowColor: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.6),
                            disabledBackgroundColor: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.3),
                          ),
                          child: Text(
                            _currentPage == _totalPages - 1
                                ? (_language == 'fa'
                                    ? 'شروع کنید'
                                    : 'Get Started')
                                : (_language == 'fa' ? 'بعدی' : 'Next'),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
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

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Hero(
              tag: 'shield_icon',
              child: Icon(
                Icons.shield_rounded,
                size: 150,
                color: Theme.of(context).colorScheme.secondary,
                shadows: [
                  Shadow(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _language == 'fa'
                  ? 'به گارد آزادی خوش آمدید'
                  : 'Welcome to Freedom Guard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: _language == 'fa' ? 'Vazir' : null,
                shadows: [
                  Shadow(
                    blurRadius: 6,
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              _language == 'fa'
                  ? 'حافظ آزادی شما در دنیای دیجیتال: VPN متن‌باز، سریع، نامحدود و امن'
                  : 'Your guardian of digital freedom: Open-source VPN, fast, unlimited, and secure',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: _language == 'fa' ? 'Vazir' : null,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.lock_rounded,
                  size: 150,
                  color: Theme.of(context).colorScheme.secondary,
                  shadows: [
                    Shadow(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  _language == 'fa'
                      ? 'حریم خصوصی، اولویت ماست'
                      : 'Privacy is Our Priority',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontFamily: _language == 'fa' ? 'Vazir' : null,
                    shadows: [
                      Shadow(
                        blurRadius: 6,
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Text(
                  _language == 'fa'
                      ? 'داده‌های شما را ردیابی یا ذخیره نمی‌کنیم. آزادی واقعی با امنیت کامل.'
                      : 'We don’t track or store your data. True freedom with complete security.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                        fontFamily: _language == 'fa' ? 'Vazir' : null,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptedPrivacy,
                      onChanged: (value) {
                        setState(() {
                          _acceptedPrivacy = value ?? false;
                        });
                      },
                      activeColor: Theme.of(context).colorScheme.secondary,
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    Expanded(
                      child: Wrap(
                        alignment: _language == 'fa'
                            ? WrapAlignment.start
                            : WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          Text(
                            _language == 'fa' ? 'من ' : 'I accept the ',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontFamily:
                                      _language == 'fa' ? 'Vazir' : null,
                                ),
                          ),
                          InkWell(
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
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontSize: 16,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    decoration: TextDecoration.underline,
                                    decorationColor:
                                        Theme.of(context).colorScheme.secondary,
                                    fontFamily:
                                        _language == 'fa' ? 'Vazir' : null,
                                  ),
                            ),
                          ),
                          Text(
                            _language == 'fa'
                                ? ' گارد آزادی را می‌پذیرم'
                                : ' of Freedom Guard',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontFamily:
                                      _language == 'fa' ? 'Vazir' : null,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          if (_currentPage == 1 && _showScrollHint)
            Positioned(
              bottom: 20,
              right: _language == 'fa' ? 20 : null,
              left: _language == 'en' ? 20 : null,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: 20,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _language == 'fa'
                                ? 'برای پذیرش اسکرول کنید'
                                : 'Scroll to accept',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              fontFamily: _language == 'fa' ? 'Vazir' : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoLimitsPage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.rocket_launch_rounded,
              size: 150,
              color: Theme.of(context).colorScheme.secondary,
              shadows: [
                Shadow(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              _language == 'fa' ? 'آزادی بدون مرز' : 'Freedom Without Limits',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: _language == 'fa' ? 'Vazir' : null,
                shadows: [
                  Shadow(
                    blurRadius: 6,
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              _language == 'fa'
                  ? 'پهنای باند نامحدود، سرورهای متنوع و سرعت بالا برای تجربه‌ای آزادانه'
                  : 'Unlimited bandwidth, diverse servers, and high speed for a seamless experience',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: _language == 'fa' ? 'Vazir' : null,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFreeToUsePage() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Icon(
              Icons.star_rounded,
              size: 150,
              color: Theme.of(context).colorScheme.secondary,
              shadows: [
                Shadow(
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              _language == 'fa' ? 'آزاد و رایگان برای همیشه' : 'Free Forever',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontFamily: _language == 'fa' ? 'Vazir' : null,
                shadows: [
                  Shadow(
                    blurRadius: 6,
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              _language == 'fa'
                  ? 'بدون هزینه، بدون تبلیغات، بدون محدودیت – آزادی در دستان شما'
                  : 'No costs, no ads, no limits – true freedom in your hands',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                    fontFamily: _language == 'fa' ? 'Vazir' : null,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
