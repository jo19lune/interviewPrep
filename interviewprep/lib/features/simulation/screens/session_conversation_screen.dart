import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import 'session_conversation_feedback_widgets.dart';
import 'session_conversation_widgets.dart';

class SessionConversationScreen extends ConsumerWidget {
  const SessionConversationScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = ref.watch(sessionConversationProvider(sessionId));
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        title: const Text(
          'Conversation',
          style: TextStyle(
            color: AppTheme.primaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryContainer),
          onPressed: () => context.pop(),
        ),
      ),
      body: conversation.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Erreur: $error',
            style: const TextStyle(color: AppTheme.error),
          ),
        ),
        data: (value) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SessionHeaderCard(conversation: value),
              if (value.feedback != null) ...[
                const SizedBox(height: 20),
                FeedbackCard(feedback: value.feedback!),
              ],
              const SizedBox(height: 20),
              ConversationList(conversation: value),
            ],
          ),
        ),
      ),
    );
  }
}
