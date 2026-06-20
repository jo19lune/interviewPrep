import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _prenomController;
  late TextEditingController _nomController;
  String? _tempAvatarUrl;
  String? _selectedDomaine;
  String? _selectedNiveau;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _prenomController = TextEditingController();
    _nomController = TextEditingController();

    // Initialise avec les données si déjà chargées
    final profileState = ref.read(profileProvider);
    if (profileState.hasValue) {
      _prenomController.text = profileState.value?.prenom ?? '';
      _nomController.text = profileState.value?.nom ?? '';
      _tempAvatarUrl = profileState.value?.avatarUrl;
      _selectedDomaine = profileState.value?.domaine;
      _selectedNiveau = profileState.value?.niveau;
    }
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(profileProvider.notifier)
          .updateProfile(
            prenom: _prenomController.text.isNotEmpty
                ? _prenomController.text
                : null,
            nom: _nomController.text.isNotEmpty ? _nomController.text : null,
            domaine: _selectedDomaine,
            niveau: _selectedNiveau,
          );

      // Invalider le fournisseur du tableau de bord pour synchroniser les initiales
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      // Valider la taille (max 5MB)
      if (file.size > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Le fichier dépasse la limite de 5 Mo.'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
        return;
      }

      setState(() {
        _isSaving = true;
      });

      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception('Impossible de lire le fichier.');
        }
        await ref
            .read(profileProvider.notifier)
            .uploadAvatar(bytes: file.bytes, filename: file.name);
      } else {
        if (file.path == null) {
          throw Exception('Impossible d\'accéder au chemin du fichier.');
        }
        await ref
            .read(profileProvider.notifier)
            .uploadAvatar(path: file.path, filename: file.name);
      }

      // Invalider pour rafraîchir l'en-tête du tableau de bord
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar téléversé avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi de l\'avatar: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final dialogFormKey = GlobalKey<FormState>();
    bool isSavingPassword = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceContainerLowest,
              title: const Text(
                'Modifier le mot de passe',
                style: TextStyle(
                  color: AppTheme.primaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Form(
                key: dialogFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: oldPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: AppTheme.onSurface),
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe actuel',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ce champ est requis';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: AppTheme.onSurface),
                        decoration: const InputDecoration(
                          labelText: 'Nouveau mot de passe',
                          prefixIcon: Icon(Icons.lock_reset),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ce champ est requis';
                          }
                          if (val.length < 6) {
                            return 'Le mot de passe doit faire au moins 6 caract\u00e8res';
                          }
                          if (val == oldPasswordController.text) {
                            return 'Le nouveau mot de passe doit \u00eatre diff\u00e9rent';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        style: const TextStyle(color: AppTheme.onSurface),
                        decoration: const InputDecoration(
                          labelText: 'Confirmer le nouveau mot de passe',
                          prefixIcon: Icon(Icons.lock_clock),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Ce champ est requis';
                          }
                          if (val != newPasswordController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSavingPassword
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: isSavingPassword
                      ? null
                      : () async {
                          if (!dialogFormKey.currentState!.validate()) return;

                          setState(() {
                            isSavingPassword = true;
                          });

                          try {
                            final profileService = ref.read(
                              profileServiceProvider,
                            );
                            await profileService.changePassword(
                              oldPasswordController.text,
                              newPasswordController.text,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Mot de passe mis \u00e0 jour avec succ\u00e8s !',
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
                            setState(() {
                              isSavingPassword = false;
                            });
                          }
                        },
                  child: isSavingPassword
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        shadowColor: Colors.black.withAlpha((0.05 * 255).round()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryContainer),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Mon Profil',
          style: TextStyle(
            color: AppTheme.primaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await ref.read(authStateProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout, color: AppTheme.error, size: 18),
            label: const Text(
              'Déconnexion',
              style: TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Erreur: $err',
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
        data: (profile) {
          // Synchroniser les contrôleurs s'ils sont vides mais que le profil a des données
          if (_prenomController.text.isEmpty && profile.prenom != null) {
            _prenomController.text = profile.prenom!;
          }
          if (_nomController.text.isEmpty && profile.nom != null) {
            _nomController.text = profile.nom!;
          }
          _selectedDomaine ??= profile.domaine;
          _selectedNiveau ??= profile.niveau;

          final avatarUrl = _tempAvatarUrl ?? profile.avatarUrl;
          final bool isVerified = profile.estActif;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Carte du Formulaire
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    border: Border.all(color: AppTheme.outlineVariant),
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryContainer.withAlpha(
                          (0.04 * 255).round(),
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar avec modification cliquable
                        GestureDetector(
                          onTap: _pickAndUploadAvatar,
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 52,
                                backgroundColor: AppTheme.surfaceContainerLow,
                                backgroundImage: avatarUrl != null
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 52,
                                        color: AppTheme.primaryContainer,
                                      )
                                    : null,
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppTheme.secondaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Champ Prénom
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRÉNOM',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _prenomController,
                              style: const TextStyle(color: AppTheme.onSurface),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline),
                                hintText: 'Votre prénom',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Champ Nom
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NOM',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nomController,
                              style: const TextStyle(color: AppTheme.onSurface),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline),
                                hintText: 'Votre nom',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Domaine professionnel Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DOMAINE PROFESSIONNEL',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedDomaine,
                              style: const TextStyle(color: AppTheme.onSurface),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.work_outline),
                              ),
                              dropdownColor: AppTheme.surfaceContainerLowest,
                              items: const [
                                DropdownMenuItem(
                                  value: 'TECHNIQUE',
                                  child: Text('Technique'),
                                ),
                                DropdownMenuItem(
                                  value: 'COMPORTEMENTAL',
                                  child: Text('Comportemental'),
                                ),
                                DropdownMenuItem(
                                  value: 'SITUATIONNEL',
                                  child: Text('Situationnel'),
                                ),
                                DropdownMenuItem(
                                  value: 'ETUDE_DE_CAS',
                                  child: Text('\u00c9tude de cas'),
                                ),
                                DropdownMenuItem(
                                  value: 'MOTIVATION',
                                  child: Text('Motivation'),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _selectedDomaine = val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Niveau d'expertise Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NIVEAU D\'EXPERTISE',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 12,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedNiveau,
                              style: const TextStyle(color: AppTheme.onSurface),
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.trending_up),
                              ),
                              dropdownColor: AppTheme.surfaceContainerLowest,
                              items: const [
                                DropdownMenuItem(
                                  value: 'DEBUTANT',
                                  child: Text('D\u00e9butant'),
                                ),
                                DropdownMenuItem(
                                  value: 'INTERMEDIAIRE',
                                  child: Text('Interm\u00e9diaire'),
                                ),
                                DropdownMenuItem(
                                  value: 'AVANCE',
                                  child: Text('Avanc\u00e9'),
                                ),
                                DropdownMenuItem(
                                  value: 'EXPERT',
                                  child: Text('Expert'),
                                ),
                              ],
                              onChanged: (val) =>
                                  setState(() => _selectedNiveau = val),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Champ Email (Lecture Seule)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ADRESSE EMAIL (LECTURE SEULE)',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: AppTheme.outline,
                                    fontSize: 11,
                                    letterSpacing: 1.1,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              initialValue: profile.courriel,
                              readOnly: true,
                              style: const TextStyle(color: AppTheme.outline),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.mail_outline,
                                  color: AppTheme.outline,
                                ),
                                fillColor: AppTheme.surfaceContainerLow,
                                filled: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Bouton d'enregistrement
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save, size: 18),
                            label: Text(
                              _isSaving
                                  ? 'Enregistrement...'
                                  : 'Enregistrer les modifications',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _showChangePasswordDialog,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.secondaryColor,
                              side: const BorderSide(
                                color: AppTheme.secondaryColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.lock_open, size: 18),
                            label: const Text(
                              'Modifier le mot de passe',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Statut de Vérification
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLowest,
                    border: Border.all(color: AppTheme.outlineVariant),
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? AppTheme.tertiaryFixed.withValues(alpha: 0.2)
                              : AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isVerified
                              ? Icons.check_circle
                              : Icons.warning_amber_rounded,
                          color: isVerified
                              ? AppTheme.onTertiaryFixedVariant
                              : AppTheme.error,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isVerified
                                  ? 'Votre compte est actif'
                                  : 'Vérification du compte en attente',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.primaryContainer,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isVerified
                                  ? 'Vos informations personnelles sont stockées en toute sécurité.'
                                  : 'Veuillez vérifier votre adresse e-mail pour accéder à toutes les fonctionnalités.',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.onSurfaceVariant,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
