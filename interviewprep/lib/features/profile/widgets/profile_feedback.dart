import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

void showProfileMessage(
  BuildContext context,
  String text, {
  bool error = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      backgroundColor: error ? AppTheme.error : Colors.green,
    ),
  );
}
