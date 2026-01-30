import 'dart:ui';

import 'package:Freedom_Guard/utils/LOGLOG.dart';
import 'package:Freedom_Guard/core/local.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class XraySettingsDialog {
  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> initialConfig,
    required Function(Map<String, dynamic>) onConfigChanged,
  }) async {
    SettingsApp settings = SettingsApp();

    bool fragmentEnabled = initialConfig['fragment']?['enabled'] ?? true;
    TextEditingController packetsController = TextEditingController(
      text: initialConfig['fragment']?['packets']?.toString() ?? '1-3',
    );
    TextEditingController lengthController = TextEditingController(
      text: initialConfig['fragment']?['length']?.toString() ?? '100-200',
    );
    TextEditingController intervalController = TextEditingController(
      text: initialConfig['fragment']?['interval']?.toString() ?? '10-20',
    );

    bool muxEnabled = initialConfig['mux']?['enabled'] ?? false;
    TextEditingController concurrencyController = TextEditingController(
      text: initialConfig['mux']?['concurrency']?.toString() ?? '8',
    );

    bool bypassIranEnabled = await settings.getValue("bypass_iran") == "true";

    bool fakeDnsEnabled = initialConfig['fakedns']?['enabled'] ?? false;
    TextEditingController ipPoolController = TextEditingController(
      text: initialConfig['fakedns']?['ipPool']?.toString() ?? '198.18.0.0/15',
    );
    TextEditingController poolSizeController = TextEditingController(
      text: initialConfig['fakedns']?['lruSize']?.toString() ?? '65535',
    );

    bool sniEnabled = initialConfig['sni']?['enabled'] ?? false;
    TextEditingController sniController = TextEditingController(
      text: initialConfig['sni']?['serverName']?.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 12,
          backgroundColor: Colors.transparent,
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.08),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white.withOpacity(.2)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Fragment',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  Switch(
                                    value: fragmentEnabled,
                                    activeColor:
                                        Theme.of(context).colorScheme.primary,
                                    activeTrackColor: const Color(0xFF2A2A2A),
                                    inactiveThumbColor: Colors.grey[700],
                                    inactiveTrackColor: const Color(0xFF424242),
                                    onChanged: (value) {
                                      setState(() {
                                        fragmentEnabled = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (fragmentEnabled) ...[
                                _buildTextField(
                                  controller: packetsController,
                                  label: 'Packets',
                                  hint: 'e.g., 1-3',
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  controller: lengthController,
                                  label: 'Length',
                                  hint: 'e.g., 100-200',
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  controller: intervalController,
                                  label: 'Interval (ms)',
                                  hint: 'e.g., 10-20',
                                ),
                              ],
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Mux',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  Switch(
                                    value: muxEnabled,
                                    activeColor:
                                        Theme.of(context).colorScheme.primary,
                                    activeTrackColor: const Color(0xFF2A2A2A),
                                    inactiveThumbColor: Colors.grey[700],
                                    inactiveTrackColor: const Color(0xFF424242),
                                    onChanged: (value) {
                                      setState(() {
                                        muxEnabled = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (muxEnabled)
                                _buildTextField(
                                  controller: concurrencyController,
                                  label: 'Concurrency',
                                  hint: 'e.g., 8',
                                ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'FakeDNS',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  Switch(
                                    value: fakeDnsEnabled,
                                    activeColor:
                                        Theme.of(context).colorScheme.primary,
                                    activeTrackColor: const Color(0xFF2A2A2A),
                                    inactiveThumbColor: Colors.grey[700],
                                    inactiveTrackColor: const Color(0xFF424242),
                                    onChanged: (value) {
                                      setState(() {
                                        fakeDnsEnabled = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (fakeDnsEnabled) ...[
                                _buildTextField(
                                  controller: ipPoolController,
                                  label: 'IP Pool',
                                  hint: 'e.g., 198.18.0.0/15',
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  controller: poolSizeController,
                                  label: 'Pool Size',
                                  hint: 'e.g., 65535',
                                ),
                              ],
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'SNI',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  Switch(
                                    value: sniEnabled,
                                    activeColor:
                                        Theme.of(context).colorScheme.primary,
                                    activeTrackColor: const Color(0xFF2A2A2A),
                                    inactiveThumbColor: Colors.grey[700],
                                    inactiveTrackColor: const Color(0xFF424242),
                                    onChanged: (value) {
                                      setState(() {
                                        sniEnabled = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (sniEnabled) ...[
                                _buildTextField(
                                  controller: sniController,
                                  label: 'Server Name (SNI)',
                                  hint: 'e.g. www.cloudflare.com',
                                ),
                              ],
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Bypass Iran',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFE0E0E0),
                                    ),
                                  ),
                                  Switch(
                                    value: bypassIranEnabled,
                                    activeColor:
                                        Theme.of(context).colorScheme.primary,
                                    activeTrackColor: const Color(0xFF2A2A2A),
                                    inactiveThumbColor: Colors.grey[700],
                                    inactiveTrackColor: const Color(0xFF424242),
                                    onChanged: (value) {
                                      setState(() {
                                        bypassIranEnabled = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      tr('cancel'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFFB0B0B0),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      foregroundColor: const Color(0xFF121212),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 12,
                                      ),
                                      elevation: 6,
                                    ),
                                    onPressed: () {
                                      Map<String, dynamic> newConfig = {
                                        'fragment': {
                                          'enabled': fragmentEnabled,
                                          if (fragmentEnabled) ...{
                                            'packets': packetsController.text,
                                            'length': lengthController.text,
                                            'interval': intervalController.text,
                                          },
                                        },
                                        'sni': {
                                          'enabled': sniEnabled,
                                          if (sniEnabled)
                                            'serverName':
                                                sniController.text.trim(),
                                        },
                                        'mux': {
                                          'enabled': muxEnabled,
                                          if (muxEnabled)
                                            'concurrency': int.tryParse(
                                                  concurrencyController.text,
                                                ) ??
                                                8,
                                        },
                                        'fakedns': {
                                          'enabled': fakeDnsEnabled,
                                          if (fakeDnsEnabled) ...{
                                            'ipPool': ipPoolController.text,
                                            'lruSize': int.tryParse(
                                                    poolSizeController.text) ??
                                                65535,
                                          },
                                        },
                                      };
                                      settings.setValue(
                                        'fragment',
                                        jsonEncode(newConfig['fragment']),
                                      );
                                      settings.setValue(
                                        'mux',
                                        jsonEncode(newConfig['mux']),
                                      );
                                      settings.setValue(
                                        'fakedns',
                                        jsonEncode(newConfig['fakedns']),
                                      );
                                      settings.setValue(
                                        'sni',
                                        jsonEncode(newConfig['sni']),
                                      );
                                      settings.setValue(
                                        'bypass_iran',
                                        bypassIranEnabled.toString(),
                                      );
                                      onConfigChanged(newConfig);
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      tr('save'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ))),
        );
      },
    );
  }

  static Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: Color(0xFFB0B0B0),
          fontWeight: FontWeight.w500,
        ),
        hintStyle: const TextStyle(color: Color(0xFF757575)),
        filled: true,
        fillColor: Colors.white.withOpacity(.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00E676), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: const TextStyle(fontSize: 16, color: Color(0xFFE0E0E0)),
      cursorColor: const Color(0xFF00E676),
    );
  }
}

Future<void> openXraySettings(BuildContext context) async {
  SettingsApp settings = SettingsApp();
  Map<String, dynamic> initialConfig = {
    'fragment': {
      'enabled': true,
      'packets': '1-3',
      'length': '100-200',
      'interval': '10-20',
    },
    'sni': {'enabled': false, 'serverName': ''},
    'mux': {'enabled': false, 'concurrency': 8},
    'fakedns': {'enabled': false, 'ipPool': '198.18.0.0/15', 'lruSize': 65535},
  };
  if (await settings.getValue("fragment") != "") {
    initialConfig["fragment"] = jsonDecode(await settings.getValue("fragment"));
  }
  if (await settings.getValue("mux") != "") {
    initialConfig["mux"] = jsonDecode(await settings.getValue("mux"));
  }
  if (await settings.getValue("fakedns") != "") {
    initialConfig["fakedns"] = jsonDecode(await settings.getValue("fakedns"));
  }
  if (await settings.getValue("sni") != "") {
    initialConfig["sni"] = jsonDecode(await settings.getValue("sni"));
  }
  XraySettingsDialog.show(
    context,
    initialConfig: initialConfig,
    onConfigChanged: (newConfig) {
      String jsonConfig = jsonEncode(newConfig);
      LogOverlay.showLog('Updated Xray Config: \n $jsonConfig');
    },
  );
}
