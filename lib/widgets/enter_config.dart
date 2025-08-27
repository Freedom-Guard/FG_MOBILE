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
  final TextEditingController _nameController = TextEditingController();
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
    _nameController.dispose();
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
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    final port = _portController.text.trim();
    if (address.isEmpty || port.isEmpty) return null;

    switch (_protocol) {
      case 'vless':
        final uuid = _uuidController.text.trim();
        if (uuid.isEmpty) return null;
        return 'vless://$uuid@$address:$port?security=${_securityController.text.trim()}#$name';
      case 'vmess':
        final uuid = _uuidController.text.trim();
        if (uuid.isEmpty) return null;
        final json = {
          'v': '2',
          'ps': name.isNotEmpty ? name : 'manual',
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
        return 'socks://$auth$address:$port#$name';
      case 'trojan':
        final pass = _passwordController.text.trim();
        if (pass.isEmpty) return null;
        return 'trojan://$pass@$address:$port#$name';
      case 'ss':
        final method = _methodController.text.trim();
        final pass = _passwordController.text.trim();
        if (method.isEmpty || pass.isEmpty) return null;
        return 'ss://$method:$pass@$address:$port#$name';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? double.infinity : 450,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface.withOpacity(0.9),
                  theme.colorScheme.surface.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isSmallScreen ? 20 : 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Manual Config',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  _buildTextField(
                    context,
                    controller: _nameController,
                    label: 'Config Name',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    context,
                    controller: _addressController,
                    label: 'Server Address',
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    context,
                    controller: _portController,
                    label: 'Port',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdownField(context),
                  const SizedBox(height: 16),
                  if (_protocol == 'vless' || _protocol == 'vmess')
                    _buildTextField(
                      context,
                      controller: _uuidController,
                      label: 'UUID/ID',
                    ),
                  if (_protocol == 'vless') const SizedBox(height: 16),
                  if (_protocol == 'vless')
                    _buildTextField(
                      context,
                      controller: _securityController,
                      label: 'Security (e.g., none, tls)',
                    ),
                  if (_protocol == 'socks') const SizedBox(height: 16),
                  if (_protocol == 'socks')
                    _buildTextField(
                      context,
                      controller: _userController,
                      label: 'Username (optional)',
                    ),
                  if (_protocol == 'socks' ||
                      _protocol == 'trojan' ||
                      _protocol == 'ss')
                    const SizedBox(height: 16),
                  if (_protocol == 'socks' ||
                      _protocol == 'trojan' ||
                      _protocol == 'ss')
                    _buildTextField(
                      context,
                      controller: _passwordController,
                      label: 'Password',
                      obscureText: true,
                    ),
                  if (_protocol == 'ss') const SizedBox(height: 16),
                  if (_protocol == 'ss')
                    _buildTextField(
                      context,
                      controller: _methodController,
                      label: 'Method (e.g., aes-128-gcm)',
                    ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildButton(
                        context,
                        text: 'Cancel',
                        isPrimary: false,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      _buildButton(
                        context,
                        text: 'Confirm',
                        isPrimary: true,
                        onPressed: () {
                          final link = _buildConfigLink();
                          if (link != null) {
                            Navigator.of(context).pop(link);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.75),
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainer.withOpacity(0.65),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        prefixIcon: Icon(
          _getIconForLabel(label),
          color: theme.colorScheme.primary.withOpacity(0.8),
          size: 22,
        ),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildDropdownField(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: _protocol,
      decoration: InputDecoration(
        labelText: 'Protocol',
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.75),
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: theme.colorScheme.surfaceContainer.withOpacity(0.65),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2.5,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        prefixIcon: Icon(
          Icons.security_rounded,
          color: theme.colorScheme.primary.withOpacity(0.8),
          size: 22,
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'vless', child: Text('VLESS')),
        DropdownMenuItem(value: 'vmess', child: Text('VMess')),
        DropdownMenuItem(value: 'socks', child: Text('SOCKS')),
        DropdownMenuItem(value: 'trojan', child: Text('Trojan')),
        DropdownMenuItem(value: 'ss', child: Text('Shadowsocks')),
      ],
      onChanged: (value) => setState(() => _protocol = value!),
      style: theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      dropdownColor: theme.colorScheme.surfaceContainer.withOpacity(0.95),
      borderRadius: BorderRadius.circular(20),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String text,
    required bool isPrimary,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHigh.withOpacity(0.8),
        foregroundColor: isPrimary
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        elevation: isPrimary ? 6 : 0,
        shadowColor:
            isPrimary ? theme.colorScheme.primary.withOpacity(0.4) : null,
      ),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'Config Name':
        return Icons.label_rounded;
      case 'Server Address':
        return Icons.dns_rounded;
      case 'Port':
        return Icons.numbers_rounded;
      case 'UUID/ID':
        return Icons.fingerprint_rounded;
      case 'Security (e.g., none, tls)':
        return Icons.lock_rounded;
      case 'Username (optional)':
        return Icons.person_rounded;
      case 'Password':
        return Icons.key_rounded;
      case 'Method (e.g., aes-128-gcm)':
        return Icons.vpn_key_rounded;
      default:
        return Icons.text_fields_rounded;
    }
  }
}
