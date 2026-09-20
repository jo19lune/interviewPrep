import 'package:flutter/material.dart';
import '../../../core/models/session_detail.dart';
import '../../../core/theme/app_theme.dart';

class FeedbackCard extends StatelessWidget {
  const FeedbackCard({super.key, required this.feedback});

  final SessionDetailFeedback feedback;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            _group(
              'Points forts',
              feedback.pointsForts,
              AppTheme.onTertiaryFixedVariant,
            ),
            _group(
              'Axes d’amélioration',
              feedback.ameliorations,
              AppTheme.error,
            ),
            _group(
              'Recommandations',
              feedback.recommandations,
              AppTheme.secondaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _group(String title, List<dynamic> values, Color color) {
    if (values.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
          for (final value in values)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text(
                '${value is Map ? (value['note']?.toString() ?? value) : value}',
                style: const TextStyle(color: AppTheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class ConversationList extends StatelessWidget {
  const ConversationList({super.key, required this.conversation});

  final SessionConversation conversation;

  @override
  Widget build(BuildContext context) {
    if (conversation.userResponses.isEmpty) {
      return const Text(
        'Aucune réponse enregistrée pour cette session.',
        style: TextStyle(color: AppTheme.onSurfaceVariant),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Questions & Réponses',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < conversation.userResponses.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: QuestionAnswerCard(
              response: conversation.userResponses[index],
              index: index + 1,
            ),
          ),
      ],
    );
  }
}

class QuestionAnswerCard extends StatelessWidget {
  const QuestionAnswerCard({
    super.key,
    required this.response,
    required this.index,
  });

  final dynamic response;
  final int index;

  @override
  Widget build(BuildContext context) {
    final question = response is Map
        ? response['question'] as String? ?? ''
        : '';
    final text = response is Map ? response['texte'] as String? ?? '' : '';
    final score = response is Map
        ? (response['score_partiel'] as num?)?.toDouble()
        : null;
    final sentiment = response is Map ? response['sentiment'] as String? : null;
    final tip = response is Map ? response['coaching_tip'] as String? : null;
    return Card(
      color: AppTheme.surfaceContainerLowest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Q$index',
                  style: const TextStyle(color: AppTheme.secondaryColor),
                ),
                const Spacer(),
                if (score != null) Text('${score.round()}/100'),
              ],
            ),
            if (question.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                question,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 8),
            Text(text.isNotEmpty ? text : '(réponse vocale)'),
            if (sentiment != null || (tip?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  [
                    if (sentiment != null) 'Sentiment: $sentiment',
                    if (tip?.isNotEmpty ?? false) tip!,
                  ].join('\n'),
                  style: const TextStyle(color: AppTheme.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
