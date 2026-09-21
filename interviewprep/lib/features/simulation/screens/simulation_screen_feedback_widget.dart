mixin _SimulationFeedback on _SimulationScreenState {
  Widget _buildFeedbackScreen(
    BuildContext context,
    SimulationState state,
    SimulationNotifier notifier,
  ) {
    final feedback = state.feedback!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 1,
        title: const Text(
          'Bilan d\'Ã‰valuation IA',
          style: TextStyle(
            color: AppTheme.primaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Radial score banner
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'VOTRE SCORE GLOBAL',
                    style: TextStyle(
                      color: AppTheme.primaryFixedVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: CircularProgressIndicator(
                          value: feedback.scoreGlobal / 100,
                          strokeWidth: 14,
                          backgroundColor: Colors.white.withAlpha(
                            (0.15 * 255).round(),
                          ),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.tertiaryFixed,
                          ),
                        ),
                      ),
                      Text(
                        '${feedback.scoreGlobal.round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Entretien complÃ©tÃ© avec succÃ¨s !',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Points forts (Green)
            if (feedback.pointsForts != null &&
                feedback.pointsForts!.isNotEmpty) ...[
              _buildSectionTitle(
                context,
                Icons.check_circle,
                'Points Forts',
                Colors.green,
              ),
              const SizedBox(height: 12),
              ...feedback.pointsForts!.map(
                (pf) => _buildDetailCard(
                  context,
                  title: pf['domaine'] as String? ?? 'CompÃ©tence',
                  description: pf['note'] as String? ?? '',
                  borderColor: Colors.green,
                  iconColor: Colors.green,
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Axes d'amÃ©lioration (Orange)
            if (feedback.ameliorations != null &&
                feedback.ameliorations!.isNotEmpty) ...[
              _buildSectionTitle(
                context,
                Icons.trending_up,
                'Axes d\'AmÃ©lioration',
                Colors.orange,
              ),
              const SizedBox(height: 12),
              ...feedback.ameliorations!.map(
                (am) => _buildDetailCard(
                  context,
                  title: am['domaine'] as String? ?? 'CompÃ©tence',
                  description: am['note'] as String? ?? '',
                  borderColor: Colors.orange,
                  iconColor: Colors.orange,
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Recommandations
            if (feedback.recommandations != null &&
                feedback.recommandations!.isNotEmpty) ...[
              _buildSectionTitle(
                context,
                Icons.assignment,
                'Recommandations de l\'IA',
                AppTheme.secondaryColor,
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowest,
                  border: Border.all(color: AppTheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: feedback.recommandations!
                      .map(
                        (rec) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
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
              ),
              const SizedBox(height: 48),
            ],

            // Button Return to Dashboard
            ElevatedButton(
              onPressed: () {
                notifier.reset();
                ref.invalidate(userProgressProvider);
                ref.invalidate(sessionHistoryProvider);
                ref.invalidate(detailedStatsProvider);
                context.go('/dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Retour au Tableau de Bord',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
