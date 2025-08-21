import 'dart:async';

import 'package:Freedom_Guard/components/local.dart';
import 'package:Freedom_Guard/screens/home_screen.dart';
import 'package:Freedom_Guard/screens/welcome.dart';
import 'package:Freedom_Guard/services/quick_connect.dart';
import 'package:Freedom_Guard/widgets/theme/theme.dart';
import 'package:Freedom_Guard/components/servers.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quick_settings/quick_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/LOGLOG.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  await WidgetsFlutterBinding.ensureInitialized();

  QuickSettings.setup(
    onTileClicked: onTileClicked,
    onTileAdded: onTileAdded,
    onTileRemoved: onTileRemoved,
  );

  await initTranslations();
  try {
    await Firebase.initializeApp();
    await FirebaseMessaging.instance.setAutoInitEnabled(true);
    print("🔥 Firebase Initialized Successfully");
  } catch (e) {
    print("❌ Firebase Initialization Failed: $e");
  }

  final themeNotifier = await ThemeNotifier.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeNotifier),
        ChangeNotifierProvider(create: (context) => ServersM()),
        Provider(create: (context) => SettingsApp()),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) {
          return MaterialApp(
            navigatorKey: LogOverlay.navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: themeNotifier.currentTheme,
            initialRoute: '/',
            routes: {
              '/': (context) => FreedomGuardApp(),
              '/home': (context) => FreedomGuardApp(),
            },
          );
        },
      ),
    ),
  );
}

class FreedomGuardApp extends StatefulWidget {
  @override
  _FreedomGuardAppState createState() => _FreedomGuardAppState();
}

class _FreedomGuardAppState extends State<FreedomGuardApp> {
  TextDirection _direction = TextDirection.ltr;
  bool _isLoaded = false;
  bool _privacyAccepted = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final dir = await getDir();
    setState(() {
      _direction = dir == "rtl" ? TextDirection.rtl : TextDirection.ltr;
      _privacyAccepted = prefs.getBool('privacy_accepted') ?? false;
      _isLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return Directionality(
      textDirection: _direction,
      child: _privacyAccepted ? MainScreen() : PrivacyWelcomeScreen(),
    );
  }
}
