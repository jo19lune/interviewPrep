import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/auth_models.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/profile_provider.dart';

Future<void> showChangePasswordDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final oldController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var saving = false;

  await showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainerLowest,
        title: const Text(
          'Modifier le mot de passe',
          style: TextStyle(
            color: AppTheme.primaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _passwordField(oldController, 'Mot de passe actuel'),
                const SizedBox(height: 16),
                _passwordField(
                  newController,
                  'Nouveau mot de passe',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ce champ est requis';
                    }
                    if (value.length < 6) {
                      return 'Le mot de passe doit faire au moins 6 caractères';
                    }
                    if (value == oldController.text) {
                      return 'Le nouveau mot de passe doit être différent';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _passwordField(
                  confirmController,
                  'Confirmer le nouveau mot de passe',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ce champ est requis';
                    }
                    return value == newController.text
                        ? null
                        : 'Les mots de passe ne correspondent pas';
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: saving
                ? null
                : () async {
                    if (!formKey.currentState!.validate()) return;
                    final confirmed =
                        await showDialog<bool>(
                          context: dialogContext,
                          builder: (confirmContext) => AlertDialog(
                            backgroundColor: AppTheme.surfaceContainerLowest,
                            title: const Text(
                              'Confirmer le mot de passe',
                              style: TextStyle(
                                color: AppTheme.primaryContainer,
                              ),
                            ),
                            content: const Text(
                              'Voulez-vous vraiment modifier votre mot de passe ?',
                              style: TextStyle(color: AppTheme.onSurface),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(confirmContext, false),
                                child: const Text('Annuler'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(confirmContext, true),
                                child: const Text('Confirmer'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (!confirmed) return;
                    setState(() => saving = true);
                    try {
                      await ref
                          .read(profileServiceProvider)
                          .changePassword(
                            ChangePasswordRequest(
                              motDePasseActuel: oldController.text,
                              nouveauMotDePasse: newController.text,
                            ),
                          );
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Mot de passe mis à jour avec succès !',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: $e'),
                            backgroundColor: AppTheme.error,
                          ),
                        );
                      }
                    } finally {
                      setState(() => saving = false);
                    }
                  },
            child: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Valider'),
          ),
        ],
      ),
    ),
  );
  oldController.dispose();
  newController.dispose();
  confirmController.dispose();
}

TextFormField _passwordField(
  TextEditingController controller,
  String label, {
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    obscureText: true,
    style: const TextStyle(color: AppTheme.onSurface),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline),
    ),
    validator:
        validator ??
        (value) => value == null || value.trim().isEmpty
            ? 'Ce champ est requis'
            : null,
  );
}
