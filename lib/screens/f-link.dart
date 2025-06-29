import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/f-link.dart';
import 'package:Freedom_Guard/components/local.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumDonateConfigPage extends StatefulWidget {
  @override
  State<PremiumDonateConfigPage> createState() =>
      _PremiumDonateConfigPageState();
}

class _PremiumDonateConfigPageState extends State<PremiumDonateConfigPage>
    with SingleTickerProviderStateMixin {
  String? selectedCore = "Mobile Vibe Core";
  final TextEditingController configController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController telegramLinkController = TextEditingController();
  bool isButtonHovered = false;
  bool isBackButtonHovered = false;
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    configController.dispose();
    messageController.dispose();
    telegramLinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
        textDirection:
            getDir() == "rtl" ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(
          body: Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
              minWidth: MediaQuery.of(context).size.width,
            ),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  Colors.deepPurple.shade900,
                  Colors.purple.shade800,
                  Colors.blue.shade900,
                  Colors.cyan.shade400.withOpacity(0.6),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: GestureDetector(
                            onTapDown: (_) =>
                                setState(() => isBackButtonHovered = true),
                            onTapUp: (_) =>
                                setState(() => isBackButtonHovered = false),
                            onTapCancel: () =>
                                setState(() => isBackButtonHovered = false),
                            onTap: () => Navigator.pop(context),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              transform: Matrix4.translationValues(
                                  isBackButtonHovered ? -5 : 0, 0, 0),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: isBackButtonHovered
                                      ? [
                                          Colors.purple.shade400,
                                          Colors.cyan.shade400
                                        ]
                                      : [
                                          Colors.purple.shade800
                                              .withOpacity(0.6),
                                          Colors.cyan.shade600.withOpacity(0.6)
                                        ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.shade400.withOpacity(
                                        isBackButtonHovered ? 0.7 : 0.4),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(Icons.arrow_back_ios_new,
                                  color: Colors.white, size: 26),
                            ),
                          ),
                        ),
                      ),
                      Center(
                          child: Icon(Icons.volunteer_activism,
                              color: Colors.redAccent, size: 44)),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Row(
                            children: [
                              const SizedBox(width: 12),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Text(
                                    "آزادی در دستان توست",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.vazirmatn(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 20,
                                          color: Colors.purple.shade900
                                              .withOpacity(0.6),
                                          offset: Offset(3, 3),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Center(
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Text(
                              "کانفیگ را وارد کنید، هسته را انتخاب کنید و با اهدای آن، به پایداری گارد آزادی کمک کنید",
                              style: GoogleFonts.vazirmatn(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.85),
                                fontWeight: FontWeight.w300,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade900.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Colors.purple.shade900.withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: -5),
                                BoxShadow(
                                    color:
                                        Colors.cyan.shade600.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: -3),
                              ],
                              border: Border.all(
                                  color: Colors.cyan.shade400.withOpacity(0.4),
                                  width: 2),
                            ),
                            child: TextField(
                              controller: configController,
                              maxLines: 6,
                              style: GoogleFonts.vazirmatn(
                                  color: Colors.white, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'کانفیگ را اینجا وارد کن',
                                hintStyle: GoogleFonts.vazirmatn(
                                    color: Colors.white38, fontSize: 16),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none),
                                contentPadding: EdgeInsets.all(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade900.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Colors.purple.shade900.withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: -5),
                                BoxShadow(
                                    color:
                                        Colors.cyan.shade600.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: -3),
                              ],
                              border: Border.all(
                                  color: Colors.cyan.shade400.withOpacity(0.4),
                                  width: 2),
                            ),
                            child: TextField(
                              controller: messageController,
                              maxLines: 3,
                              style: GoogleFonts.vazirmatn(
                                  color: Colors.white, fontSize: 16),
                              decoration: InputDecoration(
                                hintText:
                                    'پیام تبلیغاتی خود را وارد کنید (اختیاری)',
                                hintStyle: GoogleFonts.vazirmatn(
                                    color: Colors.white38, fontSize: 16),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none),
                                contentPadding: EdgeInsets.all(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade900.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                    color:
                                        Colors.purple.shade900.withOpacity(0.5),
                                    blurRadius: 30,
                                    spreadRadius: -5),
                                BoxShadow(
                                    color:
                                        Colors.cyan.shade600.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: -3),
                              ],
                              border: Border.all(
                                  color: Colors.cyan.shade400.withOpacity(0.4),
                                  width: 2),
                            ),
                            child: TextField(
                              controller: telegramLinkController,
                              maxLines: 1,
                              style: GoogleFonts.vazirmatn(
                                  color: Colors.white, fontSize: 16),
                              decoration: InputDecoration(
                                hintText: 'لینک کانال تلگرام (اختیاری)',
                                hintStyle: GoogleFonts.vazirmatn(
                                    color: Colors.white38, fontSize: 16),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                    borderSide: BorderSide.none),
                                contentPadding: EdgeInsets.all(20),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      Center(
                        child: GestureDetector(
                          onTapDown: (_) =>
                              setState(() => isButtonHovered = true),
                          onTapUp: (_) =>
                              setState(() => isButtonHovered = false),
                          onTapCancel: () =>
                              setState(() => isButtonHovered = false),
                          onTap: () async {
                            if (selectedCore != null &&
                                configController.text.isNotEmpty) {
                              bool success = await donateCONFIG(
                                configController.text,
                                core: selectedCore!,
                                message: messageController.text,
                                telegramLink: telegramLinkController.text,
                              ).timeout(Duration(seconds: 14), onTimeout: () {
                                LogOverlay.showLog("Connection timed out",
                                    type: "error");
                                return false;
                              });
                            } else {}
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            transform: Matrix4.translationValues(
                                0, isButtonHovered ? -5 : 0, 0),
                            padding: EdgeInsets.symmetric(
                                horizontal: 60, vertical: 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isButtonHovered
                                    ? [
                                        Colors.purple.shade400,
                                        Colors.cyan.shade400
                                      ]
                                    : [
                                        Colors.purple.shade700,
                                        Colors.cyan.shade600
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.shade400
                                      .withOpacity(isButtonHovered ? 0.7 : 0.4),
                                  blurRadius: 25,
                                  spreadRadius: 3,
                                ),
                                BoxShadow(
                                  color: Colors.cyan.shade400
                                      .withOpacity(isButtonHovered ? 0.5 : 0.3),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Text(
                              'اهدا',
                              style: GoogleFonts.vazirmatn(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ));
  }
}
