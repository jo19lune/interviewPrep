import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/bottom_navigation.dart';
import '../providers/qa_module_provider.dart';
import '../widgets/qa_message_list.dart';
import '../widgets/qa_input_field.dart';
import '../widgets/qa_module_container.dart';

class StandaloneQAScreen extends ConsumerWidget {
  const StandaloneQAScreen({super.key, this.exerciseId, this.exerciseTitle, this.domaine, this.difficulte});

  final String? exerciseId;
  final String? exerciseTitle;
  final String? domaine;
  final String? difficulte;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qaState = ref.watch(qaModuleProvider);

    if (exerciseId != null && qaState.exerciseId != exerciseId) {
      ref.read(qaModuleProvider.notifier).configure(
        exerciseId: exerciseId!,
        exerciseTitle: exerciseTitle ?? 'Exercice',
        domaine: domaine,
        difficulte: difficulte,
        subject: qaState.subject,
        totalQuestions: qaState.totalQuestions,
      );
    }

    final messages = qaState.messages;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        title: const Text('Module Q&A', style: TextStyle(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryContainer),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Exercice de questions-réponses autonome',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: QaModuleContainer(
              title: 'Session Q&A',
              child: Column(
                children: [
                  Expanded(
                    child: QaMessageList(messages: messages),
                  ),
                  const SizedBox(height: 12),
                  if (messages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => ref.read(qaModuleProvider.notifier).endSession(),
                              icon: const Icon(Icons.stop_circle_outlined),
                              label: const Text('Terminer la session'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  const QaInputField(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNavigation(),
    );
  }
}
