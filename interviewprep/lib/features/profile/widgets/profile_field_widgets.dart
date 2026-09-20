import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ProfileFieldWidgets {
  ProfileFieldWidgets(this.context);
  final BuildContext context;
  Widget label(String text) => Text(
    text,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: AppTheme.onSurfaceVariant,
      fontSize: 12,
      letterSpacing: 1.2,
    ),
  );
  InputDecoration decoration(IconData icon) =>
      InputDecoration(prefixIcon: Icon(icon));

  Widget textField(
    String labelText,
    TextEditingController controller,
    String hint,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      label(labelText),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        style: const TextStyle(color: AppTheme.onSurface),
        decoration: decoration(Icons.person_outline).copyWith(hintText: hint),
      ),
    ],
  );

  Widget dropdown(
    String labelText,
    String? value,
    IconData icon,
    List<DropdownMenuItem<String>> items,
    ValueChanged<String?> onChanged,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      label(labelText),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        initialValue: value,
        style: const TextStyle(color: AppTheme.onSurface),
        decoration: decoration(icon),
        dropdownColor: AppTheme.surfaceContainerLowest,
        items: items,
        onChanged: onChanged,
      ),
    ],
  );
}
