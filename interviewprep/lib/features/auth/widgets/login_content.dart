import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'auth_widgets.dart';
import 'login_footer.dart';
import 'login_sections.dart';

class LoginContent extends ConsumerWidget {
  const LoginContent({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberMe,
    required this.successOverlayVisible,
    required this.onTogglePassword,
    required this.onRememberChanged,
    required this.onLogin,
    required this.onGoogleLogin,
    required this.onForgetAccount,
    super.key,
  });
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberMe;
  final bool successOverlayVisible;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onLogin;
  final VoidCallback onGoogleLogin;
  final VoidCallback onForgetAccount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(authStateProvider) is AsyncLoading<void>;
    return Stack(
      children: [
        AuthPageFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthHeader(
                title: 'Welcome back',
                subtitle: 'Your career breakthrough starts here.',
              ),
              AuthCard(
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Email Address',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          hintText: 'name@company.com',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value!.isEmpty
                            ? 'Veuillez entrer votre email'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Password',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          TextButton(
                            onPressed: () => context.go('/forgot-password'),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot password?',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: AppTheme.secondaryColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppTheme.outline,
                            ),
                            onPressed: onTogglePassword,
                          ),
                        ),
                        validator: (value) => value!.isEmpty
                            ? 'Veuillez entrer votre mot de passe'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Semantics(
                        label: 'Se souvenir de moi',
                        child: Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (value) =>
                                  onRememberChanged(value ?? false),
                            ),
                            Text(
                              'Se souvenir de moi',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      AuthSubmitButton(
                        loading: loading,
                        onPressed: onLogin,
                        label: 'Log In',
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: loading ? null : onGoogleLogin,
                        icon: const Icon(Icons.login),
                        label: const Text('Continuer avec Google'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const LoginInsightsCard(),
              const SizedBox(height: 32),
              const LoginNavigationLink(),
              const SizedBox(height: 32),
              LoginFooter(onForgetAccount: onForgetAccount),
            ],
          ),
        ),
        LoginSuccessOverlay(visible: successOverlayVisible),
      ],
    );
  }
}
