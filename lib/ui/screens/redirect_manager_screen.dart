import 'dart:ui';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:flutter/material.dart';

class RedirectManagerPage extends StatefulWidget {
  const RedirectManagerPage({super.key});

  @override
  State<RedirectManagerPage> createState() => _RedirectManagerPageState();
}

class _RedirectManagerPageState extends State<RedirectManagerPage> {
  final controller = TextEditingController();

  String _initialRedirectBase = "https://req.freedomguard.workers.dev/";

  @override
  void initState() {
    super.initState();
    _loadInitialRedirectBase();
  }

  Future<void> _loadInitialRedirectBase() async {
    _initialRedirectBase = await SettingsApp().getValue("redirectBase");
    controller.text = _initialRedirectBase == ""
        ? "https://req.freedomguard.workers.dev/"
        : _initialRedirectBase;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Redirect Manager"),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.surface
                ],
              ),
            ),
          ),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  width: 340,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Change Redirect Base URL",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.3),
                          hintText: "Redirect Base URL",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            SettingsApp().setValue(
                                "redirectBase", controller.text.trim());
                            LogOverlay.showLog(
                                'Redirect base updated: ${controller.text.trim()}');
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          child: Text("Save"),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
