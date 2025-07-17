import 'dart:convert';
import 'dart:ui';
import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsPage extends StatefulWidget {
  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> notifications = [];
  Set<String> readIds = {};
  bool loading = true;

  Future<void> fetchNotifications() async {
    setState(() => loading = true);
    const maxAttempts = 3;
    int attempt = 0;
    bool success = false;

    while (attempt < maxAttempts && !success) {
      attempt++;
      try {
        LogOverlay.addLog("در حال دریافت نوتیفیکیشن‌ها - تلاش $attempt");
        final response = await http.get(Uri.parse(
            'https://raw.githubusercontent.com/Freedom-Guard/Freedom-Guard/main/config/mobile/notif.json'));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            notifications = data.reversed.take(10).toList();
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
                'cached_notifications', jsonEncode(notifications));
            success = true;
            LogOverlay.addLog("دریافت موفق");
          }
        }
      } catch (e) {
        LogOverlay.addLog("خطا در دریافت: $e");
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!success) {
      LogOverlay.addLog("دریافت از کش");
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_notifications');
      if (cached != null) {
        final data = jsonDecode(cached);
        if (data is List) notifications = data;
      }
    }

    await loadReadIds();
    setState(() => loading = false);
  }

  Future<void> loadReadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('read_notification_ids') ?? [];
    readIds = ids.toSet();
  }

  Future<void> markAsRead(String id) async {
    if (readIds.contains(id)) return;
    readIds.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_notification_ids', readIds.toList());
    setState(() {});
    LogOverlay.addLog("نوتیفیکیشن خوانده شد: $id");
  }

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('نوتیفیکیشن‌ها'),
        backgroundColor: Colors.black.withOpacity(0.4),
        elevation: 0,
        actions: [
          IconButton(
              onPressed: fetchNotifications, icon: const Icon(Icons.refresh))
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withOpacity(0.6),
              theme.colorScheme.primary.withOpacity(0.2),
              theme.colorScheme.secondary.withOpacity(0.1)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 24),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final item = notifications[index];
                  final id = (item['title'] ?? '') + (item['message'] ?? '');
                  final isRead = readIds.contains(id);
                  return GestureDetector(
                    onTap: () async {
                      await markAsRead(id);
                      final link = item['link'];
                      if (link != null && link.toString().trim().isNotEmpty) {
                        final uri = Uri.parse(link);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                          LogOverlay.addLog("باز کردن لینک: $link");
                        }
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white.withOpacity(0.05),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isRead)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(top: 4),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] ?? 'بدون عنوان',
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: isRead
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item['message'] ?? '',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: Colors.white70,
                                          height: 1.4,
                                        ),
                                      ),
                                      if (item['link'] != null &&
                                          item['link']
                                              .toString()
                                              .trim()
                                              .isNotEmpty)
                                        const SizedBox(height: 16),
                                      if (item['link'] != null &&
                                          item['link']
                                              .toString()
                                              .trim()
                                              .isNotEmpty)
                                        InkWell(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          onTap: () async {
                                            await markAsRead(id);
                                            final uri = Uri.parse(item['link']);
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri,
                                                  mode: LaunchMode
                                                      .externalApplication);
                                              LogOverlay.addLog(
                                                  "باز کردن لینک: ${item['link']}");
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 10),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              gradient: LinearGradient(
                                                colors: [
                                                  theme.colorScheme.secondary
                                                      .withOpacity(0.3),
                                                  Colors.white
                                                      .withOpacity(0.05),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              border: Border.all(
                                                  color: Colors.white24),
                                            ),
                                            child: Text(
                                              'مشاهده لینک',
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.secondary,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
