import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/local.dart';
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
    _groupDnsServers();
    _loadCurrentDns();
  }

  void _groupDnsServers() {
    _groupedDns.clear();
    for (var dns in _masterDnsList) {
      _groupedDns.putIfAbsent(dns.category, () => []).add(dns);
    }
    _groupedDns.putIfAbsent('شخصی', () => []);
  }

  Future<void> _loadCurrentDns() async {
    final dnsList = await Settings().getList('preferred_dns');
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

  Future<void> _saveSelection() async {
    if (_selectedDnsAddresses != null) {
      await Settings().setList('preferred_dns', _selectedDnsAddresses!);
      if (mounted) {
        LogOverlay.showLog('DNS جدید با موفقیت ذخیره شد.');
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _clearSelection() async {
    await Settings().setList('preferred_dns', []);
    if (mounted) {
      setState(() => _selectedDnsAddresses = null);
      Navigator.pop(context);
      LogOverlay.showLog('تنظیمات DNS پاک شد.');
    }
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _customDnsNameController,
                  decoration: InputDecoration(labelText: 'نام DNS'),
                ),
                TextField(
                  controller: _customDnsAddress1Controller,
                  decoration: InputDecoration(labelText: 'آدرس اولیه'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _customDnsAddress2Controller,
                  decoration:
                      InputDecoration(labelText: 'آدرس ثانویه (اختیاری)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('لغو'),
              ),
              FilledButton(
                onPressed: () {
                  final name = _customDnsNameController.text;
                  final address1 = _customDnsAddress1Controller.text;
                  final address2 = _customDnsAddress2Controller.text;

                  if (name.isNotEmpty && address1.isNotEmpty) {
                    final addresses = [address1];
                    if (address2.isNotEmpty) {
                      addresses.add(address2);
                    }
                    setState(() {
                      final newDns = DnsInfo(
                          name: name,
                          addresses: addresses,
                          category: 'شخصی',
                          description: 'DNS تعریف شده توسط کاربر');
                      _groupedDns['شخصی']!.add(newDns);
                      _handleSelection(addresses);
                    });
                    _customDnsNameController.clear();
                    _customDnsAddress1Controller.clear();
                    _customDnsAddress2Controller.clear();
                    Navigator.of(context).pop();
                  }
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
                          if (category == 'شخصی') {
                            return Column(
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 12.0),
                                    itemCount: dnsList.length,
                                    itemBuilder: (context, index) {
                                      final dns = dnsList[index];
                                      final isSelected = listEquals(
                                          dns.addresses, _selectedDnsAddresses);
                                      return DnsCard(
                                        dnsInfo: dns,
                                        isSelected: isSelected,
                                        onTap: () =>
                                            _handleSelection(dns.addresses),
                                      );
                                    },
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
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
                                )
                              ],
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 12.0),
                            itemCount: dnsList.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final dns = dnsList[index];
                              final isSelected = listEquals(
                                  dns.addresses, _selectedDnsAddresses);
                              return DnsCard(
                                dnsInfo: dns,
                                isSelected: isSelected,
                                onTap: () => _handleSelection(dns.addresses),
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
                              onPressed: _clearSelection,
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

  const DnsCard({
    Key? key,
    required this.dnsInfo,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color cardColor = isSelected
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final Color contentColor =
        isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant;
    final Color titleColor =
        isSelected ? colorScheme.onPrimary : colorScheme.onSurface;

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
                ? Border.all(color: colorScheme.primary, width: 2)
                : null,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dnsInfo.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                  color: titleColor,
                                  fontWeight: FontWeight.bold)),
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
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 8,
                  left: 8,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary,
                    child: Icon(Icons.check,
                        color: theme.colorScheme.onPrimary, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
