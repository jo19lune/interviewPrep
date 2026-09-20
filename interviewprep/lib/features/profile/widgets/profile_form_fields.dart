import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../../../core/theme/app_theme.dart';
import 'profile_avatar_section.dart';
import 'profile_field_widgets.dart';

class ProfileFormCard extends StatelessWidget {
  const ProfileFormCard({
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
  Widget build(BuildContext context) {
    final fields = ProfileFieldWidgets(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        border: Border.all(color: AppTheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryContainer.withAlpha((0.04 * 255).round()),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            ProfileAvatarSection(
              avatarUrl: avatarUrl,
              isSaving: isSaving,
              onPick: onPickAvatar,
              onDelete: onDeleteAvatar,
            ),
            const SizedBox(height: 24),
            fields.textField('PRÉNOM', prenomController, 'Votre prénom'),
            const SizedBox(height: 20),
            fields.textField('NOM', nomController, 'Votre nom'),
            const SizedBox(height: 20),
            fields.dropdown(
              'DOMAINE PROFESSIONNEL',
              selectedDomaine,
              Icons.work_outline,
              const [
                DropdownMenuItem(value: 'TECHNIQUE', child: Text('Technique')),
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
                  child: Text('Étude de cas'),
                ),
                DropdownMenuItem(
                  value: 'MOTIVATION',
                  child: Text('Motivation'),
                ),
              ],
              onDomaineChanged,
            ),
            const SizedBox(height: 20),
            fields.dropdown(
              "NIVEAU D'EXPERTISE",
              selectedNiveau,
              Icons.trending_up,
              const [
                DropdownMenuItem(value: 'DEBUTANT', child: Text('Débutant')),
                DropdownMenuItem(
                  value: 'INTERMEDIAIRE',
                  child: Text('Intermédiaire'),
                ),
                DropdownMenuItem(value: 'AVANCE', child: Text('Avancé')),
                DropdownMenuItem(value: 'EXPERT', child: Text('Expert')),
              ],
              onNiveauChanged,
            ),
            const SizedBox(height: 20),
            fields.label('ADRESSE EMAIL (LECTURE SEULE)'),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: profile.courriel,
              readOnly: true,
              style: const TextStyle(color: AppTheme.outline),
              decoration: fields
                  .decoration(Icons.mail_outline)
                  .copyWith(
                    fillColor: AppTheme.surfaceContainerLow,
                    filled: true,
                  ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: isSaving
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
                  isSaving
                      ? 'Enregistrement...'
                      : 'Enregistrer les modifications',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: onChangePassword,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.secondaryColor,
                  side: const BorderSide(color: AppTheme.secondaryColor),
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
    );
  }
}
