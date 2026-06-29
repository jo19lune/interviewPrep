import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, this.email = ''});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitted = false;
  String? _email;
  bool _obscurePassword = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _email ??= widget.email.isNotEmpty ? widget.email : (ModalRoute.of(context)?.settings.arguments as String?);
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _email ?? '';
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email manquant. Retournez à l\'étape précédente.')),
      );
      return;
    }
    setState(() => _submitted = true);
    try {
      final notifier = ref.read(forgotPasswordProvider.notifier);
      final valid = await notifier.verifyCode(email, _codeController.text.trim());
      if (!mounted) return;
      if (!valid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code invalide ou expiré. Demandez un nouveau code.')),
        );
        return;
      }
      await notifier.resetPassword(
        email,
        _codeController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe réinitialisé. Connectez-vous.')),
        );
        if (mounted) context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg.isNotEmpty ? msg : 'Erreur lors de la réinitialisation')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitted = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _submitted || ref.watch(forgotPasswordProvider) is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text('Nouveau mot de passe'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
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
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Code de vérification',
                        hintText: '123456',
                        prefixIcon: Icon(Icons.numbers),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      enabled: !isLoading,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Veuillez entrer le code';
                        if (v.length != 6) return 'Le code doit contenir 6 chiffres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Nouveau mot de passe',
                        hintText: 'Minimum 8 caractères',
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
                      enabled: !isLoading,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Veuillez entrer un mot de passe';
                        if (v.length < 8) return 'Minimum 8 caractères requis';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmController,
                      decoration: InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        hintText: 'Retapez le mot de passe',
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
                      enabled: !isLoading,
                      validator: (v) {
                        if (v != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Réinitialiser le mot de passe'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: isLoading ? null : () => context.go('/forgot-password'),
                      child: const Text('Renvoyer un code'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: isLoading ? null : () => context.go('/login'),
                      child: const Text('Retour à la connexion'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
