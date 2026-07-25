import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/session_detail.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class SessionConversationScreen extends ConsumerWidget {
  final String sessionId;
  const SessionConversationScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationAsync = ref.watch(sessionConversationProvider(sessionId));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        title: const Text('Conversation', style: TextStyle(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryContainer),
          onPressed: () => context.pop(),
        ),
      ),
      body: conversationAsync.when(
        data: (conv) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSessionHeader(context, conv),
                const SizedBox(height: 20),
                if (conv.feedback != null) _buildFeedbackSection(context, conv.feedback!),
                if (conv.feedback != null) const SizedBox(height: 20),
                _buildConversation(context, conv),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e', style: const TextStyle(color: AppTheme.error))),
      ),
    );
  }

  Widget _buildSessionHeader(BuildContext context, SessionConversation conv) {
    final session = conv.session;
    final titre = conv.exerciseTitle ?? 'Session #${session.id.substring(0, 8)}';
    final domaine = conv.exerciseDomaine ?? '';
    final score = session.score ?? 0.0;
    final date = session.commenceLe != null
        ? '${session.commenceLe!.day}/${session.commenceLe!.month}/${session.commenceLe!.year}'
        : '';

    return Card(
      color: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titre, style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.primaryContainer, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (domaine.isNotEmpty)
              Text('Domaine: $domaine', style: const TextStyle(color: AppTheme.onSurfaceVariant)),
            Text('Date: $date', style: const TextStyle(color: AppTheme.onSurfaceVariant)),
            if (session.statut == 'TERMINEE') ...[
              const SizedBox(height: 8),
              Text('Score: ${score.round()}/100',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: score >= 70 ? AppTheme.onTertiaryFixedVariant : score < 50 ? AppTheme.error : AppTheme.secondaryColor)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackSection(BuildContext context, SessionDetailFeedback feedback) {
    return Card(
      color: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Feedback', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryContainer, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (feedback.pointsForts.isNotEmpty) ...[
              Text('Points forts', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.onTertiaryFixedVariant)),
              const SizedBox(height: 4),
              for (final pf in feedback.pointsForts)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('• ', style: TextStyle(color: AppTheme.onTertiaryFixedVariant)),
                    Expanded(child: Text(
                      pf is Map ? (pf['note']?.toString() ?? pf.toString()) : pf.toString(),
                      style: const TextStyle(color: AppTheme.onSurfaceVariant),
                    )),
                  ]),
                ),
              const SizedBox(height: 8),
            ],
            if (feedback.ameliorations.isNotEmpty) ...[
              Text('Axes d\'amélioration', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.error)),
              const SizedBox(height: 4),
              for (final am in feedback.ameliorations)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('• ', style: TextStyle(color: AppTheme.error)),
                    Expanded(child: Text(
                      am is Map ? (am['note']?.toString() ?? am.toString()) : am.toString(),
                      style: const TextStyle(color: AppTheme.onSurfaceVariant),
                    )),
                  ]),
                ),
              const SizedBox(height: 8),
            ],
            if (feedback.recommandations.isNotEmpty) ...[
              Text('Recommandations', style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.secondaryColor)),
              const SizedBox(height: 4),
              for (final rec in feedback.recommandations)
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('→ ', style: TextStyle(color: AppTheme.secondaryColor)),
                    Expanded(child: Text(rec.toString(), style: const TextStyle(color: AppTheme.onSurfaceVariant))),
                  ]),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConversation(BuildContext context, SessionConversation conv) {
    final responses = conv.userResponses;
    if (responses.isEmpty) {
      return const Center(child: Text('Aucune réponse enregistrée pour cette session.',
        style: TextStyle(color: AppTheme.onSurfaceVariant)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Questions & Réponses', style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.primaryContainer, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        for (int i = 0; i < responses.length; i++) ...[
          _buildQACard(context, responses[i], i + 1),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildQACard(BuildContext context, dynamic response, int index) {
    final question = response is Map ? (response['question'] as String? ?? '') : '';
    final texte = response is Map ? (response['texte'] as String? ?? '') : '';
    final score = response is Map ? (response['score_partiel'] as num?)?.toDouble() : null;
    final sentiment = response is Map ? (response['sentiment'] as String?) : null;
    final coachingTip = response is Map ? (response['coaching_tip'] as String?) : null;

    return Card(
      color: AppTheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Q$index', style: const TextStyle(
                  fontSize: 11, color: AppTheme.secondaryColor, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              if (score != null)
                Text('${score.round()}/100',
                  style: TextStyle(fontWeight: FontWeight.bold,
                    color: score >= 70 ? AppTheme.onTertiaryFixedVariant : score < 50 ? AppTheme.error : AppTheme.secondaryColor)),
            ]),
            const SizedBox(height: 8),
            if (question.isNotEmpty) ...[
              Text(question, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryContainer)),
              const SizedBox(height: 8),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(texte.isNotEmpty ? texte : '(réponse vocale)',
                style: const TextStyle(color: AppTheme.onSurface)),
            ),
            if (sentiment != null || (coachingTip != null && coachingTip.isNotEmpty)) ...[
              const SizedBox(height: 8),
              if (sentiment != null)
                Row(children: [
                  Icon(Icons.face, size: 14, color: AppTheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text('Sentiment: $sentiment', style: const TextStyle(fontSize: 12, color: AppTheme.onSurfaceVariant)),
                ]),
              if (coachingTip != null && coachingTip.isNotEmpty)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.lightbulb_outline, size: 14, color: AppTheme.secondaryColor),
                  const SizedBox(width: 4),
                  Expanded(child: Text(coachingTip, style: const TextStyle(fontSize: 12, color: AppTheme.secondaryColor))),
                ]),
            ],
          ],
        ),
      ),
    );
  }
}
