import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../services/qa_service.dart';
import 'standalone_qa_score.dart';

class StandaloneQAFeedback extends StatelessWidget {
  const StandaloneQAFeedback({
    super.key,
    required this.feedback,
    required this.onRestart,
    required this.onDashboard,
  });
  final QAFeedback feedback;
  final VoidCallback onRestart, onDashboard;

  Widget _title(
    BuildContext context,
    IconData icon,
    String text,
    Color color,
  ) => Row(
    children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 8),
      Text(
        text,
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          color: AppTheme.primaryContainer,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Widget _card(String title, String description, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLowest,
      border: Border(left: BorderSide(color: color, width: 4)),
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(8),
        bottomRight: Radius.circular(8),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryContainer,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _recommendations() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.surfaceContainerLowest,
      border: Border.all(color: AppTheme.outlineVariant),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: feedback.recommandations
          .map(
            (rec) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.star,
                    color: AppTheme.secondaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      rec,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StandaloneQAScore(feedback: feedback),
          const SizedBox(height: 28),
          if (feedback.pointsForts.isNotEmpty) ...[
            _title(context, Icons.check_circle, 'Points Forts', Colors.green),
            const SizedBox(height: 12),
            ...feedback.pointsForts.map(
              (item) => _card(item.domaine, item.note, Colors.green),
            ),
            const SizedBox(height: 24),
          ],
          if (feedback.ameliorations.isNotEmpty) ...[
            _title(
              context,
              Icons.trending_up,
              "Axes d'Amélioration",
              Colors.orange,
            ),
            const SizedBox(height: 12),
            ...feedback.ameliorations.map(
              (item) => _card(item.domaine, item.note, Colors.orange),
            ),
            const SizedBox(height: 24),
          ],
          if (feedback.recommandations.isNotEmpty) ...[
            _title(
              context,
              Icons.assignment,
              "Recommandations de l'IA",
              AppTheme.secondaryColor,
            ),
            const SizedBox(height: 12),
            _recommendations(),
            const SizedBox(height: 32),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRestart,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Recommencer'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDashboard,
                  icon: const Icon(Icons.dashboard, color: Colors.white),
                  label: const Text('Tableau de bord'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
