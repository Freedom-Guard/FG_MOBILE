import 'dart:io';
import 'package:Freedom_Guard/components/settings.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:Freedom_Guard/ui/widgets/dialogs.dart';

class BackgroundPickerDialog {
  static Future<void> show(BuildContext context) async {
    Color selectedColor = Colors.blue;
    File? selectedImage;

    return showDialog(
      context: context,
      builder: (context) => AppDialogs.buildDialog(
        context: context,
        title: 'Choose Background',
        contentWidget: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => selectedColor = Colors.red),
                      child: CircleAvatar(
                        backgroundColor: Colors.red,
                        radius: 20,
                        child: selectedColor == Colors.red
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => selectedColor = Colors.green),
                      child: CircleAvatar(
                        backgroundColor: Colors.green,
                        radius: 20,
                        child: selectedColor == Colors.green
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => selectedColor = Colors.blue),
                      child: CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 20,
                        child: selectedColor == Colors.blue
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text("Choose Image"),
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                    );
                    if (result != null && result.files.single.path != null) {
                      setState(() =>
                          selectedImage = File(result.files.single.path!));
                    }
                  },
                ),
                if (selectedImage != null) ...[
                  const SizedBox(height: 12),
                  Image.file(selectedImage!, height: 100),
                ],
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (selectedImage != null) {
                await SettingsApp().setValue("selectedIMG", selectedImage!.path);
                await SettingsApp().setValue("selectedColor", "");
              } else {
                final hexColor =
                    '#${selectedColor.value.toRadixString(16).padLeft(8, '0')}';
                await SettingsApp().setValue("selectedIMG", "");
                await SettingsApp().setValue("selectedColor", hexColor);
              }
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
