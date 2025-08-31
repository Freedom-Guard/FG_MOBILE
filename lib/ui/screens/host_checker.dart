import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';

class HostCheckerScreen extends StatefulWidget {
  const HostCheckerScreen({Key? key}) : super(key: key);

  @override
  State<HostCheckerScreen> createState() => _HostCheckerScreenState();
}

class _HostCheckerScreenState extends State<HostCheckerScreen> {
  final TextEditingController _urlController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _result;

  final List<String> _defaultUrls = [
    'https://www.google.com',
    'https://www.youtube.com',
    'https://firebase.google.com',
    'https://x.com',
    'https://chat.openai.com',
    'https://gemini.google.com',
    'https://www.tiktok.com',
    'https://www.instagram.com',
    'https://www.facebook.com',
    'https://telegram.org'
  ];

  final Map<String, String> _urlDisplayNames = {
    'https://www.google.com': 'Google',
    'https://www.youtube.com': 'YouTube',
    'https://firebase.google.com': 'Firebase',
    'https://x.com': 'X (Twitter)',
    'https://chat.openai.com': 'ChatGPT',
    'https://gemini.google.com': 'Gemini',
    'https://www.tiktok.com': 'TikTok',
    'https://www.instagram.com': 'Instagram',
    'https://www.facebook.com': 'Facebook',
    'https://telegram.org': 'Telegram'
  };

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _checkHost() async {
    final String url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a URL';
      });
      return;
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      setState(() {
        _errorMessage = 'URL must start with http:// or https://';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    Uri? uri;
    try {
      uri = Uri.parse(url);
      if (uri.host.isEmpty) {
        throw Exception('Invalid host in URL');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Invalid URL format: $e';
      });
      return;
    }

    final String host = uri.host;
    final int port = uri.scheme == 'https' ? 443 : 80;

    Map<String, dynamic> checkResult = {
      'dnsTime': null,
      'dnsError': null,
      'ips': <String>[],
      'connectTime': null,
      'connectError': null,
      'responseTime': null,
      'statusCode': 0,
      'headers': <String, String>{},
      'contentLength': null,
      'isSuccess': false,
      'errorMessage': null,
    };

    try {
      final Stopwatch dnsSw = Stopwatch()..start();
      final List<InternetAddress> addresses =
          await InternetAddress.lookup(host);
      dnsSw.stop();
      checkResult['dnsTime'] = dnsSw.elapsedMilliseconds;
      checkResult['ips'] = addresses.map((e) => e.address).toList();
    } catch (e) {
      checkResult['dnsError'] = e.toString();
    }

    if (checkResult['ips'].isNotEmpty) {
      final String ip = checkResult['ips'][0];
      try {
        final Stopwatch connectSw = Stopwatch()..start();
        final Socket socket =
            await Socket.connect(ip, port).timeout(const Duration(seconds: 5));
        connectSw.stop();
        checkResult['connectTime'] = connectSw.elapsedMilliseconds;
        socket.destroy();
      } catch (e) {
        checkResult['connectError'] = e.toString();
      }
    }

    try {
      final Stopwatch responseSw = Stopwatch()..start();
      final http.Response response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      responseSw.stop();
      checkResult['responseTime'] = responseSw.elapsedMilliseconds;
      checkResult['statusCode'] = response.statusCode;
      checkResult['headers'] = response.headers;
      checkResult['contentLength'] = response.contentLength;
      checkResult['isSuccess'] =
          response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      checkResult['errorMessage'] = e.toString();
    }

    setState(() {
      _isLoading = false;
      _result = checkResult;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Host Checker'),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUrlInput(theme),
            const SizedBox(height: 24),
            _buildCheckButton(theme),
            const SizedBox(height: 24),
            Expanded(
              child: _buildResultSection(theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlInput(ThemeData theme) {
    return Column(
      children: [
        Card(
          color: theme.cardColor,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: TextStyle(color: theme.colorScheme.onBackground),
                    decoration: InputDecoration(
                      hintText: 'Enter URL',
                      hintStyle: TextStyle(
                          color:
                              theme.colorScheme.onBackground.withOpacity(0.5)),
                      border: InputBorder.none,
                      prefixIcon:
                          Icon(Icons.link, color: theme.colorScheme.primary),
                      suffixIcon: _urlController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color: theme.colorScheme.onBackground
                                      .withOpacity(0.5)),
                              onPressed: () {
                                _urlController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _checkHost(),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.arrow_drop_down,
                      color: theme.colorScheme.primary),
                  tooltip: 'Select a default URL',
                  onSelected: (String url) {
                    setState(() {
                      _urlController.text = url;
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    return _defaultUrls.map((String url) {
                      return PopupMenuItem<String>(
                        value: url,
                        child: Text(_urlDisplayNames[url] ?? url),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _defaultUrls.take(5).map((url) {
            return InkWell(
              onTap: () {
                setState(() {
                  _urlController.text = url;
                });
              },
              child: Card(
                color: theme.colorScheme.primary.withOpacity(0.1),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    _urlDisplayNames[url] ?? url,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCheckButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _checkHost,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.5),
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Text(
              'Check Host',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
    );
  }

  Widget _buildResultSection(ThemeData theme) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Checking host...',
              style: TextStyle(
                  color: theme.colorScheme.onBackground.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                  color: theme.colorScheme.onBackground.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_result == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.public,
              color: theme.colorScheme.onBackground.withOpacity(0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Enter a URL and click "Check Host"',
              style: TextStyle(
                  color: theme.colorScheme.onBackground.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(theme),
          const SizedBox(height: 16),
          _buildResponseDetailsCard(theme),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    final bool isSuccess = _result!['isSuccess'];
    final int statusCode = _result!['statusCode'];
    final int? responseTime = _result!['responseTime'];
    final int? connectTime = _result!['connectTime'];
    final int? dnsTime = _result!['dnsTime'];
    final String? errorMessage = _result!['errorMessage'];

    return Card(
      color: theme.cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSuccess
                        ? theme.colorScheme.primary.withOpacity(0.1)
                        : theme.colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSuccess ? Icons.check_circle : Icons.error,
                    color: isSuccess
                        ? theme.colorScheme.primary
                        : theme.colorScheme.error,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isSuccess ? 'Success' : 'Failed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSuccess
                              ? theme.colorScheme.primary
                              : theme.colorScheme.error,
                        ),
                      ),
                      if (statusCode > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Status Code: $statusCode',
                          style: TextStyle(
                              color: theme.colorScheme.onBackground
                                  .withOpacity(0.7)),
                        ),
                      ],
                      if (dnsTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'DNS Time: ${dnsTime}ms',
                          style: TextStyle(
                              color: theme.colorScheme.onBackground
                                  .withOpacity(0.7)),
                        ),
                      ],
                      if (connectTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Ping: ${connectTime}ms',
                          style: TextStyle(
                              color: theme.colorScheme.onBackground
                                  .withOpacity(0.7)),
                        ),
                      ],
                      if (responseTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Response Time: ${responseTime}ms',
                          style: TextStyle(
                              color: theme.colorScheme.onBackground
                                  .withOpacity(0.7)),
                        ),
                      ],
                      if (errorMessage != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          errorMessage,
                          style: TextStyle(
                              color: theme.colorScheme.onBackground
                                  .withOpacity(0.7)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseDetailsCard(ThemeData theme) {
    final int? contentLength = _result!['contentLength'];
    final Map<String, String> headers = _result!['headers'];

    return Card(
      color: theme.cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Response Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('URL', _urlController.text, theme),
            _buildInfoRow(
              'DNS Resolution Time',
              _result!['dnsTime'] != null
                  ? '${_result!['dnsTime']} ms'
                  : 'Failed (${_result!['dnsError'] ?? 'Unknown'})',
              theme,
            ),
            _buildInfoRow(
              'IP Addresses',
              _result!['ips'].isNotEmpty ? _result!['ips'].join(', ') : 'N/A',
              theme,
            ),
            _buildInfoRow(
              'Ping Time',
              _result!['connectTime'] != null
                  ? '${_result!['connectTime']} ms'
                  : 'Failed (${_result!['connectError'] ?? 'Unknown'})',
              theme,
            ),
            _buildInfoRow(
              'HTTP Response Time',
              _result!['responseTime'] != null
                  ? '${_result!['responseTime']} ms'
                  : 'N/A',
              theme,
            ),
            _buildInfoRow('Status Code', '${_result!['statusCode']}', theme),
            _buildInfoRow(
                'Content Length', '${contentLength ?? 'N/A'} bytes', theme),
            if (headers.isNotEmpty) ...[
              const SizedBox(height: 16),
              ExpansionTile(
                title: Text(
                  'Headers',
                  style: TextStyle(
                    color: theme.colorScheme.onBackground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                iconColor: theme.colorScheme.onBackground,
                children: headers.entries.map((entry) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      '${entry.key}: ${entry.value}',
                      style: TextStyle(
                          color:
                              theme.colorScheme.onBackground.withOpacity(0.7)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: theme.colorScheme.onBackground.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: theme.colorScheme.onBackground,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
