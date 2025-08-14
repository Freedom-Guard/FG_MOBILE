import 'dart:async';
import 'dart:convert';
import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/servers.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/services/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CFGPage extends StatefulWidget {
  @override
  State<CFGPage> createState() => _CFGPageState();
}

class _CFGPageState extends State<CFGPage> with TickerProviderStateMixin {
  List<String> subLinks = [];
  String? selectedSubLink;
  String? selectedConfig;
  List<String> configs = [];
  List<Map<String, dynamic>> testedConfigs = [];
  bool isLoading = false;
  bool isTesting = false;
  Settings settings = Settings();
  ServersM serversM = new ServersM();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final Map<String, bool> _configLoading = {};

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    loadSubLinks();
    loadSelectedSubLink();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> loadSubLinks() async {
    setState(() => isLoading = true);
    try {
      List<String> links = await getSubLinks();
      setState(() {
        subLinks = links
            .where((link) =>
                link.startsWith('http') || link.startsWith('freedom-guard://'))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      LogOverlay.showLog('Failed to load sub-links: $e');
    }
  }

  Future<void> loadSelectedSubLink() async {
    try {
      String? savedLink = await settings.getValue('selectedSubLink');
      if (savedLink != null && subLinks.contains(savedLink)) {
        setState(() {
          selectedSubLink = savedLink;
        });
        fetchConfigs(savedLink);
        return;
      }
      if (subLinks.isNotEmpty && selectedSubLink == null) {
        setState(() {
          selectedSubLink = subLinks[0];
        });
        await settings.setValue('selectedSubLink', subLinks[0]);
        fetchConfigs(subLinks[0]);
      }
    } catch (e) {
      LogOverlay.showLog('Failed to load saved sub-link: $e');
    }
  }

  Future<List<String>> getSubLinks() async {
    return await ServersM().oldServers();
  }

  Future<void> fetchConfigs(String subLink) async {
    setState(() {
      isLoading = true;
      testedConfigs.clear();
      configs.clear();
      _configLoading.clear();
    });
    int maxRetries = 3;
    int retryCount = 0;
    subLink = subLink.replaceAll("freedom-guard://", "");
    while (retryCount < maxRetries) {
      try {
        final response = await http
            .get(Uri.parse(subLink))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          String content = response.body;
          if (content.isEmpty) {
            throw Exception('Empty response from server');
          }
          List<String> decodedConfigs = [];
          if (content.contains('\n')) {
            decodedConfigs = content
                .split('\n')
                .where((line) =>
                    line.trim().isNotEmpty && !(line.startsWith("//")))
                .toList();
          } else {
            try {
              decodedConfigs = utf8
                  .decode(base64Decode(content))
                  .split('\n')
                  .where((line) =>
                      line.trim().isNotEmpty && !line.trim().startsWith("//"))
                  .toList();
            } catch (e) {
              decodedConfigs = [content];
            }
          }
          try {
            var jsonData = jsonDecode(content);
            if (jsonData is Map && jsonData.containsKey("MOBILE")) {
              decodedConfigs = jsonData["MOBILE"];
            }
          } catch (e) {
            LogOverlay.addLog("error on json cfg: " + e.toString());
          }
          if (decodedConfigs.isEmpty) {
            throw Exception('No valid configs found');
          }
          setState(() {
            configs = decodedConfigs;
            isLoading = false;
          });
          _fadeController.forward(from: 0);
          loadTestedConfigs();
          return;
        } else {
          throw Exception('HTTP ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        if (retryCount == maxRetries) {
          LogOverlay.showLog('Failed to fetch configs: $e');
        }
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> loadTestedConfigs() async {
    try {
      String? savedConfigs = await settings.getValue('testedConfigs');
      if (savedConfigs != null) {
        setState(() {
          testedConfigs =
              List<Map<String, dynamic>>.from(jsonDecode(savedConfigs));
        });
      }
    } catch (e) {
      LogOverlay.addLog('Failed to load tested configs: $e');
    }
  }

  Future<int> _pingServer(String config) async {
    final pingResult = await serversM.pingC(config);
    return pingResult;
  }

  Future<void> testConfigs() async {
    if (configs.isEmpty) {
      LogOverlay.showLog('No configs to test');
      return;
    }

    setState(() {
      isTesting = true;
      testedConfigs.clear();
      _configLoading.clear();
      for (var config in configs) {
        _configLoading[config] = false;
      }
    });

    final List<Map<String, dynamic>> results = [];
    final List<String> pendingConfigs = List.from(configs)..shuffle();
    final Set<String> testedSet = {};
    const batchSize = 3;

    while (pendingConfigs.isNotEmpty) {
      final batch = <String>[];

      while (batch.length < batchSize && pendingConfigs.isNotEmpty) {
        final config = pendingConfigs.removeLast();
        if (!testedSet.contains(config)) {
          batch.add(config);
          testedSet.add(config);
        }
      }
      if (!mounted) break;
      try {
        final batchResults = await Future.wait(batch.map((server) async {
          if (!mounted) return {"": ""};
          if (server.trim().isEmpty) {
            setState(() => _configLoading[server] = false);
            return {
              'config': server,
              'success': false,
              'ping': null,
            };
          }
          setState(() => _configLoading[server] = true);

          final ping = await _pingServer(server);
          final success = ping != -1;

          setState(() => _configLoading[server] = false);

          return {
            'config': server,
            'success': success,
            'ping': success ? ping : null,
          };
        }).toList());

        results.addAll(batchResults);

        final sortedResults = List<Map<String, dynamic>>.from(results);
        sortedResults.sort((a, b) {
          final aSuccess = a['success'] == true;
          final bSuccess = b['success'] == true;
          if (aSuccess && bSuccess) {
            return (a['ping'] as int).compareTo(b['ping'] as int);
          }
          if (aSuccess) return -1;
          if (bSuccess) return 1;
          return 0;
        });

        final sortedConfigs = configs.toList()
          ..sort((a, b) {
            final aResult = sortedResults.firstWhere(
              (e) => e['config'] == a,
              orElse: () => {'config': a, 'success': false, 'ping': 999999},
            );
            final bResult = sortedResults.firstWhere(
              (e) => e['config'] == b,
              orElse: () => {'config': b, 'success': false, 'ping': 999999},
            );

            final aSuccess = aResult['success'] == true;
            final bSuccess = bResult['success'] == true;

            if (aSuccess && bSuccess) {
              return (aResult['ping'] ?? 999999)
                  .compareTo(bResult['ping'] ?? 999999);
            }
            if (aSuccess) return -1;
            if (bSuccess) return 1;
            return 0;
          });

        setState(() {
          testedConfigs = List.from(sortedResults);
          configs = List.from(sortedConfigs);
        });

        await settings.setValue('testedConfigs', jsonEncode(sortedResults));
      } catch (e) {
        LogOverlay.addLog('Batch test failed: $e');
      }

      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (!mounted) return;
    setState(() => isTesting = false);

    LogOverlay.showLog('Config testing completed');
  }

  Future<void> selectConfig(String config) async {
    try {
      var oldServers = await ServersM().oldServers();
      if (!oldServers.contains(config)) {
        await ServersM().saveServers([config] + oldServers);
      }
      await ServersM().selectServer(config);
      setState(() {
        selectedConfig = config;
      });
      LogOverlay.addLog('Selected: ${getConfigName(config)}');
    } catch (e) {
      LogOverlay.showLog('Failed to select config: $e');
    }
  }

  String getConfigName(String config) {
    return getNameByConfig(config);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text(
              'CFG',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: isLoading || isTesting ? null : loadSubLinks,
                tooltip: 'Refresh Configs',
              ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedSubLink,
                        hint: const Text('Select Subscription Link'),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down, size: 30),
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        items: subLinks.map((String link) {
                          return DropdownMenuItem<String>(
                            value: link,
                            child: Text(
                              link,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) async {
                          if (newValue != null && !isTesting) {
                            setState(() {
                              selectedSubLink = newValue;
                              selectedConfig = null;
                              testedConfigs.clear();
                              configs.clear();
                              _configLoading.clear();
                            });
                            await settings.setValue(
                                'selectedSubLink', newValue);
                            fetchConfigs(newValue);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isTesting ? null : testConfigs,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            elevation: 2,
                            shadowColor:
                                theme.colorScheme.shadow.withOpacity(0.3),
                          ),
                          child: isTesting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Test Configurations',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: configs.isEmpty
                      ? const Center(
                          child: Text(
                            'No configurations available',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 1,
                            crossAxisSpacing: 0,
                            mainAxisSpacing: 0,
                            childAspectRatio: 5,
                          ),
                          itemCount: configs.length,
                          itemBuilder: (context, index) {
                            bool isTested = testedConfigs.any(
                                (config) => config['config'] == configs[index]);
                            Map<String, dynamic>? testResult = isTested
                                ? testedConfigs.firstWhere((config) =>
                                    config['config'] == configs[index])
                                : null;
                            bool isSelected = configs[index] == selectedConfig;
                            bool isConfigLoading =
                                _configLoading[configs[index]] ?? false;
                            return GestureDetector(
                              onTap: isConfigLoading
                                  ? null
                                  : () => selectConfig(configs[index]),
                              child: Card(
                                elevation: isSelected ? 8 : 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                color: isSelected
                                    ? theme.colorScheme.primary.withOpacity(0.9)
                                    : theme.colorScheme.surface,
                                child: Stack(
                                  children: [
                                    Container(
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        gradient: isSelected
                                            ? LinearGradient(
                                                colors: [
                                                  theme.colorScheme.primary,
                                                  theme.colorScheme.primary
                                                      .withOpacity(0.7),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.shadow
                                                .withOpacity(0.1),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            top: 12, left: 12, right: 12),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.vpn_key,
                                                  color: isSelected
                                                      ? theme
                                                          .colorScheme.onPrimary
                                                      : theme
                                                          .colorScheme.primary,
                                                  size: 24,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  getConfigName(configs[index]),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: isSelected
                                                        ? theme.colorScheme
                                                            .onPrimary
                                                        : theme.colorScheme
                                                            .onSurface,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Spacer(flex: 1),
                                                const SizedBox(width: 3),
                                                if (!isSelected)
                                                  Text(
                                                    '${testResult?['ping'] != null ? '${testResult?['ping']}ms' : 'N/A'}',
                                                    style: TextStyle(
                                                      color:
                                                          testResult?['success']
                                                              ? Colors.green
                                                              : Colors.red,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                const SizedBox(width: 3),
                                                if (isTested &&
                                                    testResult != null &&
                                                    !isSelected)
                                                  Icon(
                                                    testResult['success']
                                                        ? testResult["ping"] >
                                                                500
                                                            ? Icons
                                                                .wifi_1_bar_sharp
                                                            : testResult[
                                                                        "ping"] >
                                                                    150
                                                                ? Icons
                                                                    .wifi_2_bar
                                                                : Icons.wifi
                                                        : Icons.wifi_off,
                                                    color: testResult['success']
                                                        ? Colors.green
                                                        : Colors.red,
                                                    size: 20,
                                                  ),
                                                const SizedBox(width: 8),
                                                if (isSelected)
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: const Text(
                                                      'Selected',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (isConfigLoading)
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: const Center(
                                          child: SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                      Colors.white),
                                            ),
                                          ),
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
          ),
        ),
      ],
    );
  }
}
