import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/profile_app_bar.dart';
import '../widgets/profile_confirmation.dart';
import '../widgets/profile_feedback.dart';
import '../widgets/profile_screen_body.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _prenomController;
  late final TextEditingController _nomController;
  String? _tempAvatarUrl, _selectedDomaine, _selectedNiveau;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _prenomController = TextEditingController();
    _nomController = TextEditingController();
    final state = ref.read(profileProvider);
    if (state.hasValue) {
      final profile = state.value;
      _prenomController.text = profile?.prenom ?? '';
      _nomController.text = profile?.nom ?? '';
      _tempAvatarUrl = profile?.avatarUrl;
      _selectedDomaine = profile?.domaine;
      _selectedNiveau = profile?.niveau;
    }
  }

  @override
  void dispose() {
    _prenomController.dispose();
    _nomController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() ||
        !await showProfileConfirmation(
          context,
          'Confirmer la mise à jour',
          'Voulez-vous vraiment enregistrer ces modifications de profil ?',
        )) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref
          .read(profileProvider.notifier)
          .updateProfile(
            prenom: _prenomController.text.isEmpty
                ? null
                : _prenomController.text,
            nom: _nomController.text.isEmpty ? null : _nomController.text,
            domaine: _selectedDomaine,
            niveau: _selectedNiveau,
          );
      ref.invalidate(userProfileProvider);
      if (mounted) {
        showProfileMessage(context, 'Profil mis à jour avec succès !');
      }
    } catch (e) {
      if (mounted) showProfileMessage(context, 'Erreur: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
      if (file.size > 5 * 1024 * 1024) {
        if (mounted) {
          showProfileMessage(
            context,
            'Le fichier dépasse la limite de 5 Mo.',
            error: true,
          );
        }
        return;
      }
      if (!mounted) return;
      if (!await showProfileConfirmation(
        context,
        'Confirmer l\'avatar',
        'Voulez-vous vraiment changer votre avatar ?',
      )) {
        return;
      }
      setState(() => _isSaving = true);
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
      ref.invalidate(userProfileProvider);
      if (mounted) {
        showProfileMessage(context, 'Avatar téléversé avec succès !');
      }
    } catch (e) {
      if (mounted) {
        showProfileMessage(
          context,
          'Erreur lors de l\'envoi de l\'avatar: $e',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteAvatar() async {
    if (!await showProfileConfirmation(
      context,
      'Supprimer l\'avatar',
      'Voulez-vous vraiment supprimer votre avatar ?',
    )) {
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(profileProvider.notifier).deleteAvatar();
      ref.invalidate(userProfileProvider);
      if (mounted) {
        showProfileMessage(context, 'Avatar supprimé avec succès !');
      }
    } catch (e) {
      if (mounted) {
        showProfileMessage(
          context,
          'Erreur lors de la suppression de l\'avatar: $e',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const ProfileAppBar(),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Erreur: $error',
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
        data: (profile) {
          _prenomController.text = _prenomController.text.isEmpty
              ? profile.prenom ?? ''
              : _prenomController.text;
          _nomController.text = _nomController.text.isEmpty
              ? profile.nom ?? ''
              : _nomController.text;
          _selectedDomaine ??= profile.domaine;
          _selectedNiveau ??= profile.niveau;
          return ProfileScreenBody(
            formKey: _formKey,
            profile: profile,
            avatarUrl: _tempAvatarUrl ?? profile.avatarUrl,
            isSaving: _isSaving,
            prenomController: _prenomController,
            nomController: _nomController,
            selectedDomaine: _selectedDomaine,
            selectedNiveau: _selectedNiveau,
            onPickAvatar: _pickAndUploadAvatar,
            onDeleteAvatar: _deleteAvatar,
            onDomaineChanged: (value) =>
                setState(() => _selectedDomaine = value),
            onNiveauChanged: (value) => setState(() => _selectedNiveau = value),
            onSave: _saveProfile,
            onChangePassword: () => showChangePasswordDialog(context, ref),
          );
        },
      ),
    );
  }
}
