import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../core/utils/app_dialog.dart';
import '../providers/auth_additional_providers.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  const OtpVerificationScreen({
    required this.email,
    this.expiresInSeconds,
    super.key,
  });

  final String email;
  final int? expiresInSeconds;

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    try {
      await ref
          .read(otpVerificationProvider.notifier)
          .verify(widget.email, _controller.text);
      if (mounted) context.go('/dashboard');
    } catch (error) {
      if (!mounted) return;
      await AppDialog.showException(
        context,
        error,
        fallback: 'Le code de vérification est invalide ou expiré',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(otpVerificationProvider) is AsyncLoading<void>;
    return Scaffold(
      appBar: AppBar(title: const Text('Vérification en deux étapes')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_outlined, size: 56),
                const SizedBox(height: 16),
                Text(
                  'Saisissez le code envoyé à ${widget.email}.',
                  textAlign: TextAlign.center,
                ),
                if (widget.expiresInSeconds != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Le code expire dans ${widget.expiresInSeconds} secondes.',
                  ),
                ],
                const SizedBox(height: 24),
                Pinput(
                  controller: _controller,
                  length: 6,
                  keyboardType: TextInputType.number,
                  validator: (value) => value == null || value.length != 6
                      ? 'Entrez les 6 chiffres'
                      : null,
                  onCompleted: (_) => _verify(),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: loading ? null : _verify,
                  child: loading
                      ? const CircularProgressIndicator()
                      : const Text('Vérifier'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
