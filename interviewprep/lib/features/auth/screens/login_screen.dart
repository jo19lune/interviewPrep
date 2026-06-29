import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isSuccessOverlayVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authStateProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
        );
        if (mounted) {
          setState(() {
            _isSuccessOverlayVisible = true;
          });
          // Petit délai pour afficher le spinner fluide de succès
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) context.go('/dashboard');
        }
      } catch (e) {
        if (mounted) {
          final msg = e.toString().replaceAll('Exception: ', '').trim();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg.isNotEmpty ? msg : 'Erreur de connexion')),
          );
        }
      }
    }
  }

  void _showForgetDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer votre compte ?'),
        content: const Text(
          'Connectez-vous avec le compte a supprimer, puis confirmez l effacement definitif de vos donnees.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Renseignez email et mot de passe avant la suppression.')),
                );
                return;
              }
              try {
                await ref.read(authStateProvider.notifier).login(
                      _emailController.text,
                      _passwordController.text,
                    );
                await ref.read(authStateProvider.notifier).deleteAccount();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Compte et donnees supprimes.')),
                  );
                  context.go('/login');
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                  );
                }
              }
            },
            child: const Text('Supprimer', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.terminal, color: AppTheme.primaryContainer, size: 28),
            const SizedBox(width: 8),
            Text(
              'InterviewPrep',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.primaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Header
                  Text(
                    'Welcome back',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: AppTheme.primaryContainer,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your career breakthrough starts here.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Auth Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryContainer.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email Field
                          Text('Email Address', style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              hintText: 'name@company.com',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) => value!.isEmpty ? 'Veuillez entrer votre email' : null,
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Password', style: Theme.of(context).textTheme.labelLarge),
                              TextButton(
                                onPressed: () => context.go('/forgot-password'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text('Forgot password?', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.secondaryColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: AppTheme.outline,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            validator: (value) => value!.isEmpty ? 'Veuillez entrer votre mot de passe' : null,
                          ),
                          const SizedBox(height: 24),

                          // Submit Button + Loading + (social logins supprimés)
                          Consumer(
                            builder: (context, ref, _) {
                              final authState = ref.watch(authStateProvider);
                              final isLoading = authState is AsyncLoading<void>;

                              return Column(
                                children: [
                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _login,
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const Text('Log In'),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // AI Coaching Teaser Card
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryContainer, AppTheme.secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'AI INSIGHTS',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.2,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Master your next interview.',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join 50k+ professionals using our proprietary AI simulation engine to land top-tier roles.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                            ),
                          ],
                        ),
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Icon(
                            Icons.psychology,
                            size: 100,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant)),
                      TextButton(
                        onPressed: () => context.go('/register'),
                        child: Text('Create Account', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.secondaryColor)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Footer
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.gpp_maybe_outlined, color: AppTheme.outline, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'We value your privacy. InterviewPrep is fully GDPR compliant and uses enterprise-grade encryption.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  backgroundColor: AppTheme.surfaceContainerLowest,
                                  title: const Text('Politique de confidentialité'),
                                  content: const Text(
                                    'InterviewPrep respecte votre vie privée. Vos données d\'entraînement sont sécurisées et traitées conformément au RGPD pour vous fournir des analyses de performance de qualité. Vous pouvez à tout moment exercer votre droit à l\'oubli.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(dialogCtx),
                                      child: const Text('Fermer'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text('Privacy Policy', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.secondaryColor)),
                          ),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            onPressed: () => _showForgetDialog(),
                            icon: const Icon(Icons.delete_forever, size: 14, color: AppTheme.error),
                            label: Text('Right to be forgotten', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.error)),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Overlay de chargement
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _isSuccessOverlayVisible
              ? Container(
                  key: const ValueKey('success_overlay'),
                  color: Colors.white.withAlpha((0.9 * 255).round()),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.secondaryColor),
                        const SizedBox(height: 16),
                        Text(
                          'Connexion réussie...',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.primaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('empty')),
        ),
      ],
    ),
  ),
);
}
}
