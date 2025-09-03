import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';

import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:Freedom_Guard/core/local.dart';
import 'package:Freedom_Guard/components/settings.dart';

class DnsInfo {
  final String name;
  final List<String> addresses;
  final String category;
  final String description;

  DnsInfo({
    required this.name,
    required this.addresses,
    required this.category,
    required this.description,
  });

  factory DnsInfo.fromJson(Map<String, dynamic> json) {
    return DnsInfo(
      name: json['name'],
      addresses: List<String>.from(json['addresses']),
      category: json['category'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'addresses': addresses,
      'category': category,
      'description': description,
    };
  }
}

void showDnsSelectionPopup(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return const DnsSelectionDialog();
    },
  );
}

class DnsSelectionDialog extends StatefulWidget {
  const DnsSelectionDialog({Key? key}) : super(key: key);

  @override
  State<DnsSelectionDialog> createState() => _DnsSelectionDialogState();
}

class _DnsSelectionDialogState extends State<DnsSelectionDialog> {
  List<String>? _selectedDnsAddresses;
  final Map<String, List<DnsInfo>> _groupedDns = {};
  final _customDnsNameController = TextEditingController();
  final _customDnsAddress1Controller = TextEditingController();
  final _customDnsAddress2Controller = TextEditingController();

  final List<DnsInfo> _masterDnsList = [
    DnsInfo(
        name: 'Cloudflare',
        addresses: ['1.1.1.1', '1.0.0.1'],
        category: 'عمومی',
        description: 'سریع و امن'),
    DnsInfo(
        name: 'Google',
        addresses: ['8.8.8.8', '8.8.4.4'],
        category: 'عمومی',
        description: 'پایدار و قابل اعتماد'),
    DnsInfo(
        name: 'Quad9',
        addresses: ['9.9.9.9', '149.112.112.112'],
        category: 'عمومی',
        description: 'مسدودسازی دامنه مخرب'),
    DnsInfo(
        name: 'OpenDNS',
        addresses: ['208.67.222.222', '208.67.220.220'],
        category: 'عمومی',
        description: 'قدیمی و پایدار'),
    DnsInfo(
        name: 'AdGuard DNS',
        addresses: ['94.140.14.14', '94.140.15.15'],
        category: 'ضد تبلیغ',
        description: 'مسدودسازی تبلیغات و ردیاب'),
    DnsInfo(
        name: 'Control D',
        addresses: ['76.76.2.0', '76.76.10.0'],
        category: 'ضد تبلیغ',
        description: 'مسدودسازی بدافزار'),
    DnsInfo(
        name: 'Mullvad',
        addresses: ['194.242.2.2', '193.19.108.2'],
        category: 'ضد تبلیغ',
        description: 'حفظ حریم خصوصی'),
    DnsInfo(
        name: 'Cloudflare Family',
        addresses: ['1.1.1.3', '1.0.0.3'],
        category: 'خانواده',
        description: 'مسدودسازی محتوای بزرگسالان'),
    DnsInfo(
        name: 'AdGuard Family',
        addresses: ['94.140.14.15', '94.140.15.16'],
        category: 'خانواده',
        description: 'حالت جستجوی امن'),
    DnsInfo(
        name: 'OpenDNS Family',
        addresses: ['208.67.222.123', '208.67.220.123'],
        category: 'خانواده',
        description: 'مناسب برای کودکان'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeDnsData();
  }

  @override
  void dispose() {
    _customDnsNameController.dispose();
    _customDnsAddress1Controller.dispose();
    _customDnsAddress2Controller.dispose();
    super.dispose();
  }

  Future<void> _initializeDnsData() async {
    await _loadAndGroupDnsServers();
    await _loadCurrentDnsSelection();
  }

  Future<void> _loadAndGroupDnsServers() async {
    _groupedDns.clear();
    for (var dns in _masterDnsList) {
      _groupedDns.putIfAbsent(dns.category, () => []).add(dns);
    }

    final customDnsList = await _loadCustomDnsList();
    _groupedDns['شخصی'] = customDnsList;

    if (mounted) setState(() {});
  }

  Future<List<DnsInfo>> _loadCustomDnsList() async {
    final jsonString = await SettingsApp().getString('custom_dns_list');
    if (jsonString != null && jsonString.isNotEmpty) {
      try {
        final List<dynamic> decodedList = jsonDecode(jsonString);
        return decodedList.map((json) => DnsInfo.fromJson(json)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  Future<void> _saveCustomDnsList(List<DnsInfo> customDns) async {
    final List<Map<String, dynamic>> jsonList =
        customDns.map((dns) => dns.toJson()).toList();
    await SettingsApp().setString('custom_dns_list', jsonEncode(jsonList));
  }

  Future<void> _loadCurrentDnsSelection() async {
    final dnsList = await SettingsApp().getList('preferred_dns');
    if (dnsList != null && dnsList.isNotEmpty && mounted) {
      setState(() {
        _selectedDnsAddresses = dnsList.cast<String>();
      });
    }
  }

  void _handleSelection(List<String> addresses) {
    setState(() {
      _selectedDnsAddresses = addresses;
    });
  }

  void _handleDeleteCustomDns(DnsInfo dnsToDelete) async {
    final customDns = _groupedDns['شخصی']!;
    customDns.removeWhere((dns) => dns.name == dnsToDelete.name);
    await _saveCustomDnsList(customDns);

    if (listEquals(_selectedDnsAddresses, dnsToDelete.addresses)) {
      await _clearSelection(showLog: false, popContext: false);
    }

    setState(() {});
    LogOverlay.showLog('DNS شخصی حذف شد.');
  }

  Future<void> _saveSelection() async {
    if (_selectedDnsAddresses != null) {
      await SettingsApp().setList('preferred_dns', _selectedDnsAddresses!);
      if (mounted) {
        LogOverlay.showLog('DNS جدید با موفقیت ذخیره شد.');
        Navigator.of(context).pop();
      }
    } else {
      LogOverlay.showLog('هیچ DNS انتخاب نشده است.');
    }
  }

  Future<void> _clearSelection(
      {bool showLog = true, bool popContext = true}) async {
    await SettingsApp().setList('preferred_dns', []);
    if (mounted) {
      setState(() => _selectedDnsAddresses = null);
      if (popContext) {
        Navigator.pop(context);
      }
      if (showLog) {
        LogOverlay.showLog('تنظیمات DNS پاک شد.');
      }
    }
  }

  bool _isValidIp(String ip) {
    return true;
  }

  void _showAddCustomDnsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Directionality(
          textDirection:
              getDir() == "rtl" ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            title: Text('افزودن DNS شخصی'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _customDnsNameController,
                    decoration: InputDecoration(labelText: 'نام DNS'),
                  ),
                  TextField(
                    controller: _customDnsAddress1Controller,
                    decoration: InputDecoration(labelText: 'آدرس اولیه'),
                    keyboardType: TextInputType.text,
                  ),
                  TextField(
                    controller: _customDnsAddress2Controller,
                    decoration:
                        InputDecoration(labelText: 'آدرس ثانویه (اختیاری)'),
                    keyboardType: TextInputType.text,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('لغو'),
              ),
              FilledButton(
                onPressed: () async {
                  final name = _customDnsNameController.text.trim();
                  final address1 = _customDnsAddress1Controller.text.trim();
                  final address2 = _customDnsAddress2Controller.text.trim();

                  if (name.isEmpty ||
                      !_isValidIp(address1) ||
                      (address2.isNotEmpty && !_isValidIp(address2))) {
                    LogOverlay.showLog('لطفاً نام و آدرس IP معتبر وارد کنید.');
                    return;
                  }

                  final customDnsList = _groupedDns['شخصی']!;
                  if (customDnsList.any((dns) =>
                      dns.name.toLowerCase() == name.toLowerCase() ||
                      dns.addresses.contains(address1))) {
                    LogOverlay.showLog(
                        'این نام یا آدرس DNS قبلاً اضافه شده است.');
                    return;
                  }

                  final addresses = [address1];
                  if (address2.isNotEmpty) {
                    addresses.add(address2);
                  }

                  final newDns = DnsInfo(
                      name: name,
                      addresses: addresses,
                      category: 'شخصی',
                      description: 'DNS تعریف شده توسط کاربر');

                  customDnsList.add(newDns);
                  await _saveCustomDnsList(customDnsList);

                  setState(() {
                    _handleSelection(addresses);
                  });

                  _customDnsNameController.clear();
                  _customDnsAddress1Controller.clear();
                  _customDnsAddress2Controller.clear();
                  Navigator.of(context).pop();
                  LogOverlay.showLog('DNS شخصی با موفقیت افزوده شد.');
                },
                child: Text('افزودن'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _groupedDns.keys.toList();

    return Directionality(
        textDirection:
            getDir() == "rtl" ? TextDirection.rtl : TextDirection.ltr,
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.0)),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: DefaultTabController(
              length: categories.length,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
                      child: Text(
                        'انتخاب سرور DNS',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    TabBar(
                      isScrollable: true,
                      tabs: categories
                          .map((category) => Tab(text: category))
                          .toList(),
                      labelStyle: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                      unselectedLabelStyle: theme.textTheme.titleSmall,
                    ),
                    Flexible(
                      child: TabBarView(
                        children: categories.map((category) {
                          final dnsList = _groupedDns[category]!;
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 12.0),
                            itemCount:
                                dnsList.length + (category == 'شخصی' ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (category == 'شخصی' &&
                                  index == dnsList.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 4.0),
                                  child: ElevatedButton.icon(
                                    icon: Icon(Icons.add),
                                    label: Text("افزودن DNS جدید"),
                                    onPressed: _showAddCustomDnsDialog,
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: Size(double.infinity, 50),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final dns = dnsList[index];
                              final isSelected = listEquals(
                                  dns.addresses, _selectedDnsAddresses);
                              return DnsCard(
                                dnsInfo: dns,
                                isSelected: isSelected,
                                onTap: () => _handleSelection(dns.addresses),
                                onDelete: category == 'شخصی'
                                    ? () => _handleDeleteCustomDns(dns)
                                    : null,
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                              onPressed: () => _clearSelection(),
                              child: const Text('پاکسازی')),
                          FilledButton.tonal(
                            onPressed: _saveSelection,
                            child: const Text('ذخیره و اعمال'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}

class DnsCard extends StatelessWidget {
  final DnsInfo dnsInfo;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const DnsCard({
    Key? key,
    required this.dnsInfo,
    required this.isSelected,
    required this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color cardColor = isSelected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final Color contentColor = isSelected
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;
    final Color titleColor =
        isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: isSelected
                ? Border.all(color: colorScheme.primary, width: 1.5)
                : Border.all(color: Colors.transparent),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                if (isSelected) ...[
                  Icon(Icons.check_circle,
                      color: colorScheme.primary, size: 24),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dnsInfo.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                              color: titleColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(dnsInfo.description,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: contentColor)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: dnsInfo.addresses
                      .map((address) => Text(address,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: contentColor,
                              fontFamily: 'monospace',
                              letterSpacing: 0.8)))
                      .toList(),
                ),
                if (onDelete != null)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    onPressed: onDelete,
                    tooltip: 'حذف DNS',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
