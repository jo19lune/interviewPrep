import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_confirmation.dart';
import '../widgets/profile_feedback.dart';

const int _maxAvatarBytes = 5 * 1024 * 1024;

/// Sélectionne, confirme puis envoie un nouvel avatar. [onSavingChanged] reflète
/// l'état de chargement de l'écran et le profil est invalidé après l'envoi.
Future<void> pickAndUploadAvatar(
  BuildContext context,
  WidgetRef ref, {
  required ValueChanged<bool> onSavingChanged,
}) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.size > _maxAvatarBytes) {
      if (context.mounted) {
        showProfileMessage(
          context,
          'Le fichier dépasse la limite de 5 Mo.',
          error: true,
        );
      }
      return;
    }
    if (!context.mounted) return;
    if (!await showProfileConfirmation(
      context,
      'Confirmer l\'avatar',
      'Voulez-vous vraiment changer votre avatar ?',
    )) {
      return;
    }
    onSavingChanged(true);
    final notifier = ref.read(profileProvider.notifier);
    if (kIsWeb) {
      if (file.bytes == null) {
        throw Exception('Impossible de lire le fichier.');
      }
      await notifier.uploadAvatar(bytes: file.bytes, filename: file.name);
    } else {
      if (file.path == null) {
        throw Exception('Impossible d\'accéder au chemin du fichier.');
      }
      await notifier.uploadAvatar(path: file.path, filename: file.name);
    }
    ref.invalidate(userProfileProvider);
    if (context.mounted) {
      showProfileMessage(context, 'Avatar téléversé avec succès !');
    }
  } catch (e) {
    if (context.mounted) {
      showProfileMessage(
        context,
        'Erreur lors de l\'envoi de l\'avatar: $e',
        error: true,
      );
    }
  } finally {
    if (context.mounted) onSavingChanged(false);
  }
}

/// Supprime l'avatar après confirmation, puis invalide le profil.
Future<void> deleteAvatar(
  BuildContext context,
  WidgetRef ref, {
  required ValueChanged<bool> onSavingChanged,
}) async {
  if (!await showProfileConfirmation(
    context,
    'Supprimer l\'avatar',
    'Voulez-vous vraiment supprimer votre avatar ?',
  )) {
    return;
  }
  onSavingChanged(true);
  try {
    await ref.read(profileProvider.notifier).deleteAvatar();
    ref.invalidate(userProfileProvider);
    if (context.mounted) {
      showProfileMessage(context, 'Avatar supprimé avec succès !');
    }
  } catch (e) {
    if (context.mounted) {
      showProfileMessage(
        context,
        'Erreur lors de la suppression de l\'avatar: $e',
        error: true,
      );
    }
  } finally {
    if (context.mounted) onSavingChanged(false);
  }
}
