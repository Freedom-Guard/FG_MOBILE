import 'package:Freedom_Guard/components/LOGLOG.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

class XraySettingsDialog {
  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> initialConfig,
    required Function(Map<String, dynamic>) onConfigChanged,
  }) async {
    Settings settings = Settings();
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
    bool BypassIranEnabled = await settings.getValue("bypass_iran") == "true";
    TextEditingController concurrencyController = TextEditingController(
      text: initialConfig['mux']?['concurrency']?.toString() ?? '8',
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 12,
          backgroundColor: const Color(0xFF121212),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            activeColor: Theme.of(context).colorScheme.primary,
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
                      const SizedBox(height: 16),
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
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          const Text(
                            'Bypass IRAN',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                          Switch(
                            value: BypassIranEnabled,
                            activeColor: Theme.of(context).colorScheme.primary,
                            activeTrackColor: const Color(0xFF2A2A2A),
                            inactiveThumbColor: Colors.grey[700],
                            inactiveTrackColor: const Color(0xFF424242),
                            onChanged: (value) {
                              setState(() {
                                BypassIranEnabled = value;
                              });
                            },
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            activeColor: Theme.of(context).colorScheme.primary,
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
                      const SizedBox(height: 16),
                      if (muxEnabled)
                        _buildTextField(
                          controller: concurrencyController,
                          label: 'Concurrency',
                          hint: 'e.g., 8',
                        ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFFB0B0B0),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
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
                                'mux': {
                                  'enabled': muxEnabled,
                                  if (muxEnabled)
                                    'concurrency':
                                        int.tryParse(
                                          concurrencyController.text,
                                        ) ??
                                        8,
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
                                'bypass_iran',
                                (BypassIranEnabled.toString()),
                              );
                              onConfigChanged(newConfig);
                              Navigator.pop(context);
                            },
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 16,
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
          ),
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
        fillColor: const Color(0xFF1E1E1E),
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
  Settings settings = Settings();
  Map<String, dynamic> initialConfig = {
    'fragment': {
      'enabled': true,
      'packets': '1-3',
      'length': '100-200',
      'interval': '10-20',
    },
    'mux': {'enabled': false, 'concurrency': 8},
  };
  if (await settings.getValue("fragment") != "") {
    initialConfig["fragment"] = jsonDecode(await settings.getValue("fragment"));
  }
  if (await settings.getValue("mux") != "") {
    initialConfig["mux"] = jsonDecode(await settings.getValue("mux"));
  }
  XraySettingsDialog.show(
    context,
    initialConfig: initialConfig,
    onConfigChanged: (newConfig) {
      String jsonConfig = jsonEncode(newConfig);
      LogOverlay.showLog('Updated Xray Config: $jsonConfig');
    },
  );
}
