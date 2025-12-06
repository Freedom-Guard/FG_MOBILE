import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: DnsToolsPage(),
  ));
}

class DnsModel {
  final String ip;
  final String provider;
  int? latency;
  bool isOnline;
  bool isScanning;

  DnsModel({
    required this.ip,
    required this.provider,
    this.latency,
    this.isOnline = false,
    this.isScanning = false,
  });
}

class DnsToolsPage extends StatefulWidget {
  const DnsToolsPage({super.key});

  @override
  State<DnsToolsPage> createState() => _DnsToolsPageState();
}

class _DnsToolsPageState extends State<DnsToolsPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customIpController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<DnsModel> _masterList = [
    DnsModel(ip: "1.1.1.1", provider: "Cloudflare Primary"),
    DnsModel(ip: "1.0.0.1", provider: "Cloudflare Secondary"),
    DnsModel(ip: "8.8.8.8", provider: "Google Primary"),
    DnsModel(ip: "8.8.4.4", provider: "Google Secondary"),
    DnsModel(ip: "9.9.9.9", provider: "Quad9 Primary"),
    DnsModel(ip: "149.112.112.112", provider: "Quad9 Secondary"),
    DnsModel(ip: "208.67.222.222", provider: "OpenDNS Home"),
    DnsModel(ip: "208.67.220.220", provider: "OpenDNS Home"),
    DnsModel(ip: "94.140.14.14", provider: "AdGuard Default"),
    DnsModel(ip: "76.76.2.0", provider: "Control D"),
    DnsModel(ip: "185.228.168.9", provider: "CleanBrowsing"),
  ];

  List<DnsModel> _filteredList = [];
  bool _isGlobalScanning = false;
  bool _isLoadingIp = false;
  String _publicIp = "";
  String _ispSummary = "Tap to analyze";

  Map<String, dynamic>? _fullIpDetails;

  @override
  void initState() {
    super.initState();
    _filteredList = List.from(_masterList);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customIpController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredList = List.from(_masterList);
      } else {
        final query = _searchController.text.toLowerCase();
        _filteredList = _masterList
            .where((dns) =>
                dns.ip.contains(query) ||
                dns.provider.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  Future<void> _checkLatency(DnsModel dns) async {
    setState(() => dns.isScanning = true);
    final stopwatch = Stopwatch()..start();
    try {
      final socket =
          await Socket.connect(dns.ip, 53, timeout: const Duration(seconds: 2));
      socket.destroy();
      stopwatch.stop();
      if (mounted) {
        setState(() {
          dns.latency = stopwatch.elapsedMilliseconds;
          dns.isOnline = true;
          dns.isScanning = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          dns.latency = null;
          dns.isOnline = false;
          dns.isScanning = false;
        });
      }
    }
  }

  Future<void> _runFullScan() async {
    setState(() => _isGlobalScanning = true);
    for (final dns in _masterList) {
      await _checkLatency(dns);
    }
    if (mounted) {
      setState(() {
        _masterList.sort((a, b) {
          if (!a.isOnline && !b.isOnline) return 0;
          if (!a.isOnline) return 1;
          if (!b.isOnline) return -1;
          return a.latency!.compareTo(b.latency!);
        });
        _onSearchChanged();
        _isGlobalScanning = false;
      });
      LogOverlay.showLog("Scan Complete. Sorted by speed.");
    }
  }

  Future<void> _analyzeNetwork({bool showDetails = false}) async {
    setState(() => _isLoadingIp = true);
    try {
      final request = await HttpClient().getUrl(Uri.parse('https://ipwho.is/'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final jsonString = await response.transform(utf8.decoder).join();
        final data = jsonDecode(jsonString);

        if (mounted) {
          setState(() {
            _fullIpDetails = data;
            _publicIp = data['ip'] ?? "Unknown";
            _ispSummary =
                "${data['connection']?['isp'] ?? 'ISP'} (${data['country_code']})";
            _isLoadingIp = false;
          });

          if (showDetails) {
            _showIpDetailSheet();
          }
        }
      } else {
        throw Exception("Failed");
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _ispSummary = "Connection failed";
          _isLoadingIp = false;
        });
      }
    }
  }

  void _showIpDetailSheet() {
    if (_fullIpDetails == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text("Network Intelligence",
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _detailRow(Icons.public, "IP Address", _fullIpDetails!['ip']),
              _detailRow(
                  Icons.router, "ISP", _fullIpDetails!['connection']?['isp']),
              _detailRow(Icons.business, "Organization",
                  _fullIpDetails!['connection']?['org']),
              _detailRow(Icons.location_city, "Location",
                  "${_fullIpDetails!['city']}, ${_fullIpDetails!['region']}"),
              _detailRow(Icons.flag, "Country", _fullIpDetails!['country']),
              _detailRow(Icons.access_time, "Timezone",
                  _fullIpDetails!['timezone']?['id']),
              _detailRow(Icons.map, "Coordinates",
                  "${_fullIpDetails!['latitude']}, ${_fullIpDetails!['longitude']}"),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon,
                size: 20, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value ?? "N/A",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addCustomDns() {
    if (_customIpController.text.isEmpty) return;
    final newDns = DnsModel(
      ip: _customIpController.text.trim(),
      provider: "Custom Server",
    );
    setState(() {
      _masterList.add(newDns);
      _customIpController.clear();
      _onSearchChanged();
    });
    _checkLatency(newDns);
  }

  Color _getLatencyColor(int? latency) {
    if (latency == null) return Colors.grey;
    if (latency < 50) return Colors.greenAccent.shade700;
    if (latency < 150) return Colors.orangeAccent.shade700;
    return Colors.redAccent.shade700;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        centerTitle: true,
        title: const Text("DNS Benchmark",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Reset",
            onPressed: () {
              setState(() {
                for (var item in _masterList) {
                  item.latency = null;
                  item.isOnline = false;
                }
              });
            },
          )
        ],
      ),
      body: Column(
        children: [
          _buildNetworkCard(theme),
          _buildControls(theme),
          Expanded(child: _buildDnsList(theme)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGlobalScanning ? null : _runFullScan,
        icon: _isGlobalScanning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.speed),
        label: Text(_isGlobalScanning ? "Scanning..." : "Start Scan"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildNetworkCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Public IP",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _publicIp.isEmpty ? "---.---.---.---" : _publicIp,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _ispSummary,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2)),
                    icon: _isLoadingIp
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.analytics_outlined,
                            color: Colors.white),
                    onPressed: _isLoadingIp
                        ? null
                        : () => _analyzeNetwork(showDetails: false),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: theme.colorScheme.primary),
                    icon: const Icon(Icons.info_outline),
                    onPressed: () {
                      if (_fullIpDetails != null) {
                        _showIpDetailSheet();
                      } else {
                        _analyzeNetwork(showDetails: true);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search DNS...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.cardColor,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24))),
                builder: (ctx) => Padding(
                  padding: EdgeInsets.only(
                      bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                      left: 24,
                      right: 24,
                      top: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Add Custom DNS", style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _customIpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: "IP Address",
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                              onPressed: () {
                                _addCustomDns();
                                Navigator.pop(ctx);
                              },
                              child: const Text("Add to List"))),
                    ],
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(Icons.add,
                  color: theme.colorScheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDnsList(ThemeData theme) {
    if (_filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dns_outlined, size: 64, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text("No DNS servers found",
                style: TextStyle(color: theme.disabledColor)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _filteredList.length,
      itemBuilder: (context, index) {
        final dns = _filteredList[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                  color: dns.isOnline
                      ? _getLatencyColor(dns.latency).withOpacity(0.3)
                      : Colors.transparent,
                  width: 1.5)),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Clipboard.setData(ClipboardData(text: dns.ip));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("IP ${dns.ip} copied"),
                  duration: const Duration(milliseconds: 600)));
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: dns.isOnline
                          ? _getLatencyColor(dns.latency).withOpacity(0.1)
                          : theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                        child: Icon(Icons.dns,
                            color: dns.isOnline
                                ? _getLatencyColor(dns.latency)
                                : theme.disabledColor)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dns.provider,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(dns.ip,
                            style: TextStyle(
                                fontFamily: 'Monospace',
                                fontSize: 13,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.7))),
                      ],
                    ),
                  ),
                  if (dns.isScanning)
                    const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: dns.isOnline
                            ? _getLatencyColor(dns.latency).withOpacity(0.1)
                            : theme.disabledColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(dns.isOnline ? "${dns.latency} ms" : "---",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: dns.isOnline
                                  ? _getLatencyColor(dns.latency)
                                  : theme.disabledColor)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
