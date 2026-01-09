import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/settings/data/app_settings_repository.dart';

class PinAuth {
  static Future<bool> requirePin(
    BuildContext context,
    WidgetRef ref, {
    String? reason,
  }) async {
    final pin = await ref.read(pinCodeProvider.future);
    if (pin == null || pin.isEmpty) return true;

    if (!context.mounted) return false;

    final unlocked = ref.read(pinUnlockedProvider);
    if (unlocked) return true;

    final controller = TextEditingController();
    String? errorText;

    final title = (reason == null || reason.trim().isEmpty)
        ? 'Enter PIN'
        : reason;

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(title),
              content: TextField(
                controller: controller,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'PIN',
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
                onSubmitted: (_) {
                  final entered = controller.text.trim();
                  if (entered == pin) {
                    Navigator.pop(context, true);
                  } else {
                    setState(() => errorText = 'Incorrect PIN');
                  }
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final entered = controller.text.trim();
                    if (entered == pin) {
                      Navigator.pop(context, true);
                    } else {
                      setState(() => errorText = 'Incorrect PIN');
                    }
                  },
                  child: const Text('Unlock'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (ok == true) {
      ref.read(pinUnlockedProvider.notifier).state = true;
      return true;
    }

    return false;
  }
}
