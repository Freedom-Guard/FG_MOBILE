import 'dart:ui';
import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:Freedom_Guard/components/f-link.dart';
import 'package:Freedom_Guard/core/local.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PremiumDonateConfigPage extends StatefulWidget {
  @override
  State<PremiumDonateConfigPage> createState() =>
      _PremiumDonateConfigPageState();
}

class _PremiumDonateConfigPageState extends State<PremiumDonateConfigPage>
    with SingleTickerProviderStateMixin {
  String? selectedCore = "VIBE";
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
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
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

  Widget buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(25),
            border:
                Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: getDir() == "rtl" ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F2027),
                Color(0xFF203A43),
                Color(0xFF2C5364),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTapDown: (_) =>
                              setState(() => isBackButtonHovered = true),
                          onTapUp: (_) =>
                              setState(() => isBackButtonHovered = false),
                          onTapCancel: () =>
                              setState(() => isBackButtonHovered = false),
                          onTap: () => Navigator.pop(context),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            transform: Matrix4.translationValues(
                                isBackButtonHovered ? -4 : 0, 0, 0),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isBackButtonHovered
                                    ? [Colors.pinkAccent, Colors.cyanAccent]
                                    : [
                                        Colors.purple.shade700,
                                        Colors.blue.shade600
                                      ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.arrow_back_ios_new,
                                color: Colors.white, size: 26),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          Icon(Icons.favorite_rounded,
                              color: Colors.redAccent.shade200, size: 60),
                          const SizedBox(height: 15),
                          Text(
                            "آزادی در دستان توست ✨",
                            style: GoogleFonts.vazirmatn(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  blurRadius: 25,
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(2, 2),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "با اهدای کانفیگ، به پایداری گارد آزادی کمک کن",
                            style: GoogleFonts.vazirmatn(
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                  buildGlassContainer(
                    child: TextField(
                      controller: configController,
                      maxLines: 6,
                      style: GoogleFonts.vazirmatn(
                          color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: '🔒 کانفیگ را اینجا وارد کن',
                        hintStyle: GoogleFonts.vazirmatn(
                            color: Colors.white54, fontSize: 16),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildGlassContainer(
                    child: TextField(
                      controller: messageController,
                      maxLines: 3,
                      style: GoogleFonts.vazirmatn(
                          color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: '💬 پیام تبلیغاتی خود را بنویسید (اختیاری)',
                        hintStyle: GoogleFonts.vazirmatn(
                            color: Colors.white54, fontSize: 16),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  buildGlassContainer(
                    child: TextField(
                      controller: telegramLinkController,
                      maxLines: 1,
                      style: GoogleFonts.vazirmatn(
                          color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: '📢 لینک کانال تلگرام (اختیاری)',
                        hintStyle: GoogleFonts.vazirmatn(
                            color: Colors.white54, fontSize: 16),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  GestureDetector(
                    onTapDown: (_) => setState(() => isButtonHovered = true),
                    onTapUp: (_) => setState(() => isButtonHovered = false),
                    onTapCancel: () => setState(() => isButtonHovered = false),
                    onTap: () async {
                      if (selectedCore != null &&
                          configController.text.isNotEmpty) {
                        bool success = await donateCONFIG(
                          configController.text,
                          core: selectedCore!,
                          message: messageController.text,
                          telegramLink: telegramLinkController.text,
                        ).timeout(const Duration(seconds: 14), onTimeout: () {
                          LogOverlay.showLog("⏳ اتصال زمان‌بر شد!",
                              type: "error");
                          return false;
                        });
                        if (success) {
                          LogOverlay.showLog("✅ کانفیگ شما با موفقیت اهدا شد!",
                              type: "success");
                        }
                      } else {
                        LogOverlay.showLog(
                            "⚠️ لطفاً ابتدا کانفیگ را وارد کنید.",
                            type: "warning");
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      transform: Matrix4.translationValues(
                          0, isButtonHovered ? -5 : 0, 0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 70, vertical: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isButtonHovered
                              ? [Colors.pinkAccent, Colors.cyanAccent]
                              : [Colors.purpleAccent, Colors.cyan],
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Text(
                        '🚀 اهدا',
                        style: GoogleFonts.vazirmatn(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
    );
  }
}
