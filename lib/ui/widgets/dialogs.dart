import 'dart:ui';
import 'package:flutter/material.dart';

class AppDialogs {
  static Widget buildDialog({
    required BuildContext context,
    required String title,
    String? content,
    Widget? contentWidget,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: contentWidget ??
              Text(
                content ?? '',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
        ),
      ),
      actions: actions,
    );
  }

  static Widget buildBottomSheet({
    required BuildContext context,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.2),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
