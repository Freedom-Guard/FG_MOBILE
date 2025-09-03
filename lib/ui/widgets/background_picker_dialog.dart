import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:Freedom_Guard/ui/widgets/dialogs.dart';

class BackgroundNotifier extends ChangeNotifier {
  String _background = "";

  String get background => _background;

  void setBackground(String value) {
    _background = value;
    notifyListeners();
  }
}

class BackgroundPickerDialog {
  static Future<void> show(BuildContext context) async {
    Color selectedColor = Colors.blue;
    File? selectedImage;
    TextEditingController rController = TextEditingController();
    TextEditingController gController = TextEditingController();
    TextEditingController bController = TextEditingController();

    void updateRGBFields(Color color) {
      rController.text = color.red.toString();
      gController.text = color.green.toString();
      bController.text = color.blue.toString();
    }

    return showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AppDialogs.buildDialog(
          context: context,
          title: 'Choose Background',
          contentWidget: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.75,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // RGB Inputs Glass Style
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _glassRGBInput('R', rController, (value) {
                                int r = int.tryParse(value) ?? 0;
                                setState(() {
                                  selectedColor =
                                      selectedColor.withRed(r.clamp(0, 255));
                                });
                              }, selectedColor.red),
                              const SizedBox(width: 6),
                              _glassRGBInput('G', gController, (value) {
                                int g = int.tryParse(value) ?? 0;
                                setState(() {
                                  selectedColor =
                                      selectedColor.withGreen(g.clamp(0, 255));
                                });
                              }, selectedColor.green),
                              const SizedBox(width: 6),
                              _glassRGBInput('B', bController, (value) {
                                int b = int.tryParse(value) ?? 0;
                                setState(() {
                                  selectedColor =
                                      selectedColor.withBlue(b.clamp(0, 255));
                                });
                              }, selectedColor.blue),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (var color in [
                              Colors.red,
                              Colors.green,
                              Colors.blue,
                              Colors.yellow,
                              Colors.orange,
                              Colors.purple,
                              Colors.teal,
                              Colors.pink,
                              Colors.brown,
                              Colors.cyan
                            ])
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = color;
                                    updateRGBFields(color);
                                  });
                                },
                                child: CircleAvatar(
                                  backgroundColor: color,
                                  radius: 20,
                                  child: selectedColor == color
                                      ? Icon(Icons.check,
                                          color: Colors.white, size: 18)
                                      : null,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.image),
                          label: const Text("Choose Image"),
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                            );
                            if (result != null &&
                                result.files.single.path != null) {
                              setState(() => selectedImage =
                                  File(result.files.single.path!));
                            }
                          },
                        ),
                        if (selectedImage != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(selectedImage!,
                                height: 100, fit: BoxFit.cover),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () async {
                final bgNotifier =
                    Provider.of<BackgroundNotifier>(context, listen: false);
                await SettingsApp().setValue("selectedIMG", "");
                await SettingsApp().setValue("selectedColor", "");
                bgNotifier.setBackground("");
                Navigator.pop(context);
              },
              child: const Text('Reset',
                  style: TextStyle(color: Colors.orangeAccent)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () async {
                final bgNotifier =
                    Provider.of<BackgroundNotifier>(context, listen: false);
                if (selectedImage != null) {
                  await SettingsApp()
                      .setValue("selectedIMG", selectedImage!.path);
                  await SettingsApp().setValue("selectedColor", "");
                  bgNotifier.setBackground(selectedImage!.path);
                } else {
                  final hexColor =
                      '#${selectedColor.value.toRadixString(16).padLeft(8, '0')}';
                  await SettingsApp().setValue("selectedIMG", "");
                  await SettingsApp().setValue("selectedColor", hexColor);
                  bgNotifier.setBackground(hexColor);
                }
                Navigator.pop(context);
              },
              child: const Text('Apply', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  static Expanded _glassRGBInput(
    String label,
    TextEditingController controller,
    Function(String) onChanged,
    int value,
  ) {
    controller.text = value.toString();
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
                fontSize: 12),
            border: InputBorder.none,
          ),
          onChanged: (v) => onChanged(v),
        ),
      ),
    );
  }
}
