import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/app_dialog.dart';
import '../providers/auth_provider.dart';
import 'reset_password_form.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, this.email = ''});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
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
    _email ??= widget.email.isNotEmpty
        ? widget.email
        : (ModalRoute.of(context)?.settings.arguments as String?);
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
      await AppDialog.warning(
        context,
        title: 'Email manquant',
        message: 'Retournez à l’étape précédente pour saisir votre email.',
      );
      return;
    }
    setState(() => _submitted = true);
    try {
      final notifier = ref.read(forgotPasswordProvider.notifier);
      final valid = await notifier.verifyCode(
        email,
        _codeController.text.trim(),
      );
      if (!mounted) return;
      if (!valid) {
        await AppDialog.error(
          context,
          title: 'Code invalide',
          message: 'Le code est invalide ou expiré. Demandez un nouveau code.',
        );
        return;
      }
      await notifier.resetPassword(
        email,
        _codeController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        await AppDialog.success(
          context,
          title: 'Mot de passe réinitialisé',
          message: 'Vous pouvez maintenant vous connecter.',
        );
        if (mounted) context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        await AppDialog.showException(
          context,
          e,
          fallback: 'Erreur lors de la réinitialisation',
        );
      }
    } finally {
      if (mounted) setState(() => _submitted = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        _submitted || ref.watch(forgotPasswordProvider) is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: const Text('Nouveau mot de passe'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: ResetPasswordForm(
                formKey: _formKey,
                codeController: _codeController,
                passwordController: _passwordController,
                confirmController: _confirmController,
                isLoading: isLoading,
                obscurePassword: _obscurePassword,
                onToggleObscure: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                onSubmit: _submit,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
