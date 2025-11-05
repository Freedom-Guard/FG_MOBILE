import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:Freedom_Guard/components/settings.dart';

class DnsInfo {
  final String name;
  final List<String> addresses;
  final String category;
  final String description;

  DnsInfo(
      {required this.name,
      required this.addresses,
      required this.category,
      required this.description});

  factory DnsInfo.fromJson(Map<String, dynamic> json) => DnsInfo(
        name: json['name'],
        addresses: List<String>.from(json['addresses']),
        category: json['category'],
        description: json['description'],
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'addresses': addresses,
        'category': category,
        'description': description,
      };
}

void showDnsSelectionPopup(BuildContext context) => showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const DnsSelectionDialog(),
    );

class DnsSelectionDialog extends StatefulWidget {
  const DnsSelectionDialog({super.key});
  @override
  State<DnsSelectionDialog> createState() => _DnsSelectionDialogState();
}

class _DnsSelectionDialogState extends State<DnsSelectionDialog> {
  List<String>? selectedDns;
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController addr1Ctrl = TextEditingController();
  final TextEditingController addr2Ctrl = TextEditingController();
  final TextEditingController dohCtrl = TextEditingController();

  final Map<String, List<DnsInfo>> groups = {};
  final List<DnsInfo> base = [
    DnsInfo(
        name: 'Cloudflare',
        addresses: ['1.1.1.1', '1.0.0.1'],
        category: 'Public',
        description: 'Fast & Secure'),
    DnsInfo(
        name: 'Google',
        addresses: ['8.8.8.8', '8.8.4.4'],
        category: 'Public',
        description: 'Stable & Trusted'),
    DnsInfo(
        name: 'Quad9',
        addresses: ['9.9.9.9', '149.112.112.112'],
        category: 'Public',
        description: 'Security Focus'),
    DnsInfo(
        name: 'OpenDNS',
        addresses: ['208.67.222.222', '208.67.220.220'],
        category: 'Public',
        description: 'Reliable'),
    DnsInfo(
        name: 'AdGuard DNS',
        addresses: ['94.140.14.14', '94.140.15.15'],
        category: 'AdBlock',
        description: 'Ad & Tracking Block'),
    DnsInfo(
        name: 'Cloudflare DoH',
        addresses: ['https://cloudflare-dns.com/dns-query'],
        category: 'DoH',
        description: 'DNS over HTTPS'),
    DnsInfo(
        name: 'Google DoH',
        addresses: ['https://dns.google/dns-query'],
        category: 'DoH',
        description: 'DNS over HTTPS'),
    DnsInfo(
        name: 'AdGuard DoH',
        addresses: ['https://dns.adguard.com/dns-query'],
        category: 'DoH',
        description: 'DNS over HTTPS'),
    DnsInfo(
        name: 'Quad9 DoH',
        addresses: ['https://dns.quad9.net/dns-query'],
        category: 'DoH',
        description: 'Secure DoH'),
    DnsInfo(
        name: 'Mullvad DoH',
        addresses: ['https://adblock.mullvad.net/dns-query'],
        category: 'DoH',
        description: 'Privacy Focused'),
    DnsInfo(
        name: 'Cloudflare Family',
        addresses: ['1.1.1.3', '1.0.0.3'],
        category: 'Family',
        description: 'Adult Filter'),
  ];

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    groups.clear();
    for (var d in base) {
      groups.putIfAbsent(d.category, () => []).add(d);
    }
    final custom = await loadCustomDns();
    groups['Custom'] = custom;
    final saved = await SettingsApp().getList('preferred_dns');
    if (saved != null && mounted)
      setState(() => selectedDns = saved.cast<String>());
  }

  Future<List<DnsInfo>> loadCustomDns() async {
    final raw = await SettingsApp().getString('custom_dns_list');
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List).map((e) => DnsInfo.fromJson(e)).toList();
  }

  Future saveCustomDns(List<DnsInfo> list) async => SettingsApp().setString(
      'custom_dns_list', jsonEncode(list.map((e) => e.toJson()).toList()));

  void select(List<String> a) => setState(() => selectedDns = a);

  Future save() async {
    if (selectedDns == null) return LogOverlay.showLog('No DNS selected');
    await SettingsApp().setList('preferred_dns', selectedDns!);
    LogOverlay.showLog('Saved');
    Navigator.pop(context);
  }

  Future clear() async {
    await SettingsApp().setList('preferred_dns', []);
    setState(() => selectedDns = null);
    LogOverlay.showLog('Cleared');
    Navigator.pop(context);
  }

  void addCustom() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            child: Column(children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name')),
              TextField(
                  controller: addr1Ctrl,
                  decoration:
                      const InputDecoration(labelText: 'IPv4 / DoH Link')),
              TextField(
                  controller: addr2Ctrl,
                  decoration:
                      const InputDecoration(labelText: 'IPv4 (optional)')),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: () async {
                  final n = nameCtrl.text.trim(),
                      a1 = addr1Ctrl.text.trim(),
                      a2 = addr2Ctrl.text.trim();
                  if (n.isEmpty || a1.isEmpty)
                    return LogOverlay.showLog('Invalid');
                  final custom = groups['Custom']!;
                  if (custom
                      .any((d) => d.name.toLowerCase() == n.toLowerCase()))
                    return LogOverlay.showLog('Exists');
                  final l = [a1];
                  if (a2.isNotEmpty) l.add(a2);
                  final d = DnsInfo(
                      name: n,
                      addresses: l,
                      category: 'Custom',
                      description: 'User DNS');
                  custom.add(d);
                  await saveCustomDns(custom);
                  select(l);
                  nameCtrl.clear();
                  addr1Ctrl.clear();
                  addr2Ctrl.clear();
                  Navigator.pop(context);
                  LogOverlay.showLog('Added');
                },
                child: const Text('Add'),
              )
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = groups.keys.toList();
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            width: 420,
            height: MediaQuery.of(context).size.height * .8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.08),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(.2)),
            ),
            child: DefaultTabController(
              length: cats.length,
              child: Column(children: [
                const SizedBox(height: 14),
                const Text('DNS Settings',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TabBar(
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicator: BoxDecoration(
                    color: Colors.white.withOpacity(.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tabs: cats
                      .map((e) => Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Tab(text: e),
                          ))
                      .toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: cats.map((c) {
                      final list = groups[c]!;
                      return Scrollbar(
                        thumbVisibility: true,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(25),
                          itemCount: list.length + (c == 'Custom' ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (c == 'Custom' && i == list.length) {
                              return GestureDetector(
                                onTap: addCustom,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Text('+ Add DNS / DoH',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              );
                            }
                            final d = list[i];
                            final s = selectedDns != null &&
                                d.addresses.toString() ==
                                    selectedDns.toString();
                            return GestureDetector(
                              onTap: () => select(d.addresses),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(14),
                                margin: const EdgeInsets.only(bottom: 6),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: s
                                      ? Colors.blue.withOpacity(.3)
                                      : Colors.white.withOpacity(.08),
                                  border: Border.all(
                                      color: s
                                          ? Colors.blueAccent
                                          : Colors.transparent,
                                      width: 1.4),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(d.name,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold)),
                                          Text(d.description,
                                              style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12)),
                                        ]),
                                    Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: d.addresses.map((e) {
                                          return Text(e,
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'monospace',
                                                  fontSize: 12));
                                        }).toList()),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                            onPressed: clear,
                            child: const Text('Clear',
                                style: TextStyle(color: Colors.redAccent))),
                        FilledButton(
                            onPressed: save, child: const Text('Apply')),
                      ]),
                )
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
