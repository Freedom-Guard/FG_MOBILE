import 'dart:io';
import 'package:flutter/material.dart';

BoxDecoration buildBackground(String pathOrColor) {
  if (pathOrColor.startsWith("#")) {
    int colorInt = int.tryParse(pathOrColor.substring(1), radix: 16) ?? 0xFF000000;
    return BoxDecoration(color: Color(colorInt));
  } else if (pathOrColor.startsWith("assets/")) {
    return BoxDecoration(
      image: DecorationImage(
        image: AssetImage(pathOrColor),
        fit: BoxFit.cover,
      ),
    );
  } else {
    final file = File(pathOrColor);
    if (file.existsSync()) {
      return BoxDecoration(
        image: DecorationImage(
          image: FileImage(file),
          fit: BoxFit.cover,
        ),
      );
    } else {
      return BoxDecoration(color: Colors.black);
    }
  }
}
