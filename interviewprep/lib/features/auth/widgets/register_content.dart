import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'auth_widgets.dart';
import 'register_fields.dart';

class RegisterContent extends ConsumerWidget {
  const RegisterContent({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.acceptCGU,
    required this.onTogglePassword,
    required this.onToggleConfirmPassword,
    required this.onAcceptChanged,
    required this.onShowLegalDocument,
    required this.onRegister,
    super.key,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final bool acceptCGU;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirmPassword;
  final ValueChanged<bool> onAcceptChanged;
  final void Function(String title, String content) onShowLegalDocument;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(authStateProvider) is AsyncLoading<void>;
    return AuthPageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: 'Create Account',
            subtitle: 'Join InterviewPrep today.',
          ),
          AuthCard(
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    label: 'Full Name',
                    controller: nameController,
                    hint: 'John Doe',
                    icon: Icons.person_outline,
                    validator: (value) =>
                        value!.isEmpty ? 'Veuillez entrer votre nom' : null,
                  ),
                  const SizedBox(height: 16),
                  AuthTextField(
                    label: 'Email Address',
                    controller: emailController,
                    hint: 'name@company.com',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value!.isEmpty ? 'Veuillez entrer votre email' : null,
                  ),
                  const SizedBox(height: 16),
                  AuthPasswordField(
                    label: 'Password',
                    controller: passwordController,
                    obscureText: obscurePassword,
                    onToggle: onTogglePassword,
                    validator: (value) =>
                        value!.length < 8 ? 'Minimum 8 caractères' : null,
                  ),
                  const SizedBox(height: 16),
                  AuthPasswordField(
                    label: 'Confirm Password',
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    onToggle: onToggleConfirmPassword,
                    validator: (value) {
                      if (value!.isEmpty) return 'Veuillez confirmer';
                      if (value != passwordController.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  AuthTerms(
                    accepted: acceptCGU,
                    onChanged: onAcceptChanged,
                    onShowLegalDocument: onShowLegalDocument,
                  ),
                  const SizedBox(height: 24),
                  AuthSubmitButton(
                    loading: loading,
                    onPressed: onRegister,
                    label: 'Sign Up',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'Log In',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
