import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.label,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.validator,
    this.keyboardType,
    super.key,
  });
  final String label;
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        decoration: InputDecoration(hintText: hint, prefixIcon: Icon(icon)),
        keyboardType: keyboardType,
        validator: validator,
      ),
    ],
  );
}

class AuthPasswordField extends StatelessWidget {
  const AuthPasswordField({
    required this.label,
    required this.controller,
    required this.obscureText,
    required this.onToggle,
    required this.validator,
    super.key,
  });
  final String label;
  final TextEditingController controller;
  final bool obscureText;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: '••••••••',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: AppTheme.outline,
            ),
            onPressed: onToggle,
          ),
        ),
        validator: validator,
      ),
    ],
  );
}

class AuthTerms extends StatelessWidget {
  const AuthTerms({
    required this.accepted,
    required this.onChanged,
    required this.onShowLegalDocument,
    super.key,
  });
  final bool accepted;
  final ValueChanged<bool> onChanged;
  final void Function(String title, String content) onShowLegalDocument;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Accepter les conditions générales et la politique de confidentialité',
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: accepted,
          onChanged: (value) => onChanged(value ?? false),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
                children: [
                  const TextSpan(text: 'J\'accepte les '),
                  _link(
                    'Conditions Générales d\'Utilisation',
                    'Conditions Générales d\'Utilisation',
                    'Contenu des CGU... (à compléter)',
                  ),
                  const TextSpan(text: ' et la '),
                  _link(
                    'Politique de Confidentialité',
                    'Politique de Confidentialité',
                    'Contenu de la politique de confidentialité... (à compléter)',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  TextSpan _link(String text, String title, String content) => TextSpan(
    text: text,
    style: const TextStyle(
      color: AppTheme.secondaryColor,
      decoration: TextDecoration.underline,
    ),
    recognizer: TapGestureRecognizer()
      ..onTap = () => onShowLegalDocument(title, content),
  );
}
