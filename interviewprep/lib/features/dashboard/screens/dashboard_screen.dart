import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/bottom_navigation.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../core/models/progress.dart';
import '../../../core/models/session_models.dart';
import '../../../core/models/user.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          title: Text(
            'Paramètres de compte',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 20, color: AppTheme.primaryContainer),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Gérez vos données personnelles conformément au RGPD.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Déconnexion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  _confirmDeleteAccount(context, ref);
                },
                icon: const Icon(Icons.delete_forever, color: AppTheme.error),
                label: const Text('Droit à l\'oubli (Supprimer mon compte)'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceContainerLowest,
          title: const Text('Supprimer définitivement le compte ?', style: TextStyle(color: AppTheme.error)),
          content: const Text(
            'Cette action est irréversible et effacera TOUTES vos données d\'entraînement, de progression et historiques, conformément à la réglementation RGPD.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await ref.read(authStateProvider.notifier).deleteAccount();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Compte et données supprimés avec succès.')),
                    );
                    context.go('/login');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  }
                }
              },
              child: const Text('Supprimer', style: TextStyle(color: AppTheme.error)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(userProgressProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final historyAsync = ref.watch(sessionHistoryProvider);

    void navigateTo(String route) {
      if (ModalRoute.of(context)?.settings.name != route) {
        context.go(route);
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _buildAppBar(context, ref, profileAsync),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppTheme.primaryContainer),
              child: Center(
                child: Text(
                  'InterviewPrep',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Tableau de bord'),
              selected: true,
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Exercices'),
              onTap: () {
                Navigator.pop(context);
                navigateTo('/exercises');
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Statistiques'),
              onTap: () {
                Navigator.pop(context);
                navigateTo('/statistics');
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('À propos'),
              onTap: () {
                Navigator.pop(context);
                navigateTo('/about');
              },
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '© 2026 Projet d\'Étude\nTous droits réservés.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(userProgressProvider);
          ref.invalidate(userProfileProvider);
          ref.invalidate(sessionHistoryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
                profileAsync.when(
                 data: (profile) => _buildHeroSection(context, ref, profile, progressAsync),
                 loading: () => const Center(child: CircularProgressIndicator()),
                 error: (e, _) => _buildHeroSection(context, ref, User(id: '', courriel: '', estActif: true, creeLe: DateTime(1970)), progressAsync),
               ),
              const SizedBox(height: 32),
              progressAsync.when(
                data: (progress) => _buildRecommendationsSection(context, progress),
                loading: () => const SizedBox(),
                error: (_, _) => const SizedBox(),
              ),
              const SizedBox(height: 32),
              historyAsync.when(
                data: (sessions) => _buildRecentSessions(context, sessions),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur historique: $e')),
              ),
              const SizedBox(height: 32),
              _buildMotivationBanner(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const MainBottomNavigation(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref, AsyncValue<User> profileAsync) {
    final initials = profileAsync.value?.initials ?? '?';
    final avatarUrl = profileAsync.value?.avatarUrl;

    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 1,
      shadowColor: Colors.black.withAlpha((0.05 * 255).round()),
      title: Row(
        children: [
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: CircleAvatar(
              backgroundColor: AppTheme.primaryContainer,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null 
                ? Text(initials, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))
                : null,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'InterviewPrep',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppTheme.primaryContainer,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart, color: AppTheme.primaryContainer),
          onPressed: () => context.go('/statistics'),
          tooltip: 'Insights',
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: AppTheme.primaryContainer),
          onPressed: () => _showSettingsDialog(context, ref),
          tooltip: 'Paramètres',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeroSection(
    BuildContext context, 
    WidgetRef ref, 
    User profile, 
    AsyncValue<ProgressMeResponse> progressAsync
  ) {
    final prenom = profile.prenom ?? '';
    
    return progressAsync.when(
      data: (progress) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back, $prenom.',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.primaryContainer,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Vous avez complété ${progress.totalSessions} sessions d\'entraînement. Votre série actuelle est de ${progress.streak} jours consécutifs !',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/exercises'),
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: const Text('Start Training'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryContainer.withAlpha((0.05 * 255).round()),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'AI INSIGHT',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 128,
                          width: 128,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: progress.bestScore / 100,
                                strokeWidth: 12,
                                backgroundColor: AppTheme.surfaceContainerLow,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.tertiaryFixed),
                              ),
                              Center(
                                child: Text(
                                  '${progress.bestScore.round()}%',
                                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                        color: AppTheme.primaryContainer,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Score de réussite', style: Theme.of(context).textTheme.labelLarge),
                        Text('Meilleur score sur toutes vos sessions', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(child: Text('Erreur chargement progression')),
    );
  }

  Widget _buildRecommendationsSection(BuildContext context, ProgressMeResponse progress) {
    final double avgScore = progress.avgScore;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.recommend, color: AppTheme.primaryContainer),
            const SizedBox(width: 8),
            Text(
              'Personalized Tips',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.primaryContainer,
                    fontSize: 20,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildRecommendationItem(
          context,
          icon: Icons.lightbulb,
          iconColor: AppTheme.onSecondaryContainer,
          iconBgColor: AppTheme.secondaryContainer,
          title: avgScore >= 70 ? 'Excellents résultats' : (avgScore >= 50 ? 'Bonne progression' : 'Continuer les efforts'),
          subtitle: avgScore >= 70
              ? 'Continuez d\'ajouter des chiffres précis et des indicateurs de succès (KPI) dans vos études de cas.'
              : (avgScore >= 50
                  ? 'Renforcez la structure STAR dans vos réponses et ajoutez des résultats mesurables.'
                  : 'Pratiquez avec des exercices de niveau Débutant et structurez vos réponses avec la méthode STAR.'),
        ),
        const SizedBox(height: 16),
        _buildRecommendationItem(
          context,
          icon: Icons.star_rate,
          iconColor: AppTheme.onTertiaryFixedVariant,
          iconBgColor: AppTheme.tertiaryFixed,
          title: avgScore >= 70 ? 'Excellents résultats' : (avgScore >= 50 ? 'Bonne progression' : 'Continuer les efforts'),
          subtitle: avgScore >= 70
              ? 'Continuez d\'ajouter des chiffres précis et des indicateurs de succès (KPI) dans vos études de cas.'
              : (avgScore >= 50
                  ? 'Renforcez la structure STAR dans vos réponses et ajoutez des résultats mesurables.'
                  : 'Pratiquez avec des exercices de niveau Débutant et structurez vos réponses avec la méthode STAR.'),
        ),
      ],
    );
  }

  Widget _buildRecommendationItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSessions(BuildContext context, List<SessionResponse> sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Sessions Récentes',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.primaryContainer,
                    fontSize: 20,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryContainer.withAlpha((0.05 * 255).round()),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: sessions.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: Text(
                      'Aucune session complétée pour le moment.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.onSurfaceVariant),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < sessions.length; i++) ...[
                      _buildSessionRow(
                        context,
                        session: sessions[i],
                      ),
                      if (i < sessions.length - 1)
                        const Divider(height: 1, color: AppTheme.outlineVariant),
                    ]
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSessionRow(BuildContext context, {required SessionResponse session}) {
    final double sessionScore = session.score ?? 0.0;
    final bool isGood = sessionScore >= 70.0;
    final bool isWarning = sessionScore < 50.0;
    
    Color indicatorColor = isGood ? AppTheme.tertiaryFixed : (isWarning ? AppTheme.error : AppTheme.outlineVariant);
    Color scoreBg = isGood ? AppTheme.tertiaryFixed : (isWarning ? AppTheme.error.withAlpha((0.2 * 255).round()) : AppTheme.outlineVariant.withAlpha((0.2 * 255).round()));
    Color scoreColor = isGood ? AppTheme.onTertiaryFixedVariant : (isWarning ? AppTheme.error : AppTheme.onSurfaceVariant);

    // Formater la date proprement
    final String formattedDate = session.commenceLe != null 
        ? '${session.commenceLe!.day}/${session.commenceLe!.month}/${session.commenceLe!.year}'
        : 'Inconnue';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: indicatorColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entretien d\'évaluation', 
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.primaryContainer, fontWeight: FontWeight.bold)
                ),
                Text('Lancé le $formattedDate • Statut: ${session.statut}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: scoreBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${sessionScore.round()}%', 
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scoreColor, fontSize: 12)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationBanner(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY\'S FOCUS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.primaryFixedVariant,
                  letterSpacing: 1.5,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '"Comment gérez-vous un désaccord avec un manager ?"',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Cette question comportementale classique apparaît dans 40% des entretiens. Exercez-vous dès aujourd\'hui !',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryFixedVariant),
          ),
        ],
      ),
    );
  }

}
