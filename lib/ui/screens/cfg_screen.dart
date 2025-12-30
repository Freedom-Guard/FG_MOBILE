import 'dart:async';
import 'dart:convert';
import 'package:Freedom_Guard/services/config.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:Freedom_Guard/core/network/network_service.dart';
import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:Freedom_Guard/components/servers.dart';
import 'package:Freedom_Guard/components/settings.dart';

class CFGPage extends StatefulWidget {
  const CFGPage({super.key});

  @override
  State<CFGPage> createState() => _CFGPageState();
}

class _CFGPageState extends State<CFGPage> with SingleTickerProviderStateMixin {
  final settings = SettingsApp();
  final serversM = ServersM();

  List<String> subLinks = [];
  List<String> configs = [];
  List<Map<String, dynamic>> testedConfigs = [];

  String? selectedSubLink;
  String? selectedConfig;

  bool isLoading = false;
  bool isTesting = false;

  final Map<String, bool> testingItem = {};

  late final AnimationController animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 400));
  late final Animation<double> fade =
      CurvedAnimation(parent: animCtrl, curve: Curves.easeOutCubic);
  late final Animation<double> slide =
      Tween(begin: 20.0, end: 0.0).animate(fade);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await loadSubLinks();
    await loadSelectedSubLink();
    animCtrl.forward();
  }

  @override
  void dispose() {
    animCtrl.dispose();
    super.dispose();
  }

  Future<void> loadSubLinks() async {
    setState(() => isLoading = true);
    try {
      final links = await serversM.oldServers();
      subLinks = links
          .where(
              (e) => e.startsWith('http') || e.startsWith('freedom-guard://'))
          .toList();
    } catch (e) {
      LogOverlay.showLog(e.toString());
    }
    setState(() => isLoading = false);
  }

  Future<void> loadSelectedSubLink() async {
    final saved = await settings.getValue('selectedSubLink');
    selectedSubLink = (saved != null && subLinks.contains(saved))
        ? saved
        : subLinks.firstOrNull;
    if (selectedSubLink != null) {
      await settings.setValue('selectedSubLink', selectedSubLink!);
      await fetchConfigs(selectedSubLink!);
    }
  }

  Future<void> fetchConfigs(String link) async {
    setState(() {
      isLoading = true;
      configs.clear();
      testedConfigs.clear();
      testingItem.clear();
    });

    link = link.replaceAll('freedom-guard://', '');

    try {
      final res =
          await NetworkService.get(link).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw res.statusCode;

      final body = res.body;
      List<String> list;

      try {
        list = List<String>.from(jsonDecode(body)['MOBILE']);
      } catch (_) {
        try {
          list = utf8.decode(base64Decode(body)).split('\n');
        } catch (_) {
          list = body.split('\n');
        }
      }

      configs = list
          .where((e) => e.trim().isNotEmpty && !e.trim().startsWith('//'))
          .toList();

      await _loadTested();
      _sort();
      animCtrl.forward(from: 0);
    } catch (e) {
      LogOverlay.showLog(e.toString());
    }

    setState(() => isLoading = false);
  }

  Future<void> _loadTested() async {
    final raw = await settings.getValue('testedConfigs');
    if (raw != null) {
      testedConfigs = List<Map<String, dynamic>>.from(jsonDecode(raw));
    }
  }

  Future<void> testConfigs() async {
    isTesting = true;
    testedConfigs.clear();
    setState(() {});

    for (final c in configs) {
      testingItem[c] = true;
      setState(() {});

      final ping = await serversM.pingC(c);
      testedConfigs.add({
        'config': c,
        'success': ping != -1,
        'ping': ping != -1 ? ping : null,
      });

      testingItem[c] = false;
      _sort();
      setState(() {});
    }

    await settings.setValue('testedConfigs', jsonEncode(testedConfigs));
    isTesting = false;
    setState(() {});
  }

  void _sort() {
    configs.sort((a, b) {
      final ar = testedConfigs.firstWhere((e) => e['config'] == a,
          orElse: () => {'success': false, 'ping': 999999});
      final br = testedConfigs.firstWhere((e) => e['config'] == b,
          orElse: () => {'success': false, 'ping': 999999});

      if (ar['success'] && br['success']) {
        return (ar['ping'] as int).compareTo(br['ping'] as int);
      }
      if (ar['success']) return -1;
      if (br['success']) return 1;
      return a.compareTo(b);
    });
  }

  Future<void> selectConfig(String c) async {
    setState(() => selectedConfig = c);
    final old = await serversM.oldServers();
    await serversM.saveServers({
      ...[selectedConfig.toString()],
      ...old
    }.toList());
    await serversM.selectServer(c);
  }

  Future<void> importAll() async {
    final ok = testedConfigs
        .where(
            (e) => e['success'] == true && e['ping'] != null && e['ping'] > 0)
        .map<String>((e) => e['config'] as String)
        .toList();

    final old = await serversM.oldServers();

    await serversM.saveServers([
      ...ok,
      ...old,
    ]);

    LogOverlay.showLog('Imported');
  }

  void shareTestedOnly() {
    final ok = testedConfigs
        .where((e) => e['success'] == true)
        .map((e) => e['config'])
        .join('\n');
    if (ok.isEmpty) {
      LogOverlay.showLog('Nothing to share');
      return;
    }
    Share.share(ok);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CFG'),
        actions: [
          IconButton(
              icon: const Icon(Icons.playlist_add), onPressed: importAll),
          IconButton(icon: const Icon(Icons.share), onPressed: shareTestedOnly),
          IconButton(icon: const Icon(Icons.refresh), onPressed: loadSubLinks),
        ],
      ),
      body: FadeTransition(
        opacity: fade,
        child: Transform.translate(
          offset: Offset(0, slide.value),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: DropdownButtonFormField<String>(
                  value: selectedSubLink,
                  isExpanded: true,
                  items: subLinks
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(
                              e.split('#').last,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    selectedSubLink = v;
                    await settings.setValue('selectedSubLink', v);
                    await fetchConfigs(v);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FilledButton(
                  onPressed: isTesting ? null : testConfigs,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isTesting
                        ? const SizedBox(
                            key: ValueKey(1),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Test configs', key: ValueKey(2)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: configs.length,
                  itemBuilder: (_, i) {
                    final c = configs[i];
                    final r = testedConfigs.firstWhere((e) => e['config'] == c,
                        orElse: () => {});
                    final selected = c == selectedConfig;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: selected
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surface,
                      ),
                      child: ListTile(
                        onTap: () => selectConfig(c),
                        title: Text(
                          getNameByConfig(c),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          r['ping'] != null ? '${r['ping']} ms' : 'Not tested',
                          style: TextStyle(
                            color: r['success'] == true
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        trailing: testingItem[c] == true
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                selected
                                    ? Icons.check_circle
                                    : (r['ping'] == null
                                        ? Icons.signal_cellular_off
                                        : r['ping'] > 400
                                            ? Icons.signal_cellular_alt_1_bar
                                            : r['ping'] > 250
                                                ? Icons
                                                    .signal_cellular_alt_2_bar
                                                : Icons.signal_cellular_alt),
                                color: selected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.primary,
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
