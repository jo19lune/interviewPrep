import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/utils/app_dialog.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_additional_providers.dart';
import '../widgets/login_content.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  bool _obscurePassword = true;
  bool _isSuccessOverlayVisible = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('remember_me') ?? false) {
      final email = await _storage.read(key: 'remembered_email');
      final password = await _storage.read(key: 'remembered_password');
      if (email != null && password != null && mounted) {
        setState(() {
          _emailController.text = email;
          _passwordController.text = password;
          _rememberMe = true;
        });
      }
    }
  }

  Future<void> _saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', _rememberMe);
    if (_rememberMe) {
      await _storage.write(
        key: 'remembered_email',
        value: _emailController.text,
      );
      await _storage.write(
        key: 'remembered_password',
        value: _passwordController.text,
      );
    } else {
      await _storage.delete(key: 'remembered_email');
      await _storage.delete(key: 'remembered_password');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await _saveRememberMe();
      final result = await ref
          .read(authStateProvider.notifier)
          .login(_emailController.text, _passwordController.text);
      if (!mounted) return;
      if (result.requiresTwoFactor) {
        context.go(
          '/verify-otp',
          extra: <String, dynamic>{
            'email': _emailController.text.trim(),
            'expiresInSeconds': result.challengeExpiresInSeconds,
          },
        );
        return;
      }
      setState(() => _isSuccessOverlayVisible = true);
      await Future<void>.delayed(const Duration(milliseconds: 800));
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        await AppDialog.showException(
          context,
          e,
          fallback: 'Erreur de connexion',
        );
      }
    }
  }

  Future<void> _googleLogin() async {
    try {
      await ref.read(googleAuthProvider.notifier).login();
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        await AppDialog.showException(
          context,
          e,
          fallback: 'Erreur de connexion avec Google',
        );
      }
    }
  }

  Future<void> _showForgetDialog() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Supprimer votre compte ?',
      message:
          'Cette action supprimera définitivement votre compte et vos données.',
      confirmText: 'Supprimer',
      confirmColor: AppTheme.error,
    );
    if (!confirmed || !mounted) return;

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      await AppDialog.warning(
        context,
        title: 'Informations manquantes',
        message:
            'Renseignez votre email et votre mot de passe avant la suppression.',
      );
      return;
    }
    try {
      await ref
          .read(authStateProvider.notifier)
          .login(_emailController.text, _passwordController.text);
      await ref.read(authStateProvider.notifier).deleteAccount();
      if (mounted) {
        await AppDialog.success(
          context,
          title: 'Compte supprimé',
          message: 'Votre compte et vos données ont été supprimés.',
        );
        if (mounted) context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        await AppDialog.showException(
          context,
          e,
          fallback: 'Impossible de supprimer le compte',
        );
      }
    }
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
      body: LoginContent(
        formKey: _formKey,
        emailController: _emailController,
        passwordController: _passwordController,
        obscurePassword: _obscurePassword,
        rememberMe: _rememberMe,
        successOverlayVisible: _isSuccessOverlayVisible,
        onTogglePassword: () =>
            setState(() => _obscurePassword = !_obscurePassword),
        onRememberChanged: (value) => setState(() => _rememberMe = value),
        onLogin: _login,
        onGoogleLogin: _googleLogin,
        onForgetAccount: _showForgetDialog,
      ),
    );
  }
}
