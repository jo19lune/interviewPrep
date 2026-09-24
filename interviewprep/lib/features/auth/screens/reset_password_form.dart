import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';

class ResetPasswordForm extends StatelessWidget {
  const ResetPasswordForm({
    super.key,
    required this.formKey,
    required this.codeController,
    required this.passwordController,
    required this.confirmController,
    required this.isLoading,
    required this.obscurePassword,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController codeController;
  final TextEditingController passwordController;
  final TextEditingController confirmController;
  final bool isLoading;
  final bool obscurePassword;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.vpn_key, size: 48, color: AppTheme.primaryContainer),
          const SizedBox(height: 16),
          Text(
            'Définir un nouveau mot de passe',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              color: AppTheme.primaryContainer,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: codeController,
            decoration: const InputDecoration(
              labelText: 'Code de vérification',
              hintText: '123456',
              prefixIcon: Icon(Icons.numbers),
            ),
            keyboardType: TextInputType.number,
            maxLength: 6,
            enabled: !isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer le code';
              }
              if (value.length != 6) return 'Le code doit contenir 6 chiffres';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _passwordField(
            controller: passwordController,
            label: 'Nouveau mot de passe',
            hint: 'Minimum 8 caractères',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un mot de passe';
              }
              if (value.length < 8) return 'Minimum 8 caractères requis';
              return null;
            },
          ),
          const SizedBox(height: 16),
          _passwordField(
            controller: confirmController,
            label: 'Confirmer le mot de passe',
            hint: 'Retapez le mot de passe',
            validator: (value) => value != passwordController.text
                ? 'Les mots de passe ne correspondent pas'
                : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isLoading ? null : onSubmit,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Réinitialiser le mot de passe'),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: isLoading ? null : () => context.go('/forgot-password'),
            child: const Text('Renvoyer un code'),
          ),
          TextButton(
            onPressed: isLoading ? null : () => context.go('/login'),
            child: const Text('Retour à la connexion'),
          ),
        ],
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.outline,
          ),
          onPressed: onToggleObscure,
        ),
      ),
      obscureText: obscurePassword,
      enabled: !isLoading,
      validator: validator,
    );
  }
}
