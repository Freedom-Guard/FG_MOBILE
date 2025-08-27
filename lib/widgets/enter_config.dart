import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';

Future<String?> showManualConfigDialog(BuildContext context) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext context) {
      return const ManualConfigDialog();
    },
  );
}

class ManualConfigDialog extends StatefulWidget {
  const ManualConfigDialog({super.key});

  @override
  State<ManualConfigDialog> createState() => _ManualConfigDialogState();
}

class _ManualConfigDialogState extends State<ManualConfigDialog> {
  String _protocol = 'vless';
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _uuidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _methodController =
      TextEditingController(text: 'aes-128-gcm');
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _securityController =
      TextEditingController(text: 'none');

  @override
  void dispose() {
    _addressController.dispose();
    _portController.dispose();
    _uuidController.dispose();
    _passwordController.dispose();
    _methodController.dispose();
    _userController.dispose();
    _securityController.dispose();
    super.dispose();
  }

  String? _buildConfigLink() {
    final address = _addressController.text.trim();
    final port = _portController.text.trim();
    if (address.isEmpty || port.isEmpty) return null;

    switch (_protocol) {
      case 'vless':
        final uuid = _uuidController.text.trim();
        if (uuid.isEmpty) return null;
        return 'vless://$uuid@$address:$port?security=${_securityController.text.trim()}';
      case 'vmess':
        final uuid = _uuidController.text.trim();
        if (uuid.isEmpty) return null;
        final json = {
          'v': '2',
          'ps': 'manual',
          'add': address,
          'port': port,
          'id': uuid,
          'aid': '0',
          'net': 'tcp',
          'type': 'none',
          'tls': 'none',
          'path': '',
        };
        return 'vmess://${base64Encode(utf8.encode(jsonEncode(json)))}';
      case 'socks':
        final user = _userController.text.trim();
        final pass = _passwordController.text.trim();
        final auth = user.isNotEmpty && pass.isNotEmpty ? '$user:$pass@' : '';
        return 'socks://$auth$address:$port';
      case 'trojan':
        final pass = _passwordController.text.trim();
        if (pass.isEmpty) return null;
        return 'trojan://$pass@$address:$port';
      case 'ss':
        final method = _methodController.text.trim();
        final pass = _passwordController.text.trim();
        if (method.isEmpty || pass.isEmpty) return null;
        return 'ss://$method:$pass@$address:$port';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Manual Xray Config',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _protocol,
                        decoration: InputDecoration(
                          labelText: 'Protocol',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor:
                              theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'vless', child: Text('VLESS')),
                          DropdownMenuItem(
                              value: 'vmess', child: Text('VMess')),
                          DropdownMenuItem(
                              value: 'socks', child: Text('SOCKS')),
                          DropdownMenuItem(
                              value: 'trojan', child: Text('Trojan')),
                          DropdownMenuItem(
                              value: 'ss', child: Text('Shadowsocks')),
                        ],
                        onChanged: (value) =>
                            setState(() => _protocol = value!),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Server Address',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: theme.colorScheme.primary),
                          ),
                          filled: true,
                          fillColor:
                              theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        ),
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _portController,
                        decoration: InputDecoration(
                          labelText: 'Port',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                BorderSide(color: theme.colorScheme.primary),
                          ),
                          filled: true,
                          fillColor:
                              theme.colorScheme.surfaceVariant.withOpacity(0.5),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      if (_protocol == 'vless' || _protocol == 'vmess')
                        TextField(
                          controller: _uuidController,
                          decoration: InputDecoration(
                            labelText: 'UUID/ID',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: theme.colorScheme.primary),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant
                                .withOpacity(0.5),
                          ),
                        ),
                      if (_protocol == 'vless') const SizedBox(height: 16),
                      if (_protocol == 'vless')
                        TextField(
                          controller: _securityController,
                          decoration: InputDecoration(
                            labelText: 'Security (e.g., none, tls)',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: theme.colorScheme.primary),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant
                                .withOpacity(0.5),
                          ),
                        ),
                      if (_protocol == 'socks') const SizedBox(height: 16),
                      if (_protocol == 'socks')
                        TextField(
                          controller: _userController,
                          decoration: InputDecoration(
                            labelText: 'Username (optional)',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: theme.colorScheme.primary),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant
                                .withOpacity(0.5),
                          ),
                        ),
                      if (_protocol == 'socks' ||
                          _protocol == 'trojan' ||
                          _protocol == 'ss')
                        const SizedBox(height: 16),
                      if (_protocol == 'socks' ||
                          _protocol == 'trojan' ||
                          _protocol == 'ss')
                        TextField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: theme.colorScheme.primary),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant
                                .withOpacity(0.5),
                          ),
                          obscureText: true,
                        ),
                      if (_protocol == 'ss') const SizedBox(height: 16),
                      if (_protocol == 'ss')
                        TextField(
                          controller: _methodController,
                          decoration: InputDecoration(
                            labelText: 'Method (e.g., aes-128-gcm)',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: theme.colorScheme.primary),
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.surfaceVariant
                                .withOpacity(0.5),
                          ),
                        ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              final link = _buildConfigLink();
                              if (link != null) {
                                Navigator.of(context).pop(link);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Confirm'),
                          ),
                        ],
                      ),
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
