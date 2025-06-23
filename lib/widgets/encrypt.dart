import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/services.dart';
import 'dart:math';

void showEncryptDecryptDialog(BuildContext context) {
  final TextEditingController configController = TextEditingController();
  final TextEditingController keyController = TextEditingController();
  String? resultText;
  bool isEncryptMode = true;
  bool showResult = false;
  bool isProcessing = false;
  bool obscureKey = true;

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFF1C1C1E),
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, animation) => ScaleTransition(
                    scale: animation,
                    child: child,
                  ),
                  child: Icon(
                    isEncryptMode ? Icons.lock : Icons.lock_open,
                    key: ValueKey(isEncryptMode),
                    color: Colors.blueAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEncryptMode ? 'Encrypt Config' : 'Decrypt Config',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white54),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: configController,
                decoration: InputDecoration(
                  hintText: 'Enter config text',
                  hintStyle:
                      const TextStyle(color: Colors.white54, fontSize: 14),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.paste,
                            color: Colors.white54, size: 20),
                        onPressed: () async {
                          final clipboardData =
                              await Clipboard.getData('text/plain');
                          if (clipboardData?.text != null) {
                            configController.text = clipboardData!.text!;
                            setState(() {});
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.white54, size: 20),
                        onPressed: () {
                          configController.clear();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 4,
                minLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyController,
                obscureText: obscureKey,
                decoration: InputDecoration(
                  hintText: 'Encryption key (32 characters)',
                  hintStyle:
                      const TextStyle(color: Colors.white54, fontSize: 14),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          obscureKey ? Icons.visibility : Icons.visibility_off,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => obscureKey = !obscureKey),
                      ),
                      IconButton(
                        icon: const Icon(Icons.autorenew,
                            color: Colors.white54, size: 20),
                        onPressed: () {
                          keyController.text = _generateRandomKey();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModeChip(
                    label: 'Encrypt',
                    isSelected: isEncryptMode,
                    onSelected: () => setState(() => isEncryptMode = true),
                  ),
                  const SizedBox(width: 12),
                  _buildModeChip(
                    label: 'Decrypt',
                    isSelected: !isEncryptMode,
                    onSelected: () => setState(() => isEncryptMode = false),
                  ),
                ],
              ),
              if (showResult) ...[
                const SizedBox(height: 16),
                AnimatedOpacity(
                  opacity: showResult ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Result:',
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy,
                                  color: Colors.white54, size: 20),
                              onPressed: () => Clipboard.setData(
                                  ClipboardData(text: resultText ?? '')),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          resultText ?? '',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white54,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Cancel', style: TextStyle(fontSize: 14)),
          ),
          ElevatedButton(
            onPressed: isProcessing
                ? null
                : () async {
                    if (configController.text.isEmpty ||
                        keyController.text.isEmpty) {
                      _showSnackBar(
                          context, 'Please fill both fields', Colors.redAccent);
                      return;
                    }
                    if (keyController.text.length < 8) {
                      _showSnackBar(
                          context,
                          'Key must be at least 8 characters',
                          Colors.redAccent);
                      return;
                    }
                    setState(() => isProcessing = true);
                    await Future.delayed(const Duration(
                        milliseconds: 300)); // Simulate processing
                    try {
                      final result = isEncryptMode
                          ? encryptConfig(
                              configController.text, keyController.text)
                          : decryptConfig(
                              configController.text, keyController.text);
                      Clipboard.setData(ClipboardData(text: result));
                      setState(() {
                        resultText = result;
                        showResult = true;
                        isProcessing = false;
                      });
                      _showSnackBar(
                        context,
                        isEncryptMode
                            ? 'Encrypted and copied to clipboard'
                            : 'Decrypted and copied to clipboard',
                        Colors.blueAccent,
                      );
                    } catch (e) {
                      setState(() => isProcessing = false);
                      _showSnackBar(
                          context, 'Error: ${e.toString()}', Colors.redAccent);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              elevation: 3,
            ),
            child: isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Process', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    ),
  );
}

Widget _buildModeChip({
  required String label,
  required bool isSelected,
  required VoidCallback onSelected,
}) {
  return GestureDetector(
    onTap: onSelected,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blueAccent : Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: isSelected ? Colors.blueAccent : Colors.white12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white70,
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    ),
  );
}

void _showSnackBar(BuildContext context, String message, Color color) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ),
  );
}

String encryptConfig(String plainText, String key) {
  final keyBytes = encrypt.Key.fromUtf8(key.padRight(32, '0').substring(0, 32));
  final iv = encrypt.IV.fromSecureRandom(16);
  final encrypter =
      encrypt.Encrypter(encrypt.AES(keyBytes, mode: encrypt.AESMode.cbc));
  final encrypted = encrypter.encrypt(plainText, iv: iv);
  return '${encrypted.base64}:${iv.base64}';
}

String decryptConfig(String encryptedText, String key) {
  final parts = encryptedText.split(':');
  if (parts.length != 2) throw Exception('Invalid encrypted format');
  final keyBytes = encrypt.Key.fromUtf8(key.padRight(32, '0').substring(0, 32));
  final iv = encrypt.IV.fromBase64(parts[1]);
  final encrypter =
      encrypt.Encrypter(encrypt.AES(keyBytes, mode: encrypt.AESMode.cbc));
  final decrypted = encrypter.decrypt64(parts[0], iv: iv);
  return decrypted;
}

String _generateRandomKey() {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
  return String.fromCharCodes(
    Iterable.generate(
        32, (_) => chars.codeUnitAt(Random().nextInt(chars.length))),
  );
}
