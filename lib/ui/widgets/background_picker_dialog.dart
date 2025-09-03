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
    TextEditingController hexController = TextEditingController(
        text: '#${Colors.blue.value.toRadixString(16).padLeft(8, '0')}');
    TextEditingController rController =
        TextEditingController(text: Colors.blue.red.toString());
    TextEditingController gController =
        TextEditingController(text: Colors.blue.green.toString());
    TextEditingController bController =
        TextEditingController(text: Colors.blue.blue.toString());

    return showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AppDialogs.buildDialog(
          context: context,
          title: 'Choose Background',
          contentWidget: StatefulBuilder(
            builder: (context, setState) {
              void updateColorFromRGB() {
                int r = int.tryParse(rController.text) ?? 0;
                int g = int.tryParse(gController.text) ?? 0;
                int b = int.tryParse(bController.text) ?? 0;
                selectedColor = Color.fromARGB(255, r, g, b);
                hexController.text =
                    '#${selectedColor.value.toRadixString(16).padLeft(8, '0')}';
                setState(() {});
              }

              void updateColorFromHex() {
                String hex = hexController.text.replaceAll('#', '');
                if (hex.length == 6 || hex.length == 8) {
                  int value = int.parse(hex, radix: 16);
                  if (hex.length == 6) value += 0xFF000000;
                  selectedColor = Color(value);
                  rController.text = selectedColor.red.toString();
                  gController.text = selectedColor.green.toString();
                  bController.text = selectedColor.blue.toString();
                  setState(() {});
                }
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
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
                            Colors.cyan,
                            Colors.indigo,
                            Colors.lime,
                            Colors.amber,
                            Colors.deepOrange,
                            Colors.deepPurple
                          ])
                            GestureDetector(
                              onTap: () {
                                setState(() => selectedColor = color);
                                rController.text = color.red.toString();
                                gController.text = color.green.toString();
                                bController.text = color.blue.toString();
                                hexController.text =
                                    '#${color.value.toRadixString(16).padLeft(8, '0')}';
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: selectedColor == color
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2),
                                ),
                                child: CircleAvatar(
                                  backgroundColor: color,
                                  radius: 28,
                                  child: selectedColor == color
                                      ? const Icon(Icons.check,
                                          color: Colors.white)
                                      : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rController,
                            decoration: const InputDecoration(labelText: 'R'),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => updateColorFromRGB(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: gController,
                            decoration: const InputDecoration(labelText: 'G'),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => updateColorFromRGB(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: bController,
                            decoration: const InputDecoration(labelText: 'B'),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => updateColorFromRGB(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: hexController,
                      decoration:
                          const InputDecoration(labelText: 'Hex (#RRGGBB)'),
                      onChanged: (_) => updateColorFromHex(),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.image),
                      label: const Text("Choose Image"),
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                        );
                        if (result != null &&
                            result.files.single.path != null) {
                          setState(() =>
                              selectedImage = File(result.files.single.path!));
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
                  borderRadius: BorderRadius.circular(12),
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
}
