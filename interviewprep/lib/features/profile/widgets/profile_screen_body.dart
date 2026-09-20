import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import 'profile_form_fields.dart';
import 'profile_status_card.dart';

class ProfileScreenBody extends StatelessWidget {
  const ProfileScreenBody({
    super.key,
    required this.formKey,
    required this.profile,
    required this.avatarUrl,
    required this.isSaving,
    required this.prenomController,
    required this.nomController,
    required this.selectedDomaine,
    required this.selectedNiveau,
    required this.onPickAvatar,
    required this.onDeleteAvatar,
    required this.onDomaineChanged,
    required this.onNiveauChanged,
    required this.onSave,
    required this.onChangePassword,
  });

  final GlobalKey<FormState> formKey;
  final UserProfile profile;
  final String? avatarUrl, selectedDomaine, selectedNiveau;
  final bool isSaving;
  final TextEditingController prenomController, nomController;
  final VoidCallback onPickAvatar, onDeleteAvatar, onSave, onChangePassword;
  final ValueChanged<String?> onDomaineChanged, onNiveauChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
    child: Column(
      children: [
        ProfileFormCard(
          formKey: formKey,
          profile: profile,
          avatarUrl: avatarUrl,
          isSaving: isSaving,
          prenomController: prenomController,
          nomController: nomController,
          selectedDomaine: selectedDomaine,
          selectedNiveau: selectedNiveau,
          onPickAvatar: onPickAvatar,
          onDeleteAvatar: onDeleteAvatar,
          onDomaineChanged: onDomaineChanged,
          onNiveauChanged: onNiveauChanged,
          onSave: onSave,
          onChangePassword: onChangePassword,
        ),
        const SizedBox(height: 32),
        ProfileStatusCard(profile: profile),
        const SizedBox(height: 40),
      ],
    ),
  );
}
