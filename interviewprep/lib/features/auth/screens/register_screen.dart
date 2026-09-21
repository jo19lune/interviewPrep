import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/register_content.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptCGU = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_acceptCGU) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez accepter les CGU et la Politique de confidentialité',
          ),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref
          .read(authStateProvider.notifier)
          .register(
            _nameController.text,
            _emailController.text,
            _passwordController.text,
          );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll('Exception: ', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.isNotEmpty ? msg : 'Erreur d\'inscription'),
          ),
        );
      }
    }
  }

  void _showLegalDocument(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
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
        title: Text(
          'InterviewPrep',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: AppTheme.primaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RegisterContent(
        formKey: _formKey,
        nameController: _nameController,
        emailController: _emailController,
        passwordController: _passwordController,
        confirmPasswordController: _confirmPasswordController,
        obscurePassword: _obscurePassword,
        obscureConfirmPassword: _obscureConfirmPassword,
        acceptCGU: _acceptCGU,
        onTogglePassword: () =>
            setState(() => _obscurePassword = !_obscurePassword),
        onToggleConfirmPassword: () =>
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        onAcceptChanged: (value) => setState(() => _acceptCGU = value),
        onShowLegalDocument: _showLegalDocument,
        onRegister: _register,
      ),
    );
  }
}
